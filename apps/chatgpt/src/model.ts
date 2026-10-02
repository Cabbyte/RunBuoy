export type View = "active" | "history" | "machines" | "messages";
export interface Progress {
  kind: string;
  current?: number | null;
  total?: number | null;
  fraction?: number | null;
  unit?: string | null;
  estimated_end_at?: string | null;
  source?: string;
}
export interface Run {
  id: string;
  title: string;
  machine_id: string;
  machine_name: string;
  source?: string;
  execution_status: string;
  health_status: string;
  attention_status: string;
  progress?: Progress | null;
  phase?: string | null;
  safe_message?: string | null;
  safe_log_tail?: string[] | null;
  created_at: string;
  started_at?: string | null;
  updated_at: string;
  ended_at?: string | null;
  exit_code?: number | null;
  termination_reason?: string | null;
  sequence: number;
}
export interface Machine {
  id: string;
  display_name: string;
  platform?: string | null;
  architecture?: string | null;
  cli_version?: string | null;
  last_seen_at: string;
  paired_at: string;
}
export interface Message {
  id: string;
  machine_id?: string | null;
  run_id?: string | null;
  title: string;
  subtitle?: string | null;
  body: string;
  level: string;
  fields: { label: string; value: string }[];
  created_at: string;
  expires_at?: string | null;
}
export interface Event {
  event_id: string;
  seq: number;
  type: string;
  occurred_at: string;
  payload: {
    phase?: string;
    message?: string;
    safe_message?: string;
    progress?: Progress;
  };
}
export interface EventPage {
  items: Event[];
  has_more: boolean;
  before_seq: number | null;
  after_seq: number | null;
  sequence: number;
}
export interface Overview {
  next_cursor: number;
  server_time: string;
  runs: Run[];
  machines: Machine[];
  notifications: Message[];
  history_runs_next_cursor: string | null;
  history_runs_has_more: boolean;
  history_notifications_next_cursor: string | null;
  history_notifications_has_more: boolean;
}
export interface Detail {
  run: Run;
  events: EventPage;
}
export interface HistoryPage {
  kind: "runs" | "messages";
  items: (Run | Message)[];
  next_cursor: string | null;
  has_more: boolean;
}
export interface ToolData {
  overview?: Overview | null;
  not_modified?: boolean;
  run?: Run;
  events?: EventPage;
  history?: HistoryPage;
  machines?: Machine[];
}
export const terminal = new Set(["SUCCEEDED", "FAILED", "CANCELLED", "LOST"]);
export const active = (r: Run) => !terminal.has(r.execution_status);
// Freshness describes the last confirmation, not the machine's execution state.
export function isStale(r: Run, now: number): boolean {
  return active(r) && now - Date.parse(r.updated_at) > 60_000;
}
export function needsAttention(r: Run, now: number): boolean {
  return (
    active(r) &&
    (["critical", "warning"].includes(status(r).tone) || isStale(r, now))
  );
}
export function relativeTime(
  value: string,
  now: number,
  locale: string,
): string {
  const seconds = Math.max(0, Math.round((now - Date.parse(value)) / 1000));
  if (!Number.isFinite(seconds)) return "—";
  const [divisor, unit] =
    seconds < 60
      ? ([1, "second"] as const)
      : seconds < 3600
        ? ([60, "minute"] as const)
        : seconds < 86400
          ? ([3600, "hour"] as const)
          : ([86400, "day"] as const);
  return new Intl.RelativeTimeFormat(locale, { numeric: "auto" }).format(
    -Math.floor(seconds / divisor),
    unit,
  );
}
export type Tone = "neutral" | "live" | "success" | "warning" | "critical";
export function status(r: Run): { key: string; tone: Tone } {
  if (terminal.has(r.execution_status))
    return {
      key: r.execution_status,
      tone:
        r.execution_status === "SUCCEEDED"
          ? "success"
          : r.execution_status === "FAILED"
            ? "critical"
            : "neutral",
    };
  if (!["CREATED", "STARTING", "RUNNING"].includes(r.execution_status))
    return { key: "UNKNOWN", tone: "neutral" };
  if (["STALE", "OFFLINE"].includes(r.health_status))
    return { key: r.health_status, tone: "warning" };
  if (r.attention_status === "ACTION_REQUIRED")
    return { key: r.attention_status, tone: "critical" };
  if (r.attention_status === "WARNING")
    return { key: r.attention_status, tone: "warning" };
  if (r.attention_status === "INFORMATION")
    return { key: r.attention_status, tone: "neutral" };
  if (r.health_status !== "HEALTHY" || r.attention_status !== "NONE")
    return { key: "UNKNOWN", tone: "neutral" };
  return {
    key: r.execution_status,
    tone: r.execution_status === "RUNNING" ? "live" : "neutral",
  };
}
export function fraction(p?: Progress | null): number | null {
  if (
    p?.kind !== "determinate" ||
    !Number.isFinite(p.current) ||
    !Number.isFinite(p.total) ||
    !Number.isFinite(p.fraction) ||
    p.total! <= 0 ||
    p.current! < 0
  )
    return null;
  return Math.min(1, Math.max(0, p.fraction!));
}
export function cadence(hasActive: boolean, failures: number): number {
  return Math.min(
    300_000,
    (hasActive ? 10_000 : 30_000) * 2 ** Math.min(8, Math.max(0, failures)),
  );
}
export function confirmedDuration(r: Run): number | null {
  if (!r.started_at) return null;
  const end = Date.parse(r.ended_at || r.updated_at),
    start = Date.parse(r.started_at);
  return Number.isFinite(end - start) ? Math.max(0, end - start) : null;
}
export function mergeOverview(
  previous: Overview | null,
  incoming: Overview,
): Overview {
  if (!previous) return incoming;
  if (incoming.next_cursor < previous.next_cursor) return previous;
  const previousRuns = new Map(previous.runs.map((r) => [r.id, r]));
  return {
    ...incoming,
    runs: incoming.runs.map((r) => {
      const old = previousRuns.get(r.id);
      return old && old.sequence > r.sequence ? old : r;
    }),
  };
}
export function mergeEvents(old: Event[], page: Event[]): Event[] {
  return [
    ...new Map([...old, ...page].map((e) => [e.event_id, e])).values(),
  ].sort((a, b) => a.seq - b.seq);
}
export function orderedRuns(runs: Run[], now = Date.now()): Run[] {
  const rank = (r: Run) =>
    r.attention_status === "ACTION_REQUIRED"
      ? 0
      : r.attention_status === "WARNING"
        ? 1
        : ["STALE", "OFFLINE"].includes(r.health_status) || isStale(r, now)
          ? 2
          : 3;
  return [...runs].sort(
    (a, b) =>
      rank(a) - rank(b) ||
      Date.parse(b.updated_at) - Date.parse(a.updated_at) ||
      a.id.localeCompare(b.id),
  );
}
