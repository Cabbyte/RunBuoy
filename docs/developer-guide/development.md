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

The runtime Dynamic Type UI tests use the host's supported `simctl ui
content_size` control. Run them through the wrapper below with a specific
Simulator UUID in `RUNBUOY_TEST_DEVICE`:

```bash
xcrun simctl bootstatus "$RUNBUOY_TEST_DEVICE" -b
python3 scripts/run_ios_system_size_tests.py \
  --device "$RUNBUOY_TEST_DEVICE" \
  --evidence-dir /tmp/runbuoy-runtime-size-results -- \
  xcodebuild -project apps/ios/RunBuoy.xcodeproj -scheme RunBuoy \
  -destination "platform=iOS Simulator,id=$RUNBUOY_TEST_DEVICE" \
  -parallel-testing-enabled NO \
  -only-testing:RunBuoyUITests/TypographyDiagnosticsTests/testRuntimeFontSwitchPreservesAppAndMachineNavigation \
  -only-testing:RunBuoyUITests/TypographyDiagnosticsTests/testRuntimeFontSwitchRestoresSizeAfterInjectedFailure \
  CODE_SIGNING_ALLOWED=NO test
```

The existing runtime test launches the sample app once and retains its glyph,
complete-text, and Machines navigation checks. The wrapper and XCTest exchange
requests in the test runner's own Documents directory; the wrapper checks the
same app PID and reads the live UIApplication and window categories with LLDB.
XCTest restores the original size before terminating the app, including an
injected failure after a verified maximum-size change. The host also restores
the system size if XCTest aborts; a missing live-app teardown remains a failure.
Running these tests without the wrapper fails explicitly rather than skipping
them. The full latest-iOS CI UI step and typography controls use this wrapper;
native accessibility audits retain every finding.

## E2E

```bash
./scripts/e2e_smoke.sh
```

The smoke environment uses PostgreSQL plus `APNS_MODE=mock`; it verifies
pairing, long/short Runs, push lifecycle payloads, read projections, and the
absence of remote-control routes.
