from __future__ import annotations

import base64
import hashlib
import uuid
from contextlib import contextmanager
from dataclasses import replace
from datetime import timedelta
from urllib.parse import parse_qs, urlsplit

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.database import get_session
from app.main import create_app
from app.models import PluginAuthorization, RunEvent, utcnow
from app.plugin_auth import READ_SCOPES
from app.security import cipher_for
from tests.conftest import Harness
from tests.test_abuse_postgres import postgres_client, postgres_factory  # noqa: F401

VERIFIER = "a" * 64
CHALLENGE = (
    base64.urlsafe_b64encode(hashlib.sha256(VERIFIER.encode()).digest()).decode().rstrip("=")
)


@pytest.fixture
def plugin(harness):
    with configured_plugin(harness) as value:
        yield value


@contextmanager
def configured_plugin(harness):
    device, machine = harness.pair()
    other = harness.bootstrap("other-workspace")
    settings = replace(
        harness.settings,
        plugin_enabled=True,
        plugin_workspace_allowlist=(device["workspace_id"], other["workspace_id"]),
    )
    app = create_app(settings)

    def session():
        with harness.session_factory() as db:
            yield db

    app.dependency_overrides[get_session] = session
    with TestClient(app) as client:
        yield client, harness, device, machine, other, settings


def start(plugin, **overrides):
    client, harness, _device, _machine, _other, settings = plugin
    params = {
        "client_id": settings.plugin_client_id,
        "response_type": "code",
        "redirect_uri": settings.plugin_redirect_uris[0],
        "code_challenge": CHALLENGE,
        "code_challenge_method": "S256",
        "state": "caller-state",
        "scope": " ".join(READ_SCOPES),
        "resource": settings.plugin_public_url + "/mcp",
        **overrides,
    }
    response = client.get("/authorize", params=params, follow_redirects=False)
    assert response.status_code in (302, 307), response.text
    page = urlsplit(response.headers["location"]).path
    with harness.session_factory() as db:
        row = db.scalars(
            select(PluginAuthorization).order_by(PluginAuthorization.created_at.desc())
        ).first()
        challenge = cipher_for(settings).decrypt(row.challenge_encrypted)
        return page, row.id, challenge


def allow(plugin, *, decision="allow", **overrides):
    client, _, device, _, _, _ = plugin
    page, request_id, challenge = start(plugin, **overrides)
    response = client.post(
        f"/v1/plugin-connections/requests/{request_id}/decision",
        headers={"Authorization": "Bearer " + device["credential"]},
        json={"challenge": challenge, "decision": decision},
    )
    assert response.status_code == 204, response.text
    return page, request_id, challenge


def exchange(plugin, page, **overrides):
    client, _, _, _, _, settings = plugin
    status = client.get(page + "/status").json()
    query = parse_qs(urlsplit(status["redirect_url"]).query)
    assert query["state"] == ["caller-state"]
    assert query["iss"] == [client.get("/.well-known/oauth-authorization-server").json()["issuer"]]
    data = {
        "client_id": settings.plugin_client_id,
        "grant_type": "authorization_code",
        "code": query["code"][0],
        "redirect_uri": settings.plugin_redirect_uris[0],
        "code_verifier": VERIFIER,
        "resource": settings.plugin_public_url + "/mcp",
        **overrides,
    }
    return client.post("/token", data=data), data


def connect(plugin):
    page, _, _ = allow(plugin)
    response, _ = exchange(plugin, page)
    assert response.status_code == 200, response.text
    return response.json()


def rpc(client, token, method, params=None):
    return client.post(
        "/mcp",
        headers={
            "Authorization": "Bearer " + token,
            "Accept": "application/json, text/event-stream",
            "MCP-Protocol-Version": "2025-11-25",
        },
        json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params or {}},
    )


def test_oauth_mcp_ui_and_separate_credentials(plugin):
    client, _, device, machine, _, settings = plugin
    metadata = client.get("/.well-known/oauth-authorization-server").json()
    assert "S256" in metadata["code_challenge_methods_supported"]
    assert metadata["token_endpoint_auth_methods_supported"] == ["none"]
    assert metadata["revocation_endpoint_auth_methods_supported"] == ["none"]
    assert metadata["authorization_response_iss_parameter_supported"] is True
    resource = client.get("/.well-known/oauth-protected-resource/mcp").json()
    assert resource["resource"].rstrip("/") == settings.plugin_public_url + "/mcp"
    assert resource["authorization_servers"] == [metadata["issuer"]]
    page, request_id, challenge = start(plugin)
    html = client.get(page)
    assert html.status_code == 200 and "<svg" in html.text and "runbuoy://connect/" in html.text
    assert "frame-ancestors 'none'" in html.headers["content-security-policy"]
    info = client.post(
        f"/v1/plugin-connections/requests/{request_id}/inspect",
        headers={"Authorization": "Bearer " + device["credential"]},
        json={"challenge": challenge},
    )
    assert info.json()["workspace_id"] == device["workspace_id"]
    assert info.json()["scopes"] == READ_SCOPES
    approved = client.post(
        f"/v1/plugin-connections/requests/{request_id}/decision",
        headers={"Authorization": "Bearer " + device["credential"]},
        json={"challenge": challenge, "decision": "allow"},
    )
    assert approved.status_code == 204
    response, token_request = exchange(plugin, page)
    assert response.status_code == 200, response.text
    token = response.json()["access_token"]
    assert token not in (device["credential"], machine["credential"])
    tools = rpc(client, token, "tools/list")
    assert tools.status_code == 200, tools.text
    descriptors = tools.json()["result"]["tools"]
    assert len(descriptors) == 6
    opener = next(t for t in descriptors if t["name"] == "open_runbuoy")
    assert opener["_meta"]["openai/ui"]["entrypoints"] == [{"type": "global"}, {"type": "thread"}]
    assert all(t["annotations"]["readOnlyHint"] for t in descriptors)
    opened = rpc(client, token, "tools/call", {"name": "open_runbuoy", "arguments": {}})
    assert opened.status_code == 200, opened.text
    assert not opened.json()["result"].get("isError"), opened.text
    assert (
        opened.json()["result"]["_meta"]["runbuoy"]["overview"]["machines"][0]["id"]
        == machine["machine_id"]
    )
    ui = rpc(client, token, "resources/read", {"uri": opener["_meta"]["ui"]["resourceUri"]})
    assert ui.json()["result"]["contents"][0]["mimeType"] == "text/html;profile=mcp-app"
    assert client.post("/token", data=token_request).status_code == 400
    assert rpc(client, device["credential"], "tools/list").status_code == 401
    assert client.get("/v1/runs", headers={"Authorization": "Bearer " + token}).status_code == 401


def test_deny_expiry_pkce_redirect_resource_and_scope(plugin):
    client, harness, device, _, _, settings = plugin
    page, _, _ = allow(plugin, decision="deny")
    assert "error=access_denied" in client.get(page + "/status").json()["redirect_url"]
    page, _, _ = allow(plugin)
    bad, valid = exchange(plugin, page, code_verifier="b" * 64)
    assert bad.status_code == 400
    valid["code_verifier"] = VERIFIER
    assert (
        client.post("/token", data={**valid, "resource": "https://wrong.example/mcp"}).status_code
        == 400
    )
    assert (
        client.post(
            "/token", data={**valid, "redirect_uri": "https://wrong.example/callback"}
        ).status_code
        == 400
    )
    assert client.post("/token", data=valid).status_code == 200
    page, request_id, challenge = start(plugin)
    with harness.session_factory() as db:
        db.get(PluginAuthorization, request_id).expires_at = utcnow() - timedelta(seconds=1)
        db.commit()
    assert client.get(page).status_code == 410
    assert (
        client.post(
            f"/v1/plugin-connections/requests/{request_id}/decision",
            headers={"Authorization": "Bearer " + device["credential"]},
            json={"challenge": challenge, "decision": "allow"},
        ).status_code
        == 410
    )
    for changes in (
        {"code_challenge_method": "plain"},
        {"scope": "runs:create"},
        {"resource": "https://wrong.example/mcp"},
        {"redirect_uri": "https://evil.example/"},
    ):
        response = client.get(
            "/authorize",
            params={
                "client_id": settings.plugin_client_id,
                "response_type": "code",
                "code_challenge": CHALLENGE,
                "code_challenge_method": "S256",
                "redirect_uri": settings.plugin_redirect_uris[0],
                "resource": settings.plugin_public_url + "/mcp",
                **changes,
            },
            follow_redirects=False,
        )
        assert response.status_code in (400, 302, 307)
        assert "/connect/" not in response.headers.get("location", "")
        if location := response.headers.get("location"):
            redirect = urlsplit(location)
            assert parse_qs(redirect.query)["iss"] == [
                client.get("/.well-known/oauth-authorization-server").json()["issuer"]
            ]
            registered = urlsplit(settings.plugin_redirect_uris[0])
            assert (redirect.scheme, redirect.netloc, redirect.path) == (
                registered.scheme,
                registered.netloc,
                registered.path,
            )


def test_refresh_rotation_and_replay_revoke_connection(plugin):
    client, _, _, _, _, settings = plugin
    tokens = connect(plugin)
    body = {
        "client_id": settings.plugin_client_id,
        "grant_type": "refresh_token",
        "refresh_token": tokens["refresh_token"],
        "resource": settings.plugin_public_url + "/mcp",
    }
    refreshed = client.post("/token", data=body)
    assert refreshed.status_code == 200, refreshed.text
    assert refreshed.json()["refresh_token"] != tokens["refresh_token"]
    assert rpc(client, tokens["access_token"], "tools/list").status_code == 200
    assert rpc(client, refreshed.json()["access_token"], "tools/list").status_code == 200
    assert client.post("/token", data=body).status_code == 400
    assert rpc(client, tokens["access_token"], "tools/list").status_code == 401
    assert rpc(client, refreshed.json()["access_token"], "tools/list").status_code == 401


@pytest.mark.parametrize("action", ["revoke", "reset", "workspace-delete"])
def test_lifecycle_revocation(plugin, action):
    client, _, device, _, other, _ = plugin
    tokens = connect(plugin)
    headers = {"Authorization": "Bearer " + device["credential"]}
    connection = client.get("/v1/plugin-connections", headers=headers).json()[0]
    assert (
        client.delete(
            "/v1/plugin-connections/" + connection["id"],
            headers={"Authorization": "Bearer " + other["credential"]},
        ).status_code
        == 404
    )
    if action == "revoke":
        assert (
            client.delete("/v1/plugin-connections/" + connection["id"], headers=headers).status_code
            == 204
        )
    elif action == "reset":
        assert (
            client.delete("/v1/devices/" + device["device_id"], headers=headers).status_code == 204
        )
    else:
        challenge = client.post(
            f"/v1/workspaces/{device['workspace_id']}/deletion-challenge",
            headers=headers,
            json={"confirmation": "DELETE"},
        ).json()["challenge"]
        response = client.request(
            "DELETE",
            f"/v1/workspaces/{device['workspace_id']}",
            headers=headers,
            json={"challenge": challenge},
        )
        assert response.status_code == 204, response.text
    assert rpc(client, tokens["access_token"], "tools/list").status_code == 401


def test_duplicate_decision_machine_denied_and_cross_workspace(plugin):
    client, harness, device, machine, other, _ = plugin
    page, request_id, challenge = allow(plugin)
    endpoint = f"/v1/plugin-connections/requests/{request_id}/decision"
    assert (
        client.post(
            endpoint,
            headers={"Authorization": "Bearer " + device["credential"]},
            json={"challenge": challenge, "decision": "allow"},
        ).status_code
        == 409
    )
    assert (
        client.post(
            endpoint,
            headers={"Authorization": "Bearer " + machine["credential"]},
            json={"challenge": challenge, "decision": "allow"},
        ).status_code
        == 403
    )
    response, _ = exchange(plugin, page)
    token = response.json()["access_token"]
    run_id = str(uuid.uuid4())
    harness.register_run(machine, run_id)
    with harness.session_factory() as db:
        from app.models import Run

        db.get(Run, run_id).workspace_id = other["workspace_id"]
        db.commit()
    result = rpc(
        client, token, "tools/call", {"name": "get_run", "arguments": {"run_id": run_id}}
    ).json()["result"]
    assert result["isError"] and "not found" in result["content"][0]["text"]


def test_event_pagination_beyond_500_and_snapshot_parity(plugin):
    client, harness, device, machine, _, _ = plugin
    run_id = str(uuid.uuid4())
    harness.register_run(machine, run_id)
    with harness.session_factory() as db:
        for seq in range(1, 621):
            db.add(
                RunEvent(
                    id=f"e{seq}",
                    schema_version=1,
                    event_id=str(uuid.uuid4()),
                    run_id=run_id,
                    machine_id=machine["machine_id"],
                    seq=seq,
                    type="run.heartbeat",
                    occurred_at=utcnow(),
                    received_at=utcnow(),
                    payload={},
                )
            )
        db.commit()
    tokens = connect(plugin)
    data = rpc(
        client,
        tokens["access_token"],
        "tools/call",
        {"name": "get_run", "arguments": {"run_id": run_id}},
    ).json()["result"]["_meta"]["runbuoy"]
    ios = client.get(
        "/v1/runs/" + run_id, headers={"Authorization": "Bearer " + device["credential"]}
    ).json()
    assert data["run"] == ios["run"]
    assert [e["seq"] for e in data["events"]["items"]] == list(range(521, 621))
    seen = []
    before = None
    while True:
        args = {"run_id": run_id, "before_seq": before, "limit": 100}
        page = rpc(
            client,
            tokens["access_token"],
            "tools/call",
            {"name": "get_run_events", "arguments": args},
        ).json()["result"]["structuredContent"]["events"]
        seen.extend(e["seq"] for e in page["items"])
        if not page["has_more"]:
            break
        before = page["before_seq"]
    assert sorted(seen) == list(range(1, 621))
    response = client.get(
        f"/v1/runs/{run_id}/events",
        params={"after_seq": 615},
        headers={"Authorization": "Bearer " + device["credential"]},
    )
    assert [e["seq"] for e in response.json()["items"]] == list(range(616, 621))


def test_live_transition_matches_ios_and_expired_token_cannot_read(plugin):
    from app.models import PluginToken
    from app.security import token_hash
    from tests.test_api import auth, event, post_events

    client, harness, device, machine, _, settings = plugin
    run_id = str(uuid.uuid4())
    harness.register_run(machine, run_id)
    tokens = connect(plugin)
    for seq, event_type, expected, payload in [
        (1, "run.started", "RUNNING", {}),
        (2, "run.progress", "RUNNING", {"current": 7, "total": 10, "unit": "steps"}),
        (3, "run.succeeded", "SUCCEEDED", {"exit_code": 0}),
    ]:
        result = post_events(
            harness,
            machine,
            run_id,
            [event(run_id, machine["machine_id"], seq, event_type, payload=payload)],
        )
        assert result.status_code == 200, result.text
        ios = client.get("/v1/runs/" + run_id, headers=auth(device["credential"])).json()["run"]
        mcp = rpc(
            client,
            tokens["access_token"],
            "tools/call",
            {"name": "get_run", "arguments": {"run_id": run_id}},
        ).json()["result"]["_meta"]["runbuoy"]["run"]
        assert mcp == ios
        assert mcp["execution_status"] == expected and mcp["sequence"] == seq
    with harness.session_factory() as db:
        token = db.get(PluginToken, token_hash(tokens["access_token"], settings.credential_pepper))
        token.expires_at = utcnow() - timedelta(seconds=1)
        db.commit()
    assert rpc(client, tokens["access_token"], "tools/list").status_code == 401


def test_bounded_body_challenge_validation_and_retention(plugin):
    from app.models import PluginToken
    from app.retention import cleanup_retention

    client, harness, device, _, _, settings = plugin
    page, request_id, _ = start(plugin)
    headers = {"Authorization": "Bearer " + device["credential"]}
    inspect = f"/v1/plugin-connections/requests/{request_id}/inspect"
    assert client.post(inspect, headers=headers, json={"challenge": "wrong" * 8}).status_code == 404
    assert (
        client.post("/token", content="x" * (settings.max_request_body_bytes + 1)).status_code
        == 413
    )
    tokens = connect(plugin)
    assert tokens["expires_in"] == 900
    with harness.session_factory() as db:
        future = utcnow() + timedelta(days=31)
        cleanup_retention(db, settings, future)
        db.commit()
        assert db.scalar(select(PluginAuthorization.id)) is None
        assert db.scalar(select(PluginToken.token_hash)) is None
    assert client.get(page).status_code == 404
    assert rpc(client, tokens["access_token"], "tools/list").status_code == 401


def test_postgres_concurrent_decisions_and_code_exchange(postgres_client):  # noqa: F811
    from concurrent.futures import ThreadPoolExecutor
    from threading import Barrier

    client, factory = postgres_client
    harness = Harness(client, factory, client.app.state.settings)
    with configured_plugin(harness) as plugin:
        plugin_client, _, device, _, _, _ = plugin
        page, request_id, challenge = start(plugin)
        barrier = Barrier(2)

        def decide():
            barrier.wait()
            return plugin_client.post(
                f"/v1/plugin-connections/requests/{request_id}/decision",
                headers={"Authorization": "Bearer " + device["credential"]},
                json={"challenge": challenge, "decision": "allow"},
            ).status_code

        with ThreadPoolExecutor(max_workers=2) as pool:
            assert sorted(pool.map(lambda _: decide(), range(2))) == [204, 409]
        _, token_request = exchange(plugin, page, code_verifier="wrong" * 16)
        barrier = Barrier(2)
        token_request["code_verifier"] = VERIFIER

        def claim():
            barrier.wait()
            return plugin_client.post("/token", data=token_request).status_code

        with ThreadPoolExecutor(max_workers=2) as pool:
            assert sorted(pool.map(lambda _: claim(), range(2))) == [200, 400]
