from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from .auth import Principal
from .config import Settings
from .models import (
    Machine,
    MachineDeviceSubscription,
    Notification,
    Run,
    RunEvent,
    Workspace,
    utcnow,
)
from .services import TERMINAL_STATUSES, run_snapshot
from .sync import decode_history_cursor, encode_history_cursor

SYNC_SNAPSHOT_LIMIT = 200


def list_run_events(
    session: Session,
    principal: Principal,
    run_id: str,
    before_seq: int | None = None,
    after_seq: int | None = None,
    limit: int = 100,
) -> dict[str, Any]:
    """Newest page by default; older/newer pages never skip equal timestamps."""
    run = session.get(Run, run_id)
    if run is None or run.workspace_id != principal.workspace_id:
        raise HTTPException(404, "run not found")
    if before_seq is not None and after_seq is not None:
        raise HTTPException(400, "before_seq and after_seq are mutually exclusive")
    if not 1 <= limit <= 100 or any(v is not None and v < 0 for v in (before_seq, after_seq)):
        raise HTTPException(400, "invalid event page")
    query = select(RunEvent).where(RunEvent.run_id == run.id)
    if before_seq is not None:
        query = query.where(RunEvent.seq < before_seq)
    if after_seq is not None:
        query = query.where(RunEvent.seq > after_seq)
    order = RunEvent.seq.asc() if after_seq is not None else RunEvent.seq.desc()
    rows = list(session.scalars(query.order_by(order).limit(limit + 1)))
    page = sorted(rows[:limit], key=lambda event: event.seq)
    return {
        "items": [
            {
                "event_id": e.event_id,
                "seq": e.seq,
                "type": e.type,
                "occurred_at": e.occurred_at,
                "received_at": e.received_at,
                "payload": e.payload,
            }
            for e in page
        ],
        "has_more": len(rows) > limit,
        "before_seq": page[0].seq if page else before_seq,
        "after_seq": page[-1].seq if page else after_seq,
        "sequence": run.last_seq,
    }


def _machine_snapshot(
    machine: Machine,
    *,
    subscription_id: str | None,
) -> dict[str, Any]:
    return {
        "id": machine.id,
        "display_name": machine.display_name,
        "platform": machine.platform,
        "architecture": machine.architecture,
        "cli_version": machine.cli_version,
        "last_seen_at": machine.last_seen_at,
        "paired_at": machine.paired_at,
        "subscription_id": subscription_id,
        "is_subscribed": subscription_id is not None,
    }


def _subscription_ids_by_machine(
    session: Session,
    *,
    device_id: str,
    machine_ids: list[str],
) -> dict[str, str]:
    if not machine_ids:
        return {}
    rows = session.execute(
        select(
            MachineDeviceSubscription.machine_id,
            MachineDeviceSubscription.id,
        ).where(
            MachineDeviceSubscription.device_id == device_id,
            MachineDeviceSubscription.machine_id.in_(machine_ids),
        )
    )
    return {machine_id: subscription_id for machine_id, subscription_id in rows}


def _notification_snapshot(item: Notification) -> dict[str, Any]:
    return {
        "id": item.id,
        "machine_id": item.machine_id,
        "run_id": item.run_id,
        "title": item.title,
        "subtitle": item.subtitle,
        "body": item.body,
        "level": item.level,
        "fields": item.fields,
        "safe_link": item.safe_link,
        "created_at": item.created_at,
        "expires_at": item.expires_at,
    }


def _sync_etag(workspace_id: str, revision: int) -> str:
    return f'"sync-{workspace_id}-{revision}"'


def _etag_matches(if_none_match: str | None, etag: str) -> bool:
    if if_none_match is None:
        return False
    candidates = {value.strip() for value in if_none_match.split(",")}
    return "*" in candidates or etag in candidates or f"W/{etag}" in candidates


def _runs_after_cursor(sort_time: Any, item_id: str) -> Any:
    return or_(Run.updated_at < sort_time, (Run.updated_at == sort_time) & (Run.id < item_id))


def _notifications_after_cursor(sort_time: Any, item_id: str) -> Any:
    return or_(
        Notification.created_at < sort_time,
        (Notification.created_at == sort_time) & (Notification.id < item_id),
    )


def sync_snapshot(
    session: Session,
    principal: Principal,
    settings: Settings,
    cursor: int | None = None,
    if_none_match: str | None = None,
) -> tuple[dict[str, Any] | None, str]:
    required_scopes = {"runs:read", "machines:read", "notifications:read"}
    if not required_scopes.issubset(principal.scopes):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "missing sync read scopes")
    # A shared row lock keeps the revision and all bounded projections in this
    # response consistent with writers, which update this row atomically.
    workspace = session.scalar(
        select(Workspace).where(Workspace.id == principal.workspace_id).with_for_update(read=True)
    )
    if workspace is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "workspace not found")
    revision = workspace.revision
    if cursor is not None and cursor > revision:
        raise HTTPException(status.HTTP_409_CONFLICT, "sync cursor is ahead of the workspace")

    etag = _sync_etag(workspace.id, revision)
    if cursor == revision or _etag_matches(if_none_match, etag):
        return None, etag

    # Active Runs have no history endpoint, so every Run allowed by the active
    # quota must fit in the bounded sync projection. Terminal history remains a
    # fixed-size window and can be paged through /history/runs.
    active_run_limit = settings.max_machines_per_workspace * settings.max_active_runs_per_machine
    active_runs = list(
        session.scalars(
            select(Run)
            .where(
                Run.workspace_id == workspace.id,
                ~Run.execution_status.in_(TERMINAL_STATUSES),
            )
            .order_by(Run.updated_at.desc(), Run.id.desc())
            .limit(active_run_limit)
        )
    )
    terminal_runs = list(
        session.scalars(
            select(Run)
            .where(
                Run.workspace_id == workspace.id,
                Run.execution_status.in_(TERMINAL_STATUSES),
            )
            .order_by(Run.updated_at.desc(), Run.id.desc())
            .limit(SYNC_SNAPSHOT_LIMIT)
        )
    )
    runs = [*active_runs, *terminal_runs]
    machines = list(
        session.scalars(
            select(Machine)
            .where(Machine.workspace_id == workspace.id, Machine.revoked_at.is_(None))
            .order_by(Machine.paired_at.desc(), Machine.id.desc())
            .limit(settings.max_machines_per_workspace)
        )
    )
    notifications = list(
        session.scalars(
            select(Notification)
            .where(Notification.workspace_id == workspace.id)
            .order_by(Notification.created_at.desc(), Notification.id.desc())
            .limit(SYNC_SNAPSHOT_LIMIT)
        )
    )
    subscription_ids = _subscription_ids_by_machine(
        session,
        device_id=principal.subject_id if principal.kind == "device" else "",
        machine_ids=[machine.id for machine in machines],
    )

    history_runs_cursor = None
    if terminal_runs:
        oldest_run = terminal_runs[-1]
        has_more_runs = (
            session.scalar(
                select(Run.id).where(
                    Run.workspace_id == workspace.id,
                    Run.execution_status.in_(TERMINAL_STATUSES),
                    _runs_after_cursor(oldest_run.updated_at, oldest_run.id),
                )
            )
            is not None
        )
        if has_more_runs:
            history_runs_cursor = encode_history_cursor(
                "runs", oldest_run.updated_at, oldest_run.id, None
            )
    else:
        has_more_runs = (
            session.scalar(
                select(Run.id).where(
                    Run.workspace_id == workspace.id,
                    Run.execution_status.in_(TERMINAL_STATUSES),
                )
            )
            is not None
        )

    history_notifications_cursor = None
    if notifications:
        oldest_notification = notifications[-1]
        has_more_notifications = (
            session.scalar(
                select(Notification.id).where(
                    Notification.workspace_id == workspace.id,
                    _notifications_after_cursor(
                        oldest_notification.created_at, oldest_notification.id
                    ),
                )
            )
            is not None
        )
        if has_more_notifications:
            history_notifications_cursor = encode_history_cursor(
                "notifications",
                oldest_notification.created_at,
                oldest_notification.id,
                None,
            )
    else:
        has_more_notifications = False

    return {
        "schema_version": 1,
        "next_cursor": revision,
        "server_time": utcnow(),
        "runs": [run_snapshot(run) for run in runs],
        "machines": [
            _machine_snapshot(machine, subscription_id=subscription_ids.get(machine.id))
            for machine in machines
        ],
        "notifications": [_notification_snapshot(item) for item in notifications],
        "history_runs_next_cursor": history_runs_cursor,
        "history_runs_has_more": has_more_runs,
        "history_notifications_next_cursor": history_notifications_cursor,
        "history_notifications_has_more": has_more_notifications,
    }, etag


def list_run_history(
    session: Session,
    principal: Principal,
    cursor: str | None = None,
    limit: int = 50,
    machine_id: str | None = None,
) -> dict[str, Any]:
    query = select(Run).where(
        Run.workspace_id == principal.workspace_id,
        Run.execution_status.in_(TERMINAL_STATUSES),
    )
    if machine_id is not None:
        query = query.where(Run.machine_id == machine_id)
    if cursor is not None:
        sort_time, item_id = decode_history_cursor(
            cursor,
            expected_kind="runs",
            machine_id=machine_id,
        )
        query = query.where(_runs_after_cursor(sort_time, item_id))
    rows = list(
        session.scalars(query.order_by(Run.updated_at.desc(), Run.id.desc()).limit(limit + 1))
    )
    has_more = len(rows) > limit
    items = rows[:limit]
    next_cursor = (
        encode_history_cursor("runs", items[-1].updated_at, items[-1].id, machine_id)
        if has_more and items
        else None
    )
    return {
        "items": [run_snapshot(run) for run in items],
        "next_cursor": next_cursor,
        "has_more": has_more,
    }


def list_notification_history(
    session: Session,
    principal: Principal,
    cursor: str | None = None,
    limit: int = 50,
    machine_id: str | None = None,
) -> dict[str, Any]:
    query = select(Notification).where(Notification.workspace_id == principal.workspace_id)
    if machine_id is not None:
        query = query.where(Notification.machine_id == machine_id)
    if cursor is not None:
        sort_time, item_id = decode_history_cursor(
            cursor,
            expected_kind="notifications",
            machine_id=machine_id,
        )
        query = query.where(_notifications_after_cursor(sort_time, item_id))
    rows = list(
        session.scalars(
            query.order_by(Notification.created_at.desc(), Notification.id.desc()).limit(limit + 1)
        )
    )
    has_more = len(rows) > limit
    items = rows[:limit]
    next_cursor = (
        encode_history_cursor("notifications", items[-1].created_at, items[-1].id, machine_id)
        if has_more and items
        else None
    )
    return {
        "items": [_notification_snapshot(item) for item in items],
        "next_cursor": next_cursor,
        "has_more": has_more,
    }


def get_run(
    session: Session, principal: Principal, run_id: str, *, include_events: bool = True
) -> dict[str, Any]:
    run = session.get(Run, str(run_id))
    if run is None or run.workspace_id != principal.workspace_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "run not found")
    result = run_snapshot(run)
    if not include_events:
        return {"run": result}
    events = list(
        session.scalars(
            select(RunEvent).where(RunEvent.run_id == run.id).order_by(RunEvent.seq).limit(500)
        )
    )
    events_payload = [
        {
            "event_id": event.event_id,
            "seq": event.seq,
            "type": event.type,
            "occurred_at": event.occurred_at,
            "received_at": event.received_at,
            "payload": event.payload,
        }
        for event in events
    ]
    return {"run": result, "events": events_payload}


def list_machines(session: Session, principal: Principal) -> list[dict[str, Any]]:
    machines = list(
        session.scalars(
            select(Machine)
            .where(Machine.workspace_id == principal.workspace_id, Machine.revoked_at.is_(None))
            .order_by(Machine.paired_at.desc())
        )
    )
    subscription_ids = _subscription_ids_by_machine(
        session,
        device_id=principal.subject_id if principal.kind == "device" else "",
        machine_ids=[machine.id for machine in machines],
    )
    return [
        _machine_snapshot(machine, subscription_id=subscription_ids.get(machine.id))
        for machine in machines
    ]
