# RunBuoy ChatGPT plugin

The private preview adds a read-only ChatGPT client beside iOS. It uses the same
workspace projection and event sequence; it never sends commands to a machine.
The source package is under `plugins/runbuoy`. It targets the production `/mcp`
endpoint, which must be deployed and verified before the package is installed.

## Components

- `server/app/read_models.py`: shared iOS/MCP projection, sync and history; event
  pages default to the most recent 100 events. `before_seq` loads older records;
  `after_seq` loads newer records. Boundaries are exclusive, ordered by sequence.
- `server/app/plugin_auth.py`: OAuth discovery, authorization code + S256 PKCE,
  phone consent, independent viewer grants, token rotation and revocation.
- `server/app/plugin_mcp.py`: six tools and one self-contained MCP Apps resource.
  Only `open_runbuoy` creates a widget. Its empty input works for both `global`
  and `thread` entrypoints. `inline` and `fullscreen` share the same frontend.
- `apps/chatgpt`: React/TypeScript, MCP Apps bridge, active/history/machines/messages
  and Run detail. Full UI data is in result `_meta.runbuoy`; model summaries omit
  log excerpts unless explicitly requested. React renders shared text as text.
- `apps/ios/RunBuoyApp/PluginConnectionsView.swift`: scan or paste a connection
  link, review workspace and permissions, explicitly allow/deny, list/revoke.

Read tools: `open_runbuoy`, `get_overview`, `get_run`, `get_run_events`,
`list_history`, `list_machines`. All require the three scopes `runs:read`,
`machines:read`, `notifications:read`. The viewer credential works only at MCP;
Device/Machine credentials are rejected there. iOS receiving-plane APIs still
require their original credentials.

## Refresh and state

A visible UI refreshes every 10 seconds with active Runs, otherwise 30 seconds.
Failures back off exponentially to five minutes. Hidden tabs/iframes pause;
returning to visibility triggers a refresh. Lower workspace revisions and Run
sequences cannot replace newer data. Terminal status takes precedence; future
states are shown as unknown. Progress and ETA require explicitly supplied data.
The UI distinguishes last checked from last machine confirmation. Revocation
clears the UI cache; it cannot erase information already shared into a chat.

Events and log excerpts follow existing server retention. Native push
notifications, Live Activities and iPhone system permissions remain in iOS.

## Build and tests

```sh
npm ci --prefix apps/chatgpt
npm test --prefix apps/chatgpt
npm run build --prefix apps/chatgpt
uv sync --project server --all-extras
uv run --project server pytest server/tests
uv run --project server ruff check server
uv run --project server mypy server/app server/worker
```

`npm run dev --prefix apps/chatgpt -- --port 5179` serves a local development
preview. `http://127.0.0.1:5179/?demo&lang=zh&mode=inline` shows synthetic data;
`theme=dark` and `empty` cover display states. Demo code is excluded from the
production build. A standalone production page asks to open from ChatGPT.

The API Dockerfile builds the UI and copies its single HTML file into the Python
package. Enabling the plugin without that resource fails startup. New migration
`0007_plugin` adds only OAuth tables and indexes; it also handles fresh databases
whose legacy initial migration builds current SQLAlchemy metadata. Disabling the
feature flag removes MCP/OAuth availability without reverting the additive schema.

PostgreSQL concurrency tests use `RUNBUOY_TEST_POSTGRES_URL` and **drop all tables**
in that test database, as the existing PostgreSQL test harness does. Always use
a dedicated disposable database. Test phone challenges and credentials are synthetic.

## Private rollout

1. Follow the existing [deployment guide](../developer-guide/deployment-and-release.md).
   Ship a green server commit before the dependent iOS build. Existing production
   workflows deploy only green pushes on `main`; do not bypass the release gate.
2. Set the following on the API and worker's existing environment file:

   ```dotenv
   RUNBUOY_PLUGIN_ENABLED=true
   RUNBUOY_PLUGIN_PUBLIC_URL=https://api.runbuoy.cloud
   RUNBUOY_PLUGIN_CLIENT_ID=runbuoy-chatgpt
   RUNBUOY_PLUGIN_REDIRECT_URIS=https://chatgpt.com/connector_platform_oauth_redirect
   RUNBUOY_PLUGIN_WORKSPACES=YOUR_APPROVED_WORKSPACE_ID
   ```

   Use exact redirect URI(s) supplied by the actual ChatGPT client. No wildcards.
   The example callback must be verified when registering the private client.
   Empty workspace allowlist denies every phone approval. Reuse server encryption
   and pepper configuration; do not put tokens or secrets into the plugin package.
3. Publish OAuth metadata at `/.well-known/oauth-authorization-server` and
   `/.well-known/oauth-protected-resource/mcp`; `/mcp` without a token returns 401
   with a resource metadata challenge. Use a pre-registered public OAuth client,
   client ID `runbuoy-chatgpt`, no client secret, S256 PKCE and resource `/mcp`.
4. Release TestFlight using the existing exact-SHA green CI gate. On iPhone,
   Settings → Connected apps accepts the QR/link. Confirm only your own request.
   Requests expire after five minutes. Access tokens last 15 minutes; refresh
   tokens rotate until the connection's fixed 30-day expiry. Refresh-token reuse
   revokes the connection. Revoke, device reset and workspace deletion deny all
   subsequent reads. Expired OAuth records are removed by bounded retention jobs.
5. Verify real authenticated tool discovery before uploading `plugins/runbuoy`
   as a private package. Host OAuth registration is separate from the ZIP. The
   plugin does not require an OpenAI model API key.
6. Verify the same real Run ID, sequence, execution/health/attention state,
   progress and confirmation timestamp in iOS and both ChatGPT entrypoints.
   Observe a running → terminal transition, revoke from iPhone, then verify the
   next MCP request fails and the UI clears. Check denial, timeout and reconnect.

Extensions placement depends on the client. Registering entrypoints or previewing
React locally does not prove the ChatGPT sidebar works. On unsupported clients,
the inline tool card remains the fallback. Real phone approval, real host entrypoint
placement and TestFlight distribution are separate acceptance gates.

Official references: [MCP server](https://developers.openai.com/plugins/build/mcp-server),
[UI](https://developers.openai.com/plugins/build/chatgpt-ui),
[Extensions](https://developers.openai.com/plugins/build/extensions),
[OAuth](https://developers.openai.com/plugins/build/auth).
