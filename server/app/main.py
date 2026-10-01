from __future__ import annotations

from collections.abc import AsyncIterator, Iterator
from contextlib import asynccontextmanager, contextmanager
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

import uvicorn
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from .abuse import RequestBodyLimitMiddleware, anonymous_ip_key, enforce_rate_limit
from .api import router
from .config import Settings
from .database import get_session
from .lifecycle import router as lifecycle_router
from .observability import install_observability
from .plugin_auth import authorization_metadata
from .plugin_auth import router as plugin_router


def create_app(settings: Settings | None = None) -> FastAPI:
    configured = settings or Settings.from_env()
    configured.validate()
    application = FastAPI(
        title="RunBuoy API",
        version="1.2.0",
        description=(
            "One-way Machine-to-iPhone execution projection. "
            "No remote command or terminal control plane exists."
        ),
    )
    application.state.settings = configured
    application.include_router(router)
    application.include_router(lifecycle_router)
    application.include_router(plugin_router)

    @application.get("/healthz", include_in_schema=False)
    def health() -> dict[str, str]:
        return {"status": "ok", "region": configured.region}

    install_observability(application)

    if configured.plugin_enabled:
        from .plugin_mcp import create_plugin

        @contextmanager
        def plugin_sessions() -> Iterator[Session]:
            dependency = application.dependency_overrides.get(get_session, get_session)
            yield from dependency()

        server, mcp_app = create_plugin(configured, plugin_sessions)
        application.state.plugin_server = server
        metadata = authorization_metadata(configured)

        @application.get("/.well-known/oauth-authorization-server", include_in_schema=False)
        def plugin_metadata() -> JSONResponse:
            return JSONResponse(metadata, headers={"Access-Control-Allow-Origin": "*"})

        @asynccontextmanager
        async def plugin_lifespan(app: FastAPI) -> AsyncIterator[None]:
            async with mcp_app.router.lifespan_context(mcp_app):
                yield

        application.router.lifespan_context = plugin_lifespan

        @application.middleware("http")
        async def protect_plugin_requests(request: Request, call_next):  # type: ignore[no-untyped-def]
            path = request.url.path
            if path in {"/authorize", "/token", "/revoke", "/mcp"} or path.startswith(
                ("/connect/", "/v1/plugin-connections")
            ):
                try:
                    with plugin_sessions() as session:
                        enforce_rate_limit(
                            session,
                            configured,
                            Response(),
                            bucket_name="plugin-authorize"
                            if path == "/authorize"
                            else "plugin-mcp"
                            if path == "/mcp"
                            else "plugin-requests",
                            subject_key=anonymous_ip_key(request, configured),
                            limit=30 if path == "/authorize" else 600 if path == "/mcp" else 120,
                            window_seconds=3600 if path == "/authorize" else 60,
                        )
                except HTTPException as exc:
                    return JSONResponse(
                        {"detail": exc.detail}, status_code=exc.status_code, headers=exc.headers
                    )
                if path == "/token" and request.method == "POST":
                    await request.body()
                    form = await request.form()
                    if form.get("resource") != configured.plugin_public_url + "/mcp":
                        return JSONResponse(
                            {"error": "invalid_target"},
                            status_code=400,
                            headers={"Cache-Control": "no-store"},
                        )
            response = await call_next(request)
            if path == "/authorize" and response.status_code in {302, 303, 307}:
                # The SDK validates the registered redirect before emitting an
                # error callback, but does not yet include RFC 9207 issuer data.
                target = urlsplit(response.headers.get("location", ""))
                params = parse_qsl(target.query, keep_blank_values=True)
                if any(key == "error" for key, _ in params):
                    params = [(key, value) for key, value in params if key != "iss"]
                    params.append(("iss", metadata["issuer"]))
                    response.headers["location"] = urlunsplit(
                        target._replace(query=urlencode(params))
                    )
            if path.startswith("/v1/plugin-connections"):
                response.headers["Cache-Control"] = "no-store"
            return response

        application.mount("/", mcp_app)

    application.add_middleware(
        RequestBodyLimitMiddleware,
        max_bytes=configured.max_request_body_bytes,
    )

    return application


app = create_app()


def run() -> None:
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, access_log=False)
