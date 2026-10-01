import XCTest
@testable import RunBuoyApp

final class RunVisualStateTests: XCTestCase {
    func testTerminalOutcomeOverridesConnectivityAndAttention() {
        let state = RunStatusVisualState.resolve(
            executionStatus: "FAILED",
            healthStatus: "OFFLINE",
            attentionStatus: "ACTION_REQUIRED",
            isStale: true
        )

        XCTAssertEqual(state.kind, .failed)
        XCTAssertEqual(state.tone, .critical)
        XCTAssertEqual(state.priority, .terminal)
        XCTAssertTrue(state.isTerminal)
        XCTAssertFalse(state.allowsLiveEmphasis)
    }

    func testConnectivityOverridesAttentionOnlyForActiveRuns() {
        let active = RunStatusVisualState.resolve(
            executionStatus: "RUNNING",
            healthStatus: "OFFLINE",
            attentionStatus: "ACTION_REQUIRED"
        )
        let unknown = RunStatusVisualState.resolve(
            executionStatus: "UNKNOWN",
            healthStatus: "OFFLINE",
            attentionStatus: "ACTION_REQUIRED"
        )

        XCTAssertEqual(active.kind, .offline)
        XCTAssertEqual(active.priority, .connectivity)
        XCTAssertFalse(active.allowsLiveEmphasis)
        XCTAssertEqual(unknown.kind, .actionRequired)
        XCTAssertEqual(unknown.priority, .actionRequired)
    }

    func testAttentionPriorityAndTone() {
        let action = status(attention: "ACTION_REQUIRED")
        let warning = status(attention: "WARNING")
        let information = status(attention: "INFORMATION")

        XCTAssertEqual(action.tone, .critical)
        XCTAssertEqual(action.priority, .actionRequired)
        XCTAssertEqual(warning.tone, .warning)
        XCTAssertEqual(warning.priority, .warning)
        XCTAssertEqual(information.tone, .neutral)
        XCTAssertEqual(information.priority, .information)
        XCTAssertFalse(action.allowsLiveEmphasis)
        XCTAssertFalse(warning.allowsLiveEmphasis)
    }

    func testUnknownStatusIsNeutralAndNotLive() {
        let state = RunStatusVisualState.resolve(
            executionStatus: "FUTURE_STATUS",
            healthStatus: "FUTURE_HEALTH",
            attentionStatus: "FUTURE_ATTENTION"
        )

        XCTAssertEqual(state.kind, .unknown)
        XCTAssertEqual(state.tone, .neutral)
        XCTAssertEqual(state.priority, .unknown)
        XCTAssertFalse(state.isActive)
        XCTAssertFalse(state.allowsLiveEmphasis)
    }

    func testAppAndWidgetEntryPointsResolveIdentically() {
        let appState = RunStatusVisualState.resolve(
            executionStatus: ExecutionStatus.running.rawValue,
            healthStatus: HealthStatus.stale.rawValue,
            attentionStatus: AttentionStatus.warning.rawValue
        )
        let widgetState = contentState(
            execution: "RUNNING",
            health: "STALE",
            attention: "WARNING"
        ).statusVisualState()

        XCTAssertEqual(appState, widgetState)
    }

    func testTrustedDeterminateProgressRequiresAllFiniteFieldsAndClampsFraction() {
        let live = status()
        let high = progress(
            current: 140,
            total: 100,
            fraction: 1.4,
            status: live
        )
        let low = progress(
            current: 1,
            total: 100,
            fraction: -0.2,
            status: live
        )

        XCTAssertEqual(high.kind, .determinate)
        XCTAssertEqual(high.fraction, 1)
        XCTAssertEqual(low.fraction, 0)
        XCTAssertTrue(high.allowsLiveMotion)
        XCTAssertTrue(high.allowsGlow)
    }

    func testInvalidDeterminateProgressBecomesActiveIndeterminateOrUnavailable() {
        let active = status()
        let terminal = RunStatusVisualState.resolve(
            executionStatus: "SUCCEEDED",
            healthStatus: "HEALTHY",
            attentionStatus: "NONE"
        )
        let invalidInputs: [(Double?, Double?, Double?)] = [
            (nil, 100, 0.5),
            (50, nil, 0.5),
            (50, 100, nil),
            (-1, 100, 0.5),
            (50, 0, 0.5),
            (.infinity, 100, 0.5),
            (50, .nan, 0.5),
            (50, 100, .infinity)
        ]

        for (current, total, fraction) in invalidInputs {
            XCTAssertEqual(
                progress(current: current, total: total, fraction: fraction, status: active).kind,
                .indeterminate
            )
            XCTAssertEqual(
                progress(current: current, total: total, fraction: fraction, status: terminal).kind,
                .unavailable
            )
        }
    }

    func testOfflineAndTerminalProgressNeverAllowsLiveMotionOrGlow() {
        let offline = RunStatusVisualState.resolve(
            executionStatus: "RUNNING",
            healthStatus: "OFFLINE",
            attentionStatus: "NONE"
        )
        let cancelled = RunStatusVisualState.resolve(
            executionStatus: "CANCELLED",
            healthStatus: "HEALTHY",
            attentionStatus: "NONE"
        )
        let offlineProgress = progress(status: offline)
        let cancelledProgress = progress(status: cancelled)

        XCTAssertEqual(cancelled.kind, .cancelled)
        XCTAssertTrue(cancelled.isTerminal)
        XCTAssertFalse(cancelled.allowsLiveEmphasis)
        XCTAssertFalse(offlineProgress.allowsLiveMotion)
        XCTAssertFalse(offlineProgress.allowsGlow)
        XCTAssertFalse(cancelledProgress.allowsLiveMotion)
        XCTAssertFalse(cancelledProgress.allowsGlow)
    }

    private func status(attention: String = "NONE") -> RunStatusVisualState {
        RunStatusVisualState.resolve(
            executionStatus: "RUNNING",
            healthStatus: "HEALTHY",
            attentionStatus: attention
        )
    }

    private func progress(
        current: Double? = 72,
        total: Double? = 100,
        fraction: Double? = 0.72,
        status: RunStatusVisualState
    ) -> RunProgressVisualState {
        RunProgressVisualState.resolve(
            progressKind: "determinate",
            current: current,
            total: total,
            fraction: fraction,
            status: status
        )
    }

    private func contentState(
        execution: String,
        health: String,
        attention: String
    ) -> RunActivityAttributes.ContentState {
        RunActivityAttributes.ContentState(
            sequence: 1,
            executionStatus: execution,
            healthStatus: health,
            attentionStatus: attention,
            progressKind: "determinate",
            progress: 0.72,
            current: 72,
            total: 100,
            phase: "Testing",
            message: nil,
            startedAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 1),
            estimatedEndAt: nil,
            exitCode: nil
        )
    }
}
