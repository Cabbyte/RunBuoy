# Development

## Development baseline

As of the 2026-10-01 cleanup, use `main` as the starting point for future
RunBuoy development and new task branches. It includes the selected v3
continuation at `39111560d68b7c014cdab92a38ccdcdc4095a5c2` and the approved
machine layout, compact history filters, and settings icon refinements at
`17e0d3cbfc7fc39084c30e089989ee15871bd073`.

The user originally selected baseline A:
`origin/codex/ios-signal-buoy-v2` at
`19e69b443fdc8da6dad9aad8308b3902a819825a`.

Baseline B, `origin/codex/ios-signal-buoy-v2-20260813-205116` at
`3a699aad17a4dd58a9e7a19aad4995a92602a77f`, is temporarily deprecated as a
development baseline. Preserve that branch and its unique commits for reference;
any useful fixes can be evaluated separately before being carried forward.
This baseline decision does not merge or delete B.

## Prerequisites

- Python 3.12+ managed with `uv`
- tmux on macOS or Linux
- Docker for PostgreSQL integration/E2E
- Xcode on macOS for iOS builds and tests

## Protocol and security

```bash
uv sync --group dev
uv run pytest packages/protocol/tests
uv run python scripts/check_read_only_boundary.py
uvx openapi-spec-validator packages/protocol/openapi.yaml
```

## CLI

```bash
cd cli
uv sync --all-groups
uv run ruff check .
uv run mypy src
uv run pytest
```

Package construction, isolated-install checks, and PyPI release steps are in
[`cli-distribution.md`](cli-distribution.md).

## Server

```bash
cd server
uv sync --all-groups
uv run alembic upgrade head
uv run ruff check .
uv run mypy app worker
uv run pytest
```

Server tests use isolated configuration and mock APNs. PostgreSQL parity and
E2E run in Docker/GitHub Actions.

## iOS

```bash
xcodebuild \
  -project apps/ios/RunBuoy.xcodeproj \
  -scheme RunBuoy \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Simulator unit tests run only where an installed Xcode runtime is available.
Signing and real APNs require external Apple configuration.

## E2E

```bash
./scripts/e2e_smoke.sh
```

The smoke environment uses PostgreSQL plus `APNS_MODE=mock`; it verifies
pairing, long/short Runs, push lifecycle payloads, read projections, and the
absence of remote-control routes.
