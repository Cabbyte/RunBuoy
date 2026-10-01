"""Phone-confirmed OAuth using the MCP SDK's authorization-code/PKCE handlers.

A connection is a separate viewer grant. Device and Machine credentials never
leave their existing clients; access and refresh tokens are hashed at rest.
The five-minute QR challenge
and callback code are encrypted while the authorization browser needs them.
"""

from __future__ import annotations

import hmac
from collections.abc import Callable
from contextlib import AbstractContextManager
from datetime import timedelta
from pathlib import Path
from typing import Any, Literal
from urllib.parse import urlencode

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from fastapi.responses import HTMLResponse, JSONResponse
from mcp.server.auth.provider import (
    AccessToken,
    AuthorizationCode,
    AuthorizationParams,
    AuthorizeError,
    OAuthAuthorizationServerProvider,
    RefreshToken,
    RegistrationError,
    TokenError,
)
from mcp.server.auth.routes import build_metadata
from mcp.server.auth.settings import ClientRegistrationOptions, RevocationOptions
from mcp.shared.auth import OAuthClientInformationFull, OAuthToken
from pydantic import AnyHttpUrl, AnyUrl, BaseModel, ConfigDict, Field
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from .auth import Principal, authenticate
from .config import Settings
from .database import get_session
from .models import (
    AuditLog,
    Device,
    DeviceCredential,
    PluginAuthorization,
    PluginGrant,
    PluginToken,
    utcnow,
)
from .security import cipher_for, is_expired, new_bearer_token, new_id, token_hash
from .services import aware

READ_SCOPES = ["runs:read", "machines:read", "notifications:read"]
SessionFactory = Callable[[], AbstractContextManager[Session]]
router = APIRouter()
NO_STORE = {"Cache-Control": "no-store", "Referrer-Policy": "no-referrer"}


def authorization_metadata(settings: Settings) -> dict[str, Any]:
    # The SDK defaults advertise confidential clients; our pre-registered client
    # uses PKCE without a secret. Keep endpoint construction shared with the SDK.
    metadata = build_metadata(
        AnyHttpUrl(settings.plugin_public_url),
        None,
        ClientRegistrationOptions(enabled=False, valid_scopes=READ_SCOPES),
        RevocationOptions(enabled=True),
    ).model_dump(mode="json", exclude_none=True)
    metadata["token_endpoint_auth_methods_supported"] = ["none"]
    metadata["revocation_endpoint_auth_methods_supported"] = ["none"]
    metadata["authorization_response_iss_parameter_supported"] = True
    return metadata


def valid_grant(session: Session, grant_id: str, settings: Settings) -> PluginGrant | None:
    grant = session.get(PluginGrant, grant_id)
    if (
        grant is None
        or grant.revoked_at is not None
        or is_expired(grant.expires_at)
        or grant.workspace_id not in settings.plugin_workspace_allowlist
    ):
        return None
    device = session.get(Device, grant.device_id)
    if device is None or device.revoked_at is not None or device.workspace_id != grant.workspace_id:
        return None
    if not session.scalar(
        select(DeviceCredential.id)
        .where(DeviceCredential.device_id == device.id, DeviceCredential.revoked_at.is_(None))
        .limit(1)
    ):
        return None
    return grant


class PhoneOAuthProvider(
    OAuthAuthorizationServerProvider[AuthorizationCode, RefreshToken, AccessToken]
):
    def __init__(self, settings: Settings, sessions: SessionFactory) -> None:
        self.settings = settings
        self.sessions = sessions
        self.resource = settings.plugin_public_url + "/mcp"

    def digest(self, value: str) -> str:
        return token_hash(value, self.settings.credential_pepper)

    async def get_client(self, client_id: str) -> OAuthClientInformationFull | None:
        if client_id != self.settings.plugin_client_id:
            return None
        return OAuthClientInformationFull(
            client_id=client_id,
            client_name="ChatGPT · RunBuoy",
            redirect_uris=[AnyUrl(uri) for uri in self.settings.plugin_redirect_uris],
            token_endpoint_auth_method="none",
            scope=" ".join(READ_SCOPES),
            grant_types=["authorization_code", "refresh_token"],
            response_types=["code"],
        )

    async def register_client(self, client_info: OAuthClientInformationFull) -> None:
        raise RegistrationError(
            error="invalid_client_metadata", error_description="Use the configured client"
        )

    async def authorize(
        self, client: OAuthClientInformationFull, params: AuthorizationParams
    ) -> str:
        if params.resource != self.resource:
            raise AuthorizeError(
                error="invalid_target", error_description="Invalid RunBuoy resource"
            )
        scopes = params.scopes or READ_SCOPES
        if set(scopes) != set(READ_SCOPES):
            raise AuthorizeError(
                error="invalid_scope", error_description="RunBuoy requires its three read scopes"
            )
        params.scopes = scopes
        browser, challenge = new_bearer_token("pcb"), new_bearer_token("pcc")
        with self.sessions() as session:
            session.add(
                PluginAuthorization(
                    id=new_id("pca"),
                    browser_hash=self.digest(browser),
                    challenge_hash=self.digest(challenge),
                    challenge_encrypted=cipher_for(self.settings).encrypt(challenge),
                    client_id=client.client_id,
                    params=params.model_dump(mode="json"),
                    expires_at=utcnow() + timedelta(minutes=5),
                )
            )
            session.commit()
        return self.settings.plugin_public_url + "/connect/" + browser

    async def load_authorization_code(
        self, client: OAuthClientInformationFull, authorization_code: str
    ) -> AuthorizationCode | None:
        with self.sessions() as session:
            row = session.scalar(
                select(PluginAuthorization).where(
                    PluginAuthorization.code_hash == self.digest(authorization_code)
                )
            )
            if (
                row is None
                or row.client_id != client.client_id
                or row.status != "allowed"
                or row.consumed_at is not None
                or is_expired(row.expires_at)
                or row.grant_id is None
                or valid_grant(session, row.grant_id, self.settings) is None
            ):
                return None
            params = AuthorizationParams.model_validate(row.params)
            return AuthorizationCode(
                code=authorization_code,
                client_id=row.client_id,
                scopes=params.scopes or [],
                expires_at=aware(row.expires_at).timestamp(),
                code_challenge=params.code_challenge,
                redirect_uri=params.redirect_uri,
                redirect_uri_provided_explicitly=params.redirect_uri_provided_explicitly,
                resource=self.resource,
                subject=row.grant_id,
            )

    def issue_tokens(self, session: Session, grant: PluginGrant, scopes: list[str]) -> OAuthToken:
        now = utcnow()
        access, refresh = new_bearer_token("pca"), new_bearer_token("pcr")
        for raw, kind, expires in (
            (access, "access", now + timedelta(minutes=15)),
            (refresh, "refresh", grant.expires_at),
        ):
            session.add(
                PluginToken(
                    token_hash=self.digest(raw),
                    grant_id=grant.id,
                    kind=kind,
                    scopes=" ".join(scopes),
                    resource=self.resource,
                    expires_at=expires,
                )
            )
        return OAuthToken(
            access_token=access, refresh_token=refresh, expires_in=900, scope=" ".join(scopes)
        )

    async def exchange_authorization_code(
        self, client: OAuthClientInformationFull, authorization_code: AuthorizationCode
    ) -> OAuthToken:
        with self.sessions() as session:
            grant = valid_grant(session, authorization_code.subject or "", self.settings)
            if grant is None:
                raise TokenError(error="invalid_grant", error_description="Connection unavailable")
            claimed = session.execute(
                update(PluginAuthorization)
                .where(
                    PluginAuthorization.code_hash == self.digest(authorization_code.code),
                    PluginAuthorization.client_id == client.client_id,
                    PluginAuthorization.consumed_at.is_(None),
                    PluginAuthorization.expires_at > utcnow(),
                    PluginAuthorization.status == "allowed",
                )
                .values(consumed_at=utcnow(), code_encrypted=None)
                .returning(PluginAuthorization.id)
            ).scalar_one_or_none()
            if claimed is None:
                raise TokenError(
                    error="invalid_grant", error_description="Code already used or expired"
                )
            tokens = self.issue_tokens(session, grant, authorization_code.scopes)
            session.commit()
            return tokens

    async def load_refresh_token(
        self, client: OAuthClientInformationFull, refresh_token: str
    ) -> RefreshToken | None:
        with self.sessions() as session:
            row = session.get(PluginToken, self.digest(refresh_token))
            if row is None or row.kind != "refresh" or row.resource != self.resource:
                return None
            grant = valid_grant(session, row.grant_id, self.settings)
            if grant is None or grant.client_id != client.client_id or is_expired(row.expires_at):
                return None
            if row.consumed_at is not None:
                grant.revoked_at = utcnow()  # A rotated refresh token was replayed.
                session.commit()
                return None
            return RefreshToken(
                token=refresh_token,
                client_id=client.client_id,
                scopes=row.scopes.split(),
                expires_at=int(aware(row.expires_at).timestamp()),
                resource=row.resource,
                subject=grant.id,
            )

    async def exchange_refresh_token(
        self, client: OAuthClientInformationFull, refresh_token: RefreshToken, scopes: list[str]
    ) -> OAuthToken:
        with self.sessions() as session:
            grant = valid_grant(session, refresh_token.subject or "", self.settings)
            if grant is None or grant.client_id != client.client_id:
                raise TokenError(error="invalid_grant", error_description="Connection unavailable")
            claimed = session.execute(
                update(PluginToken)
                .where(
                    PluginToken.token_hash == self.digest(refresh_token.token),
                    PluginToken.consumed_at.is_(None),
                    PluginToken.expires_at > utcnow(),
                )
                .values(consumed_at=utcnow())
                .returning(PluginToken.token_hash)
            ).scalar_one_or_none()
            if claimed is None:
                grant.revoked_at = utcnow()
                session.commit()
                raise TokenError(
                    error="invalid_grant", error_description="Refresh token already used"
                )
            # Keep unexpired access tokens usable during concurrent host requests.
            # Grant revocation (including refresh replay) invalidates every token.
            result = self.issue_tokens(session, grant, scopes)
            session.commit()
            return result

    async def load_access_token(self, token: str) -> AccessToken | None:
        with self.sessions() as session:
            row = session.get(PluginToken, self.digest(token))
            if (
                row is None
                or row.kind != "access"
                or row.consumed_at is not None
                or row.resource != self.resource
                or is_expired(row.expires_at)
            ):
                return None
            grant = valid_grant(session, row.grant_id, self.settings)
            if grant is None:
                return None
            return AccessToken(
                token=token,
                client_id=grant.client_id,
                scopes=row.scopes.split(),
                expires_at=int(aware(row.expires_at).timestamp()),
                resource=self.resource,
                subject=grant.id,
                claims={"workspace_id": grant.workspace_id},
            )

    async def revoke_token(self, token: AccessToken | RefreshToken) -> None:
        with self.sessions() as session:
            grant = session.get(PluginGrant, token.subject or "")
            if grant is not None:
                grant.revoked_at = utcnow()
                session.commit()


class ConnectionChallenge(BaseModel):
    model_config = ConfigDict(extra="forbid")
    challenge: str = Field(min_length=20, max_length=256)


class ConnectionDecision(ConnectionChallenge):
    decision: Literal["allow", "deny"]


def _device(principal: Principal, settings: Settings) -> None:
    if not settings.plugin_enabled:
        raise HTTPException(404, "plugin not enabled")
    if principal.kind != "device":
        raise HTTPException(403, "device credential required")
    if principal.workspace_id not in settings.plugin_workspace_allowlist:
        raise HTTPException(403, "This workspace is not enrolled in the RunBuoy plugin preview")


def _authorization(
    session: Session, request_id: str, challenge: str, settings: Settings
) -> PluginAuthorization:
    row = session.scalar(
        select(PluginAuthorization).where(PluginAuthorization.id == request_id).with_for_update()
    )
    if row is None or not hmac.compare_digest(
        row.challenge_hash, token_hash(challenge, settings.credential_pepper)
    ):
        raise HTTPException(404, "connection request not found")
    if is_expired(row.expires_at):
        raise HTTPException(410, "connection request expired")
    return row


@router.post("/v1/plugin-connections/requests/{request_id}/inspect")
def inspect_connection(
    request_id: str,
    body: ConnectionChallenge,
    request: Request,
    session: Session = Depends(get_session),
    principal: Principal = Depends(authenticate),
) -> dict[str, Any]:
    settings = request.app.state.settings
    _device(principal, settings)
    row = _authorization(session, request_id, body.challenge, settings)
    return {
        "id": row.id,
        "client_name": "ChatGPT · RunBuoy",
        "origin": settings.plugin_public_url,
        "workspace_id": principal.workspace_id,
        "scopes": row.params["scopes"],
        "status": row.status,
        "expires_at": row.expires_at,
    }


@router.post("/v1/plugin-connections/requests/{request_id}/decision", status_code=204)
def decide_connection(
    request_id: str,
    body: ConnectionDecision,
    request: Request,
    session: Session = Depends(get_session),
    principal: Principal = Depends(authenticate),
) -> Response:
    settings = request.app.state.settings
    _device(principal, settings)
    row = _authorization(session, request_id, body.challenge, settings)
    # Conditional update also protects SQLite, where FOR UPDATE is ignored.
    claimed = session.execute(
        update(PluginAuthorization)
        .where(PluginAuthorization.id == row.id, PluginAuthorization.status == "pending")
        .values(status="allowed" if body.decision == "allow" else "denied")
        .returning(PluginAuthorization.id)
    ).scalar_one_or_none()
    if claimed is None:
        raise HTTPException(409, "connection request already decided")
    if body.decision == "allow":
        grant = PluginGrant(
            id=new_id("pcg"),
            workspace_id=principal.workspace_id,
            device_id=principal.subject_id,
            client_id=row.client_id,
            scopes=" ".join(row.params["scopes"]),
            expires_at=utcnow() + timedelta(days=30),
        )
        session.add(grant)
        session.flush()
        code = new_bearer_token("pccode")
        row.grant_id = grant.id
        row.code_hash = token_hash(code, settings.credential_pepper)
        row.code_encrypted = cipher_for(settings).encrypt(code)
    session.add(
        AuditLog(
            id=new_id("aud"),
            workspace_id=principal.workspace_id,
            actor_type="device",
            actor_id=principal.subject_id,
            action="plugin.connection." + body.decision,
            metadata_json={"request_id": row.id},
        )
    )
    session.commit()
    return Response(status_code=204, headers=NO_STORE)


@router.get("/v1/plugin-connections")
def list_connections(
    request: Request,
    session: Session = Depends(get_session),
    principal: Principal = Depends(authenticate),
) -> list[dict[str, Any]]:
    _device(principal, request.app.state.settings)
    rows = session.scalars(
        select(PluginGrant)
        .where(
            PluginGrant.device_id == principal.subject_id,
            PluginGrant.workspace_id == principal.workspace_id,
            PluginGrant.revoked_at.is_(None),
            PluginGrant.expires_at > utcnow(),
        )
        .order_by(PluginGrant.created_at.desc())
    )
    return [
        {
            "id": row.id,
            "client_name": "ChatGPT · RunBuoy",
            "scopes": row.scopes.split(),
            "created_at": row.created_at,
            "expires_at": row.expires_at,
        }
        for row in rows
    ]


@router.delete("/v1/plugin-connections/{connection_id}", status_code=204)
def delete_connection(
    connection_id: str,
    request: Request,
    session: Session = Depends(get_session),
    principal: Principal = Depends(authenticate),
) -> Response:
    _device(principal, request.app.state.settings)
    grant = session.get(PluginGrant, connection_id)
    if (
        grant is None
        or grant.device_id != principal.subject_id
        or grant.workspace_id != principal.workspace_id
    ):
        raise HTTPException(404, "connection not found")
    grant.revoked_at = utcnow()
    session.add(
        AuditLog(
            id=new_id("aud"),
            workspace_id=principal.workspace_id,
            actor_type="device",
            actor_id=principal.subject_id,
            action="plugin.connection.revoke",
            metadata_json={"grant_id": grant.id},
        )
    )
    session.commit()
    return Response(status_code=204, headers=NO_STORE)


def _browser_session(session: Session, browser: str, settings: Settings) -> PluginAuthorization:
    if not settings.plugin_enabled:
        raise HTTPException(404, "plugin not enabled")
    row = session.scalar(
        select(PluginAuthorization).where(
            PluginAuthorization.browser_hash == token_hash(browser, settings.credential_pepper)
        )
    )
    if row is None:
        raise HTTPException(404, "connection request not found")
    if is_expired(row.expires_at):
        raise HTTPException(410, "Connection expired. Start again from ChatGPT.")
    return row


@router.get("/connect/{browser}/status")
def connection_status(
    browser: str, request: Request, session: Session = Depends(get_session)
) -> JSONResponse:
    settings = request.app.state.settings
    row = _browser_session(session, browser, settings)
    result: dict[str, Any] = {"status": row.status}
    if row.consumed_at is not None:
        result["status"] = "completed"
    elif row.status in {"allowed", "denied"}:
        params = AuthorizationParams.model_validate(row.params)
        query = {"state": params.state or "", "iss": str(AnyUrl(settings.plugin_public_url))}
        if row.status == "allowed" and row.code_encrypted:
            query["code"] = cipher_for(settings).decrypt(row.code_encrypted)
        else:
            query["error"] = "access_denied"
        uri = str(params.redirect_uri)
        result["redirect_url"] = uri + ("&" if "?" in uri else "?") + urlencode(query)
    return JSONResponse(result, headers=NO_STORE)


@router.get("/connect/{browser}", response_class=HTMLResponse)
def connection_page(
    browser: str, request: Request, session: Session = Depends(get_session)
) -> HTMLResponse:
    import html
    import io
    import secrets

    import qrcode
    import qrcode.image.svg

    settings = request.app.state.settings
    row = _browser_session(session, browser, settings)
    challenge = cipher_for(settings).decrypt(row.challenge_encrypted)
    deep_link = f"runbuoy://connect/{row.id}?" + urlencode({"challenge": challenge})
    qr = qrcode.make(deep_link, image_factory=qrcode.image.svg.SvgPathImage)
    output = io.BytesIO()
    qr.save(output)
    svg = output.getvalue().decode().split("?>")[-1]
    nonce = secrets.token_urlsafe(24)
    page = (Path(__file__).parent / "static" / "connect.html").read_text()
    page = page.replace("__NONCE__", nonce).replace("__QR__", svg)
    page = page.replace("__LINK__", html.escape(deep_link, quote=True))
    return HTMLResponse(
        page,
        headers={
            **NO_STORE,
            "Content-Security-Policy": (
                f"default-src 'none'; script-src 'nonce-{nonce}'; style-src 'nonce-{nonce}'; "
                "connect-src 'self'; img-src 'self' data:; base-uri 'none'; "
                "frame-ancestors 'none'; form-action 'none'"
            ),
            "X-Content-Type-Options": "nosniff",
        },
    )
