import XCTest
@testable import RunBuoyApp

@MainActor
final class UITestScenarioTests: XCTestCase {
    func testPreviewScenariosSeedDeterministicStates() {
        let loaded = PreviewFixtures.store(scenario: .loaded)
        XCTAssertEqual(loaded.state, .loaded)
        XCTAssertEqual(loaded.runs.map(\.id), [
            PreviewFixtures.activeRun.id,
            PreviewFixtures.failedRun.id
        ])

        let empty = PreviewFixtures.store(scenario: .empty)
        XCTAssertEqual(empty.state, .loaded)
        XCTAssertTrue(empty.runs.isEmpty)
        XCTAssertTrue(empty.machines.isEmpty)
        XCTAssertTrue(empty.messages.isEmpty)

        let offline = PreviewFixtures.store(scenario: .offline)
        XCTAssertEqual(offline.state, .offline("UI test offline fixture"))
        XCTAssertFalse(offline.runs.isEmpty)

        let failed = PreviewFixtures.store(scenario: .failed)
        XCTAssertEqual(failed.state, .failed("UI test failure fixture"))
        XCTAssertTrue(failed.runs.isEmpty)

        let priority = PreviewFixtures.store(scenario: .heroPriority)
        XCTAssertEqual(priority.activeRunModels.count, 3)
        XCTAssertEqual(
            ActiveRunsPresentation.ordered(priority.activeRunModels).first?.id,
            PreviewFixtures.heroActionRequiredRun.id
        )

        let unavailable = PreviewFixtures.store(scenario: .detailUnavailable)
        XCTAssertEqual(unavailable.state, .failed("UI test detail unavailable fixture"))
        XCTAssertTrue(unavailable.runs.isEmpty)
    }

    func testActiveHeroOrderingPrioritizesSemanticsThenRecencyAndStableID() {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let actionRequired = makeActiveRun(
            id: "00000000-0000-0000-0000-000000000005",
            updatedAt: baseDate,
            attention: .actionRequired
        )
        let warning = makeActiveRun(
            id: "00000000-0000-0000-0000-000000000004",
            updatedAt: baseDate.addingTimeInterval(300),
            attention: .warning
        )
        let unhealthy = makeActiveRun(
            id: "00000000-0000-0000-0000-000000000003",
            updatedAt: baseDate.addingTimeInterval(600),
            health: .offline
        )
        let stableIDFirst = makeActiveRun(
            id: "00000000-0000-0000-0000-000000000001",
            updatedAt: baseDate.addingTimeInterval(900)
        )
        let stableIDSecond = makeActiveRun(
            id: "00000000-0000-0000-0000-000000000002",
            updatedAt: baseDate.addingTimeInterval(900)
        )
        let olderActive = makeActiveRun(
            id: "00000000-0000-0000-0000-000000000006",
            updatedAt: baseDate.addingTimeInterval(800)
        )

        let ordered = ActiveRunsPresentation.orderedSnapshots([
            stableIDSecond,
            olderActive,
            warning,
            stableIDFirst,
            actionRequired,
            unhealthy
        ])

        XCTAssertEqual(ordered.map(\.id), [
            actionRequired.id,
            warning.id,
            unhealthy.id,
            stableIDFirst.id,
            stableIDSecond.id,
            olderActive.id
        ])
    }

    func testActiveSummaryCountsAttentionAndUsesNewestConfirmation() throws {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let healthy = makeActiveRun(
            id: "00000000-0000-0000-0000-000000000001",
            updatedAt: baseDate
        )
        let stale = makeActiveRun(
            id: "00000000-0000-0000-0000-000000000002",
            updatedAt: baseDate.addingTimeInterval(60),
            health: .stale
        )
        let warning = makeActiveRun(
            id: "00000000-0000-0000-0000-000000000003",
            updatedAt: baseDate.addingTimeInterval(120),
            attention: .warning
        )

        let summary = try XCTUnwrap(
            ActiveRunsPresentation.summary(for: [healthy, stale, warning])
        )

        XCTAssertEqual(summary.activeCount, 3)
        XCTAssertEqual(summary.needsAttentionCount, 2)
        XCTAssertEqual(summary.lastConfirmed, warning.updatedAt)
        XCTAssertFalse(summary.allHealthy)
    }

    private func makeActiveRun(
        id: String,
        updatedAt: Date,
        health: HealthStatus = .healthy,
        attention: AttentionStatus = .none
    ) -> RunSnapshot {
        RunSnapshot(
            id: UUID(uuidString: id)!,
            machineID: "machine-1",
            machineName: "Mac Studio",
            title: "Fixture run",
            executionStatus: .running,
            healthStatus: health,
            attentionStatus: attention,
            progress: nil,
            phase: nil,
            safeMessage: nil,
            startedAt: updatedAt.addingTimeInterval(-60),
            updatedAt: updatedAt,
            endedAt: nil,
            estimatedEndAt: nil,
            exitCode: nil,
            safeLogTail: nil,
            sequence: 1
        )
    }
}
