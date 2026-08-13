import XCTest
@testable import RunBuoyApp

final class RunStatusVisualStateTests: XCTestCase {
    func testTerminalStatusWinsEveryCompetingSignal() {
        let state = RunStatusVisualState.resolve(
            executionStatus: "FAILED",
            healthStatus: "OFFLINE",
            attentionStatus: "ACTION_REQUIRED",
            isStale: true
        )

        XCTAssertEqual(state.category, .failed)
        XCTAssertEqual(state.tone, .critical)
        XCTAssertEqual(state.priority, .terminal)
        XCTAssertTrue(state.isTerminal)
        XCTAssertFalse(state.allowsLiveEmphasis)
    }

    func testStaleThenActionThenWarningPrecedence() {
        let stale = RunStatusVisualState.resolve(
            executionStatus: "RUNNING",
            healthStatus: "HEALTHY",
            attentionStatus: "ACTION_REQUIRED",
            isStale: true
        )
        let action = RunStatusVisualState.resolve(
            executionStatus: "RUNNING",
            healthStatus: "HEALTHY",
            attentionStatus: "ACTION_REQUIRED"
        )
        let warning = RunStatusVisualState.resolve(
            executionStatus: "RUNNING",
            healthStatus: "HEALTHY",
            attentionStatus: "WARNING"
        )

        XCTAssertEqual(stale.category, .stale)
        XCTAssertEqual(action.category, .actionRequired)
        XCTAssertEqual(warning.category, .warning)
        XCTAssertGreaterThan(stale.priority, action.priority)
        XCTAssertGreaterThan(action.priority, warning.priority)
    }

    func testHealthyRunningIsTheOnlyLiveEmphasisState() {
        let running = RunStatusVisualState.resolve(
            executionStatus: "RUNNING",
            healthStatus: "HEALTHY",
            attentionStatus: "NONE"
        )
        let starting = RunStatusVisualState.execution("STARTING")
        let cancelled = RunStatusVisualState.execution("CANCELLED")

        XCTAssertEqual(running.symbol, "waveform.path.ecg")
        XCTAssertEqual(running.tone, .live)
        XCTAssertTrue(running.allowsLiveEmphasis)
        XCTAssertFalse(starting.allowsLiveEmphasis)
        XCTAssertEqual(cancelled.tone, .neutral)
        XCTAssertTrue(cancelled.isTerminal)
        XCTAssertFalse(cancelled.allowsLiveEmphasis)
    }

    func testTrustedProgressRequiresFiniteCurrentAndTotal() {
        XCTAssertNil(TrustedRunProgress(
            kind: "determinate", current: nil, total: 10, fraction: 0.5
        ))
        XCTAssertNil(TrustedRunProgress(
            kind: "determinate", current: 5, total: 0, fraction: 0.5
        ))
        XCTAssertNil(TrustedRunProgress(
            kind: "indeterminate", current: 5, total: 10, fraction: 0.5
        ))
        XCTAssertNil(TrustedRunProgress(
            kind: "determinate", current: .infinity, total: 10, fraction: 0.5
        ))
    }

    func testTrustedProgressDerivesAndBoundsFraction() throws {
        let derived = try XCTUnwrap(TrustedRunProgress(
            kind: "determinate", current: 3, total: 4, fraction: nil, unit: "tasks"
        ))
        let bounded = try XCTUnwrap(TrustedRunProgress(
            kind: "determinate", current: 12, total: 10, fraction: 1.2
        ))

        XCTAssertEqual(derived.fraction, 0.75, accuracy: 0.0001)
        XCTAssertEqual(derived.unit, "tasks")
        XCTAssertEqual(bounded.fraction, 1)
    }

    func testOnlyNonTerminalProgressStatesCanRenderRing() {
        XCTAssertTrue(RunStatusVisualCategory.running.canShowProgressRing)
        XCTAssertTrue(RunStatusVisualCategory.warning.canShowProgressRing)
        XCTAssertFalse(RunStatusVisualCategory.stale.canShowProgressRing)
        XCTAssertFalse(RunStatusVisualCategory.cancelled.canShowProgressRing)
    }
}
