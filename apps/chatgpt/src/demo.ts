import type { Bridge, BridgeState, Envelope } from "./bridge";
import type { Overview, Run } from "./model";
const ago = (s: number) => new Date(Date.now() - s * 1000).toISOString();
const run = (
  id: string,
  title: string,
  pct: number,
  extra: Partial<Run> = {},
): Run => ({
  id,
  title,
  machine_id: "mac",
  machine_name: "Build Mac",
  execution_status: "RUNNING",
  health_status: "HEALTHY",
  attention_status: "NONE",
  phase: "Processing",
  progress: {
    kind: "determinate",
    current: pct,
    total: 100,
    fraction: pct / 100,
    unit: "steps",
  },
  created_at: ago(1235),
  started_at: ago(1220),
  updated_at: ago(5),
  sequence: 24,
  ...extra,
});
const runs = [
  run(
    "01900000-0000-7000-8000-000000000001",
    "Training · depth-estimation-v4",
    68,
    {
      phase: "Epoch 34 of 50",
      machine_id: "gpu",
      machine_name: "Studio GPU",
      safe_message: "Validation loss improved to 0.042. Saving checkpoint.",
      safe_log_tail: [
        "epoch 34 / 50 · loss 0.042",
        "checkpoint saved · validation passed",
      ],
    },
  ),
  run("01900000-0000-7000-8000-000000000002", "iOS · Release build", 42, {
    phase: "Compiling Swift modules",
  }),
  run(
    "01900000-0000-7000-8000-000000000003",
    "Data preparation · coastal-set",
    0,
    {
      phase: "Waiting for source data",
      progress: { kind: "indeterminate" },
      attention_status: "ACTION_REQUIRED",
      safe_message: "Dataset is ready for local review.",
    },
  ),
  run("01900000-0000-7000-8000-000000000004", "API · Integration tests", 100, {
    execution_status: "SUCCEEDED",
    ended_at: ago(1100),
    exit_code: 0,
  }),
];
const overview: Overview = {
  next_cursor: 10,
  server_time: ago(0),
  runs,
  machines: [
    {
      id: "mac",
      display_name: "Build Mac",
      platform: "macOS",
      architecture: "arm64",
      cli_version: "0.1.4",
      last_seen_at: ago(5),
      paired_at: ago(180000),
    },
    {
      id: "gpu",
      display_name: "Studio GPU",
      platform: "Linux",
      architecture: "x86_64",
      cli_version: "0.1.4",
      last_seen_at: ago(8),
      paired_at: ago(190000),
    },
  ],
  notifications: [
    {
      id: "msg1",
      machine_id: "mac",
      run_id: runs[3].id,
      title: "Integration tests passed",
      subtitle: "RunBuoy API",
      body: "All API checks completed successfully.",
      level: "success",
      fields: [
        { label: "Tests", value: "142 passed" },
        { label: "Duration", value: "2m 38s" },
      ],
      created_at: ago(1100),
    },
  ],
  history_runs_next_cursor: null,
  history_runs_has_more: false,
  history_notifications_next_cursor: null,
  history_notifications_has_more: false,
};
export function createDemoBridge(
  onResult: (e: Envelope) => void,
  onContext: (c: BridgeState) => void,
): Bridge {
  const params = new URLSearchParams(location.search);
  if (params.has("empty")) {
    overview.runs = [];
    overview.machines = [];
    overview.notifications = [];
  }
  setTimeout(() => {
    onContext({
      displayMode: params.get("mode") === "inline" ? "inline" : "fullscreen",
      locale: params.get("lang") === "zh" ? "zh-CN" : "en-US",
      theme: params.get("theme") || "light",
    });
    onResult({ data: { overview } });
  }, 30);
  return {
    call: async (name, args = {}) => {
      if (name === "get_overview") return { data: { not_modified: true } };
      if (name === "get_run") {
        const r = runs.find((r) => r.id === args.run_id)!;
        return {
          data: {
            run: r,
            events: {
              items: [
                {
                  event_id: "1",
                  seq: 1,
                  type: "run.started",
                  occurred_at: r.started_at!,
                  payload: {},
                },
                {
                  event_id: "24",
                  seq: 24,
                  type: "run.progress",
                  occurred_at: r.updated_at,
                  payload: {
                    message: r.safe_message || "Work in progress",
                    phase: r.phase || "",
                  },
                },
              ],
              before_seq: 1,
              after_seq: 24,
              has_more: false,
              sequence: 24,
            },
          },
        };
      }
      if (name === "list_history") {
        const items =
          args.kind === "runs"
            ? runs.filter((r) => r.execution_status === "SUCCEEDED")
            : overview.notifications;
        return {
          data: {
            history: {
              kind: args.kind as "runs" | "messages",
              items: items.filter(
                (i) => !args.machine_id || i.machine_id === args.machine_id,
              ),
              next_cursor: null,
              has_more: false,
            },
          },
        };
      }
      return { data: {} };
    },
    expand: async () => onContext({ displayMode: "fullscreen" }),
    context: async () => {},
    close: () => {},
  };
}
