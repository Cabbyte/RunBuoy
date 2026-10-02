import assert from "node:assert/strict";
import { test } from "node:test";
import {
  active,
  cadence,
  confirmedDuration,
  fraction,
  isStale,
  needsAttention,
  orderedRuns,
  relativeTime,
  mergeEvents,
  mergeOverview,
  status,
  type Overview,
  type Run,
} from "../src/model";
import { unwrap, ConnectionError } from "../src/bridge";
const run: Run = {
  id: "r",
  title: "Test",
  machine_id: "m",
  machine_name: "Mac",
  execution_status: "RUNNING",
  health_status: "HEALTHY",
  attention_status: "NONE",
  sequence: 8,
  created_at: "2026-01-01T00:00:00Z",
  started_at: "2026-01-01T00:00:00Z",
  updated_at: "2026-01-01T00:01:00Z",
};
const overview: Overview = {
  next_cursor: 10,
  server_time: run.updated_at,
  runs: [run],
  machines: [],
  notifications: [],
  history_runs_next_cursor: null,
  history_runs_has_more: false,
  history_notifications_next_cursor: null,
  history_notifications_has_more: false,
};
test("terminal outranks old warning; offline and unknown never animate as live", () => {
  assert.deepEqual(
    status({
      ...run,
      execution_status: "SUCCEEDED",
      health_status: "OFFLINE",
      attention_status: "ACTION_REQUIRED",
    }),
    { key: "SUCCEEDED", tone: "success" },
  );
  assert.equal(status({ ...run, health_status: "OFFLINE" }).tone, "warning");
  assert.equal(status({ ...run, execution_status: "FUTURE" }).key, "UNKNOWN");
  assert.notEqual(status({ ...run, health_status: "FUTURE" }).tone, "live");
  assert.equal(active({ ...run, execution_status: "FUTURE" }), true);
});
test("uncertain progress stays unknown, explicit progress is bounded", () => {
  for (const p of [
    null,
    { kind: "indeterminate" },
    { kind: "determinate", current: 3, total: 10 },
    { kind: "determinate", current: 3, total: 0, fraction: 0.3 },
  ])
    assert.equal(fraction(p), null);
  assert.equal(
    fraction({ kind: "determinate", current: 3, total: 10, fraction: 0.3 }),
    0.3,
  );
  assert.equal(
    fraction({ kind: "determinate", current: 11, total: 10, fraction: 1.1 }),
    1,
  );
  assert.equal(confirmedDuration(run), 60_000);
  assert.equal(confirmedDuration({ ...run, started_at: null }), null);
});
test("old revisions and sequences cannot replace newer state, deletions do apply", () => {
  assert.equal(
    mergeOverview(overview, { ...overview, next_cursor: 9, runs: [] }),
    overview,
  );
  assert.equal(
    mergeOverview(overview, {
      ...overview,
      next_cursor: 11,
      runs: [{ ...run, sequence: 7, title: "Old" }],
    }).runs[0].title,
    "Test",
  );
  assert.equal(
    mergeOverview(overview, { ...overview, next_cursor: 12, runs: [] }).runs
      .length,
    0,
  );
});
test("pagination deduplicates overlap and keeps sequence order", () => {
  const e = (seq: number) => ({
    event_id: String(seq),
    seq,
    type: "run.progress",
    occurred_at: run.updated_at,
    payload: {},
  });
  assert.deepEqual(
    mergeEvents([e(3), e(4)], [e(1), e(3), e(2)]).map((e) => e.seq),
    [1, 2, 3, 4],
  );
});
test("polling uses activity cadence and bounded exponential backoff", () => {
  assert.equal(cadence(true, 0), 10_000);
  assert.equal(cadence(false, 0), 30_000);
  assert.equal(cadence(true, 2), 40_000);
  assert.equal(cadence(false, 20), 300_000);
});
test("freshness includes old active confirmations without replacing execution state", () => {
  const confirmed = Date.parse(run.updated_at);
  const created = { ...run, execution_status: "CREATED" };
  assert.equal(isStale(created, confirmed + 60_000), false);
  assert.equal(isStale(created, confirmed + 60_001), true);
  assert.equal(needsAttention(created, confirmed + 60_001), true);
  assert.equal(status(created).key, "CREATED");
  assert.equal(isStale(run, confirmed - 60_000), false);
  assert.equal(isStale({ ...run, updated_at: "invalid" }, confirmed), false);
  const completed = { ...run, execution_status: "SUCCEEDED" };
  assert.equal(isStale(completed, confirmed + 86400_000), false);
  assert.equal(needsAttention(completed, confirmed + 86400_000), false);
  assert.equal(
    needsAttention({ ...run, attention_status: "ACTION_REQUIRED" }, confirmed),
    true,
  );
});
test("desktop initial selection prioritizes required actions, then overdue updates", () => {
  const now = Date.parse(run.updated_at) + 120_000;
  const fresh = {
    ...run,
    id: "fresh",
    updated_at: new Date(now).toISOString(),
  };
  const required = {
    ...fresh,
    id: "required",
    attention_status: "ACTION_REQUIRED",
  };
  const stale = { ...run, id: "stale" };
  assert.deepEqual(
    orderedRuns([fresh, stale, required], now).map((r) => r.id),
    ["required", "stale", "fresh"],
  );
});
test("long confirmation ages use days and remain readable in both languages", () => {
  const confirmed = Date.parse(run.updated_at);
  assert.equal(
    relativeTime(run.updated_at, confirmed + 1375 * 3600_000, "en-US"),
    "57 days ago",
  );
  assert.equal(
    relativeTime(run.updated_at, confirmed + 1375 * 3600_000, "zh-CN"),
    "57天前",
  );
  assert.equal(
    relativeTime(run.updated_at, confirmed + 23 * 3600_000, "en-US"),
    "23 hours ago",
  );
  assert.equal(
    relativeTime(run.updated_at, confirmed + 24 * 3600_000, "en-US"),
    "yesterday",
  );
  assert.equal(relativeTime("invalid", confirmed, "en-US"), "—");
});
test("UI data uses metadata, auth errors retain reconnect signal", () => {
  assert.equal(
    unwrap({
      _meta: { runbuoy: { overview } },
      structuredContent: { active_count: 1 },
    }).data.overview,
    overview,
  );
  assert.throws(
    () =>
      unwrap({
        isError: true,
        _meta: { "mcp/www_authenticate": ["Bearer"] },
        content: [{ type: "text", text: "Reconnect" }],
      }),
    (e) => e instanceof ConnectionError && e.auth,
  );
});
