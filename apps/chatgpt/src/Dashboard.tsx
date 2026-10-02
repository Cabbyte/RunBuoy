import { useCallback, useEffect, useRef, useState } from "react";
import {
  connectBridge,
  ConnectionError,
  type Bridge,
  type BridgeState,
  type Envelope,
} from "./bridge";
import {
  active,
  cadence,
  confirmedDuration,
  fraction,
  isStale,
  needsAttention,
  relativeTime,
  mergeEvents,
  mergeOverview,
  orderedRuns,
  status,
  terminal,
  type Detail,
  type EventPage,
  type HistoryPage,
  type Message,
  type Overview,
  type Run,
  type View,
} from "./model";
import { translator, type Language } from "./i18n";
import iconLight from "./assets/runbuoy-icon-light.png";
import iconDark from "./assets/runbuoy-icon-dark.png";

export function Dashboard() {
  const [overview, setOverview] = useState<Overview | null>(null);
  const latest = useRef<Overview | null>(null);
  const [bridge, setBridge] = useState<Bridge | null>(null);
  const bridgeRef = useRef<Bridge | null>(null);
  const [view, setView] = useState<View>("active");
  const [machine, setMachine] = useState("");
  const [selected, setSelected] = useState<string | null>(null);
  const [wide, setWide] = useState(false);
  const [selectionDismissed, setSelectionDismissed] = useState(false);
  const [showAllEvents, setShowAllEvents] = useState(false);
  const [detail, setDetail] = useState<Detail | null>(null);
  const [history, setHistory] = useState<HistoryPage | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [detailError, setDetailError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [pageBusy, setPageBusy] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const [hostMode, setHostMode] = useState("inline");
  const [language, setLanguage] = useState<Language>("en");
  const languagePreference = useRef<Language | null>(null);
  const [demo, setDemo] = useState(false);
  const [checked, setChecked] = useState<Date | null>(null);
  const [now, setNow] = useState(Date.now());
  const [copied, setCopied] = useState(false);
  const [contextSet, setContextSet] = useState(false);
  const failures = useRef(0);
  const refreshing = useRef(false);
  const authLost = useRef(false);
  const historyGeneration = useRef(0);
  const detailGeneration = useRef(0);
  const t = translator(language);
  const locale = language === "zh" ? "zh-CN" : "en-US";
  const isFull = expanded || hostMode === "fullscreen";
  const date = (value?: string | null) =>
    value
      ? new Date(value).toLocaleString(locale, {
          year: "numeric",
          month: "short",
          day: "numeric",
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
        })
      : "—";
  const relative = (value: string) => relativeTime(value, now, locale);

  useEffect(() => {
    const viewport = window.matchMedia("(min-width: 1100px)");
    const update = () => setWide(viewport.matches);
    update();
    viewport.addEventListener("change", update);
    return () => viewport.removeEventListener("change", update);
  }, []);

  useEffect(() => {
    setShowAllEvents(false);
    setCopied(false);
    setContextSet(false);
  }, [selected]);

  const apply = useCallback((result: Envelope) => {
    if (authLost.current) return;
    if (result.data.overview) {
      const merged = mergeOverview(latest.current, result.data.overview);
      latest.current = merged;
      setOverview(merged);
      authLost.current = false;
    }
    if (result.initialView) setView(result.initialView);
    if (result.initialRunID) {
      setSelected(result.initialRunID);
      setExpanded(true);
    }
    setChecked(new Date());
    setError(null);
    failures.current = 0;
  }, []);

  const handleError = useCallback((e: unknown) => {
    if (
      (e instanceof ConnectionError && e.auth) ||
      (e instanceof Error && /\b401\b|revoked|unauthorized/i.test(e.message))
    ) {
      authLost.current = true;
      detailGeneration.current++;
      historyGeneration.current++;
      latest.current = null;
      setOverview(null);
      setDetail(null);
      setHistory(null);
      setSelected(null);
      setError("revoked");
    } else setError(e instanceof Error ? e.message : "RunBuoy request failed");
    failures.current += 1;
  }, []);

  useEffect(() => {
    let alive = true;
    const host = (ctx: BridgeState) => {
      if (!alive) return;
      if (ctx.theme) document.documentElement.dataset.theme = ctx.theme;
      // Host updates include locale when the display mode changes, too.
      if (ctx.locale && languagePreference.current === null)
        setLanguage(ctx.locale.toLowerCase().startsWith("zh") ? "zh" : "en");
      if (ctx.displayMode) setHostMode(ctx.displayMode);
    };
    const init = async () => {
      try {
        let connected: Bridge;
        if (
          import.meta.env.DEV &&
          new URLSearchParams(location.search).has("demo")
        ) {
          const { createDemoBridge } = await import("./demo");
          setDemo(true);
          connected = createDemoBridge(
            (result) => alive && apply(result),
            host,
          );
        } else {
          if (window.parent === window) {
            setError("waiting");
            return;
          }
          connected = await connectBridge(
            (result) => {
              if (alive) apply(result);
            },
            host,
            handleError,
          );
        }
        if (!alive) {
          connected.close();
          return;
        }
        bridgeRef.current = connected;
        setBridge(connected);
      } catch (e) {
        if (alive) handleError(e);
      }
    };
    void init();
    return () => {
      alive = false;
      bridgeRef.current?.close();
    };
  }, [apply, handleError]);

  const refresh = useCallback(async () => {
    if (!bridgeRef.current || refreshing.current || authLost.current) return;
    refreshing.current = true;
    setBusy(true);
    try {
      apply(
        await bridgeRef.current.call(
          "get_overview",
          latest.current ? { cursor: latest.current.next_cursor } : {},
        ),
      );
    } catch (e) {
      handleError(e);
    } finally {
      refreshing.current = false;
      setBusy(false);
    }
  }, [apply, handleError]);

  useEffect(() => {
    if (!bridge) return;
    let timeout: ReturnType<typeof setTimeout>;
    let stopped = false;
    let inViewport = true;
    const schedule = () => {
      clearTimeout(timeout);
      if (stopped || document.hidden || !inViewport || authLost.current) return;
      timeout = setTimeout(
        async () => {
          await refresh();
          schedule();
        },
        cadence(!!latest.current?.runs.some(active), failures.current),
      );
    };
    const visible = () => {
      clearTimeout(timeout);
      if (!document.hidden && inViewport && !stopped)
        void refresh().then(schedule);
    };
    schedule();
    document.addEventListener("visibilitychange", visible);
    // Also pause an iframe hidden by the host while its document remains visible.
    const observer = new IntersectionObserver((entries) => {
      const next = entries[0]?.isIntersecting ?? true;
      if (next !== inViewport) {
        inViewport = next;
        visible();
      }
    });
    observer.observe(document.documentElement);
    const ticker = setInterval(() => {
      if (!document.hidden) setNow(Date.now());
    }, 30_000);
    return () => {
      stopped = true;
      observer.disconnect();
      clearTimeout(timeout);
      clearInterval(ticker);
      document.removeEventListener("visibilitychange", visible);
    };
  }, [bridge, refresh]);

  useEffect(() => {
    if (!bridge || !selected) {
      setDetail(null);
      return;
    }
    const generation = ++detailGeneration.current;
    setDetailError(null);
    void bridge
      .call("get_run", { run_id: selected })
      .then((result) => {
        if (
          authLost.current ||
          generation !== detailGeneration.current ||
          !result.data.run ||
          !result.data.events
        )
          return;
        const canonical = latest.current?.runs.find((r) => r.id === selected);
        const run =
          canonical && canonical.sequence > result.data.run.sequence
            ? canonical
            : result.data.run;
        setDetail({ run, events: result.data.events! });
      })
      .catch((e) => {
        if (generation === detailGeneration.current) {
          setDetailError(e instanceof Error ? e.message : "Request failed");
          handleError(e);
        }
      });
    return () => {
      detailGeneration.current++;
    };
  }, [bridge, selected, overview?.next_cursor, handleError]);

  useEffect(() => {
    setHistory(null);
    setPageBusy(false);
    const generation = ++historyGeneration.current;
    if (!bridge || !["history", "messages"].includes(view)) return;
    setPageBusy(true);
    void bridge
      .call("list_history", {
        kind: view === "history" ? "runs" : "messages",
        machine_id: machine || null,
        limit: 50,
      })
      .then((result) => {
        if (
          !authLost.current &&
          generation === historyGeneration.current &&
          result.data.history
        )
          setHistory(result.data.history);
      })
      .catch(handleError)
      .finally(() => {
        if (generation === historyGeneration.current) setPageBusy(false);
      });
    return () => {
      historyGeneration.current++;
    };
  }, [bridge, view, machine, overview?.next_cursor, handleError]);

  const openRun = (id: string) => {
    if (id === selected) return;
    setSelected(id);
    setDetail(null);
    setDetailError(null);
    setExpanded(true);
    setCopied(false);
    setContextSet(false);
    if (!isFull)
      void bridge?.expand().catch(() => {
        /* The full responsive view also fits the current host. */
      });
  };
  const loadMore = async () => {
    if (!bridge || !history?.next_cursor || pageBusy) return;
    const generation = historyGeneration.current;
    setPageBusy(true);
    try {
      const result = await bridge.call("list_history", {
        kind: history.kind,
        cursor: history.next_cursor,
        machine_id: machine || null,
        limit: 50,
      });
      if (
        !authLost.current &&
        generation === historyGeneration.current &&
        result.data.history
      ) {
        const page = result.data.history;
        setHistory((old) =>
          old
            ? {
                ...page,
                items: [
                  ...new Map(
                    [...old.items, ...page.items].map((item) => [
                      item.id,
                      item,
                    ]),
                  ).values(),
                ],
              }
            : page,
        );
      }
    } catch (e) {
      handleError(e);
    } finally {
      if (generation === historyGeneration.current) setPageBusy(false);
    }
  };
  const loadEvents = async () => {
    if (!bridge || !detail || pageBusy) return;
    const id = detail.run.id,
      generation = detailGeneration.current;
    setPageBusy(true);
    try {
      const result = await bridge.call("get_run_events", {
        run_id: id,
        before_seq: detail.events.before_seq,
      });
      if (generation === detailGeneration.current && result.data.events) {
        const page = result.data.events;
        setDetail((old) =>
          old && old.run.id === id
            ? {
                ...old,
                events: {
                  ...page,
                  after_seq: old.events.after_seq,
                  items: mergeEvents(old.events.items, page.items),
                },
              }
            : old,
        );
      }
    } catch (e) {
      setDetailError(e instanceof Error ? e.message : "Request failed");
      handleError(e);
    } finally {
      setPageBusy(false);
    }
  };

  const runList = overview?.runs || [];
  const activeRuns = orderedRuns(
    runList.filter(active).filter((r) => !machine || r.machine_id === machine),
    now,
  );
  const attention = activeRuns.filter((r) => needsAttention(r, now)).length;
  const firstActiveID = activeRuns[0]?.id;
  useEffect(() => {
    if (
      wide &&
      isFull &&
      view === "active" &&
      !selectionDismissed &&
      !selected &&
      firstActiveID
    )
      setSelected(firstActiveID);
  }, [wide, isFull, view, selectionDismissed, selected, firstActiveID]);
  const chosen =
    detail?.run.id === selected
      ? detail.run
      : runList.find((r) => r.id === selected);
  const filteredHistory =
    history?.kind === "runs"
      ? (history.items as Run[])
      : runList.filter(
          (r) =>
            terminal.has(r.execution_status) &&
            (!machine || r.machine_id === machine),
        );
  const messageList = (
    history?.kind === "messages"
      ? (history.items as Message[])
      : overview?.notifications || []
  ).filter(
    (m) =>
      (!machine || m.machine_id === machine) &&
      (!m.expires_at || Date.parse(m.expires_at) > now),
  );
  const filteredMachines = (overview?.machines || []).filter(
    (m) => !machine || m.id === machine,
  );
  const count =
    view === "active"
      ? activeRuns.length
      : view === "history"
        ? filteredHistory.length
        : view === "messages"
          ? messageList.length
          : filteredMachines.length;
  const machineName = (id?: string | null) =>
    overview?.machines.find((m) => m.id === id)?.display_name || id || "";

  const badge = (r: Run) => (
    <span className={`badge ${status(r).tone}`}>
      <span className="dot" />
      {t(status(r).key)}
    </span>
  );
  const progress = (r: Run) => {
    const value = fraction(r.progress);
    if (value === null)
      return (
        <div className="progress-block unknown-progress">
          {r.phase && <span>{r.phase}</span>}
          <span>{t("unknownProgress")}</span>
        </div>
      );
    return (
      <div className="progress-block">
        <div className="progress-label">
          <span>{r.phase || t("progress")}</span>
          <strong>
            {new Intl.NumberFormat(locale, {
              style: "percent",
              maximumFractionDigits: 0,
            }).format(value)}
          </strong>
        </div>
        <progress max="1" value={value} aria-label={t("progress")} />
        <div className="muted micro">
          {r.progress?.current?.toLocaleString(locale)} /{" "}
          {r.progress?.total?.toLocaleString(locale)} {r.progress?.unit || ""}
        </div>
      </div>
    );
  };
  const duration = (r: Run) => {
    const value = confirmedDuration(r);
    if (value === null) return "—";
    const mins = Math.floor(value / 60_000);
    return mins >= 60
      ? `${Math.floor(mins / 60)}h ${mins % 60}m`
      : `${mins}m ${Math.floor(value / 1000) % 60}s`;
  };
  const row = (r: Run, hero = false) => (
    <button
      key={r.id}
      className={`run-card ${hero ? "hero" : ""} ${selected === r.id ? "selected" : ""}`}
      onClick={() => openRun(r.id)}
      aria-label={`${r.title}, ${t(status(r).key)}${isStale(r, now) ? `, ${t("staleShort")}` : ""}`}
      aria-pressed={selected === r.id}
    >
      <div className="row run-heading">
        <h3>{r.title}</h3>
        {badge(r)}
      </div>
      <span className="machine-label">
        <Computer />
        {r.machine_name}
      </span>
      {progress(r)}
      <div className="row foot">
        <span className={isStale(r, now) ? "freshness-overdue" : ""}>
          {isStale(r, now) ? t("staleShort") : t("confirmed")} ·{" "}
          <time dateTime={r.updated_at} title={date(r.updated_at)}>
            {relative(r.updated_at)}
          </time>
        </span>
        <span>
          {r.started_at && duration(r)} <span aria-hidden="true">↗</span>
        </span>
      </div>
    </button>
  );

  const machineFilter = isFull && overview && (
    <select
      aria-label={t("filter")}
      value={machine}
      onChange={(e) => {
        setMachine(e.target.value);
        setSelectionDismissed(false);
        setSelected(null);
      }}
    >
      <option value="">{t("all")}</option>
      {overview.machines.map((m) => (
        <option key={m.id} value={m.id}>
          {m.display_name}
        </option>
      ))}
    </select>
  );

  const detailView = chosen && (
    <section className="detail-panel" aria-label={t("detail")}>
      <div className="row">
        <span className="eyebrow">{t("detail")}</span>
        <button
          className="icon-button"
          aria-label={t("close")}
          onClick={() => {
            setSelectionDismissed(true);
            setSelected(null);
          }}
        >
          ×
        </button>
      </div>
      <div className="detail-heading">
        {badge(chosen)}
        <h2>{chosen.title}</h2>
        <span className="machine-label">
          <Computer />
          {chosen.machine_name}
        </span>
      </div>
      {(detailError || isStale(chosen, now)) && (
        <div className="notice" role="status">
          {detailError ||
            `${t("staleShort")} · ${relative(chosen.updated_at)} · ${t("staleStatus")}`}
        </div>
      )}
      {progress(chosen)}
      {chosen.safe_message && (
        <section className="message-highlight">
          <h4>{t("safeMessage")}</h4>
          <p>{chosen.safe_message}</p>
          <time>
            {t("confirmed")} · {date(chosen.updated_at)}
          </time>
        </section>
      )}
      <dl className="metrics">
        {[
          ...(chosen.started_at
            ? [[t("elapsed"), duration(chosen)]]
            : [[t("created"), date(chosen.created_at)]]),
          [t("confirmed"), date(chosen.updated_at)],
          ...(chosen.started_at
            ? [[t("started"), date(chosen.started_at)]]
            : []),
          ...(chosen.ended_at ? [[t("ended"), date(chosen.ended_at)]] : []),
          ...(chosen.progress?.estimated_end_at
            ? [[t("eta"), date(chosen.progress.estimated_end_at)]]
            : []),
          ...(chosen.exit_code !== null && chosen.exit_code !== undefined
            ? [[t("exit"), String(chosen.exit_code)]]
            : []),
        ].map(([label, value]) => (
          <div key={label}>
            <dt>{label}</dt>
            <dd>{value}</dd>
          </div>
        ))}
      </dl>
      <section className="recent-events" aria-label={t("recentEvents")}>
        <div className="row events-heading">
          <h4>{showAllEvents ? t("timeline") : t("recentEvents")}</h4>
          {detail &&
            (detail.events.items.length > 3 || detail.events.has_more) && (
              <button
                className="text-button"
                onClick={() => setShowAllEvents(!showAllEvents)}
              >
                {showAllEvents ? t("fewerEvents") : t("allEvents")}
              </button>
            )}
        </div>
        {!detail && !detailError && <p className="muted">{t("loading")}</p>}
        {showAllEvents && detail?.events.has_more && (
          <button
            className="secondary"
            disabled={pageBusy}
            onClick={() => void loadEvents()}
          >
            {t("moreEvents")}
          </button>
        )}
        <ol className="timeline">
          {(showAllEvents
            ? detail?.events.items
            : detail?.events.items.slice(-3)
          )
            ?.slice()
            .reverse()
            .map((e) => (
              <li key={e.event_id}>
                <span className="timeline-dot" />
                <div>
                  <strong>
                    {e.type.replace(/^run\./, "").replaceAll("_", " ")}
                  </strong>
                  <time>
                    {date(e.occurred_at)} · #{e.seq}
                  </time>
                  {(e.payload.message || e.payload.safe_message) && (
                    <p>{e.payload.message || e.payload.safe_message}</p>
                  )}
                  {e.payload.phase && <small>{e.payload.phase}</small>}
                  <details>
                    <summary>{t("safeFields")}</summary>
                    <pre>{JSON.stringify(e.payload, null, 2)}</pre>
                  </details>
                </div>
              </li>
            ))}
        </ol>
        {detail && !detail.events.items.length && (
          <p className="muted">{t("noEvents")}</p>
        )}
      </section>
      <details className="shared-logs">
        <summary>{t("logs")}</summary>
        <p className="muted micro">{t("logNote")}</p>
        {chosen.safe_log_tail?.length ? (
          <pre>{chosen.safe_log_tail.join("\n")}</pre>
        ) : (
          <p className="muted">{t("noLogs")}</p>
        )}
      </details>
      <details className="technical">
        <summary>{t("technical")}</summary>
        <dl className="technical-data">
          {[
            [t("created"), date(chosen.created_at)],
            [t("execution"), t(chosen.execution_status)],
            [t("health"), t(chosen.health_status)],
            [t("attention"), t(chosen.attention_status)],
            [t("id"), chosen.id],
            [t("sequence"), String(chosen.sequence)],
            [t("source"), chosen.source || "—"],
            [t("reason"), chosen.termination_reason || "—"],
          ].map(([key, value]) => (
            <div key={key}>
              <dt>{key}</dt>
              <dd>{value}</dd>
            </div>
          ))}
        </dl>
      </details>
      <div className="detail-actions">
        <button
          className="secondary"
          onClick={() => {
            const value = fraction(chosen.progress);
            const summary = [
              chosen.title,
              chosen.machine_name,
              t(status(chosen).key),
              chosen.phase,
              value === null ? undefined : `${Math.round(value * 100)}%`,
              `${t("confirmed")}: ${date(chosen.updated_at)}`,
              chosen.safe_message,
            ]
              .filter(Boolean)
              .join("\n");
            void navigator.clipboard
              .writeText(summary)
              .then(() => setCopied(true))
              .catch((e) => setDetailError(String(e)));
          }}
        >
          {copied ? t("copied") : t("copy")}
        </button>
        <button
          className="primary"
          onClick={() =>
            void bridge
              ?.context(chosen)
              .then(() => setContextSet(true))
              .catch((e) => setDetailError(String(e)))
          }
        >
          {contextSet ? t("contextSet") : t("discuss")}
        </button>
      </div>
    </section>
  );

  return (
    <main
      className={`app ${isFull ? "full" : "compact"} ${error ? "disconnected" : ""}`}
    >
      <header className="app-header">
        <div className="brand">
          <Buoy />
          <div>
            <strong>RunBuoy</strong>
            <span>{demo ? t("demo") : t("readOnly")}</span>
          </div>
        </div>
        <div className="toolbar">
          {checked && isFull && (
            <span className="checked-at" title={checked.toLocaleString(locale)}>
              {t("fetched")} ·{" "}
              {checked.toLocaleTimeString(locale, {
                hour: "2-digit",
                minute: "2-digit",
              })}
            </span>
          )}
          <button
            className="text-button"
            onClick={() => {
              const next = language === "en" ? "zh" : "en";
              languagePreference.current = next;
              setLanguage(next);
            }}
          >
            {language === "en" ? "中文" : "EN"}
          </button>
          <button
            className={`icon-button ${busy ? "busy" : ""}`}
            disabled={busy || !bridge}
            aria-label={t("refresh")}
            onClick={() => void refresh()}
          >
            ↻
          </button>
          {!isFull && (
            <button
              className="secondary"
              onClick={() => {
                setExpanded(true);
                void bridge?.expand().catch(() => {});
              }}
            >
              {t("expand")} <span aria-hidden="true">↗</span>
            </button>
          )}
        </div>
      </header>
      {error && error !== "waiting" && (
        <div role="alert" className="notice">
          {error === "revoked" ? t("revoked") : overview ? t("cached") : error}
          <button className="text-button" onClick={() => void refresh()}>
            {t("retry")}
          </button>
        </div>
      )}
      {!overview ? (
        <div className="empty">
          <Buoy />
          <h2>
            {error
              ? t(error === "waiting" ? "waiting" : "unavailable")
              : t("loading")}
          </h2>
          {error === "revoked" && <p>{t("revoked")}</p>}
        </div>
      ) : (
        <>
          {isFull && (
            <nav aria-label="RunBuoy">
              {(["active", "history", "machines", "messages"] as View[]).map(
                (item) => (
                  <button
                    key={item}
                    aria-current={view === item ? "page" : undefined}
                    onClick={() => {
                      setView(item);
                      setSelectionDismissed(false);
                      setSelected(null);
                      setMachine("");
                    }}
                  >
                    {t(item)}
                    {item === "active" && (
                      <span className="nav-count">
                        {runList.filter(active).length}
                      </span>
                    )}
                  </button>
                ),
              )}
            </nav>
          )}
          {view === "active" && (!selected || wide) && (
            <section className="overview" aria-label={t("overview")}>
              <div>
                <span className="eyebrow">{t("overview")}</span>
                <h1>
                  {language === "zh"
                    ? "运行，一目了然。"
                    : "Every run. In sight."}
                </h1>
              </div>
              <div className="overview-tools">
                <div className="summary-counts">
                  <div>
                    <strong>
                      {activeRuns.length.toString().padStart(2, "0")}
                    </strong>
                    <span>{t("activeCount")}</span>
                  </div>
                  <div
                    className={attention ? "attention" : ""}
                    title={t("attentionHint")}
                  >
                    <strong>{attention.toString().padStart(2, "0")}</strong>
                    <span>{t("attentionCount")}</span>
                  </div>
                </div>
                {machineFilter}
              </div>
            </section>
          )}
          <div className={`workspace ${selected ? "has-selection" : ""}`}>
            <section className="list-panel" aria-label={t(view)}>
              {view !== "active" && (
                <div className="section-heading">
                  <h2>
                    {t(view)} <span className="muted">{count}</span>
                  </h2>
                  {machineFilter}
                </div>
              )}
              {view === "active" && (
                <div className="run-list">
                  {(isFull ? activeRuns : activeRuns.slice(0, 3)).map((r, i) =>
                    row(r, i === 0 && !selected),
                  )}
                  {!activeRuns.length && (
                    <Empty title={t("empty")} message={t("emptyActive")} />
                  )}
                  {!isFull && activeRuns.length > 3 && (
                    <button
                      className="secondary"
                      onClick={() => {
                        setExpanded(true);
                        void bridge?.expand().catch(() => {});
                      }}
                    >
                      {t("expand")} · {activeRuns.length}
                    </button>
                  )}
                </div>
              )}
              {view === "history" && (
                <div className="run-list">
                  {filteredHistory.map((r) => row(r))}
                  {!filteredHistory.length && !pageBusy && (
                    <Empty message={t("emptyHistory")} />
                  )}
                </div>
              )}
              {view === "machines" && (
                <div className="machine-grid">
                  {filteredMachines.map((m) => (
                    <article key={m.id} className="machine-card">
                      <div className="row">
                        <Computer />
                        <span className="muted micro">
                          {m.platform || t("optional")}
                        </span>
                      </div>
                      <h3>{m.display_name}</h3>
                      <dl className="technical-data">
                        {[
                          [t("architecture"), m.architecture || "—"],
                          [t("version"), m.cli_version || "—"],
                          [t("lastSeen"), date(m.last_seen_at)],
                          [t("paired"), date(m.paired_at)],
                        ].map(([key, val]) => (
                          <div key={key}>
                            <dt>{key}</dt>
                            <dd>{val}</dd>
                          </div>
                        ))}
                      </dl>
                      <div className="machine-runs">
                        {runList
                          .filter((r) => r.machine_id === m.id)
                          .slice(0, 5)
                          .map((r) => (
                            <button
                              className="machine-run"
                              key={r.id}
                              onClick={() => openRun(r.id)}
                            >
                              <span>{r.title}</span>
                              {badge(r)}
                            </button>
                          ))}
                        <button
                          className="text-button"
                          onClick={() => {
                            setView("history");
                            setMachine(m.id);
                          }}
                        >
                          {t("history")} →
                        </button>
                      </div>
                    </article>
                  ))}
                  {!filteredMachines.length && (
                    <Empty message={t("emptyMachines")} />
                  )}
                </div>
              )}
              {view === "messages" && (
                <div className="message-list">
                  {messageList.map((m) => (
                    <article className="message-card" key={m.id}>
                      <div className="row">
                        <span
                          className={`badge ${m.level === "error" ? "critical" : m.level === "success" ? "success" : m.level === "warning" ? "warning" : "neutral"}`}
                        >
                          {m.level}
                        </span>
                        <time className="micro muted">
                          {date(m.created_at)}
                        </time>
                      </div>
                      <h3>{m.title}</h3>
                      {m.subtitle && <h4>{m.subtitle}</h4>}
                      <p>{m.body}</p>
                      {m.fields && (
                        <dl className="technical-data">
                          {m.fields.map(({ label: key, value }, index) => (
                            <div key={`${key}-${index}`}>
                              <dt>{key}</dt>
                              <dd>
                                {typeof value === "string"
                                  ? value
                                  : JSON.stringify(value)}
                              </dd>
                            </div>
                          ))}
                        </dl>
                      )}
                      <div className="row foot">
                        <span>{machineName(m.machine_id)}</span>
                        {m.run_id && (
                          <button
                            className="text-button"
                            onClick={() => openRun(m.run_id!)}
                          >
                            {t("openRun")} →
                          </button>
                        )}
                      </div>
                    </article>
                  ))}
                  {!messageList.length && !pageBusy && (
                    <Empty message={t("emptyMessages")} />
                  )}
                </div>
              )}
              {["history", "messages"].includes(view) &&
                (history?.has_more || pageBusy) && (
                  <button
                    className="load-more secondary"
                    disabled={pageBusy}
                    onClick={() => void loadMore()}
                  >
                    {pageBusy ? t("loading") : t("more")}
                  </button>
                )}
            </section>
            {selected &&
              (detailView || (
                <section className="detail-panel">
                  <button
                    className="text-button"
                    onClick={() => {
                      setSelectionDismissed(true);
                      setSelected(null);
                    }}
                  >
                    {t("back")}
                  </button>
                  <p>{detailError || t("loading")}</p>
                </section>
              ))}
          </div>
          <footer>
            <span>
              <span className="connection-dot" />
              {t("readOnly")}
            </span>
            <span>
              {checked &&
                `${t("fetched")} · ${checked.toLocaleTimeString(locale, { hour: "2-digit", minute: "2-digit" })}`}
            </span>
          </footer>
          {isFull && (
            <p className="retention">
              {t("retained")} {t("systemNative")}
            </p>
          )}
        </>
      )}
    </main>
  );
}
function Empty({ title, message }: { title?: string; message: string }) {
  return (
    <div className="empty">
      <span className="empty-symbol" aria-hidden="true">
        ✓
      </span>
      {title && <h3>{title}</h3>}
      <p>{message}</p>
    </div>
  );
}
function Computer() {
  return (
    <svg
      className="computer"
      width="18"
      height="18"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      aria-hidden="true"
    >
      <rect x="3" y="4" width="18" height="13" rx="2" />
      <path d="M8 21h8M12 17v4" />
    </svg>
  );
}
function Buoy() {
  return (
    <div className="buoy" aria-hidden="true">
      <img
        className="brand-icon-light"
        src={iconLight}
        alt=""
        width="36"
        height="36"
      />
      <img
        className="brand-icon-dark"
        src={iconDark}
        alt=""
        width="36"
        height="36"
      />
    </div>
  );
}
