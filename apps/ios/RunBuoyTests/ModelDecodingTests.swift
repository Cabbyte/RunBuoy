import ActivityKit
import XCTest
@testable import RunBuoyApp

final class ModelDecodingTests: XCTestCase {
    func testRunDetailDecodesProtocolFixtureAndLastSequence() throws {
        let detail = try JSONDecoder.runBuoy.decode(
            RunDetail.self,
            from: FixtureLoader.data("run-detail")
        )

        XCTAssertEqual(detail.run.sequence, 42)
        XCTAssertEqual(detail.run.progress?.boundedFraction, 0.37)
        XCTAssertNotNil(detail.run.estimatedEndAt)
        XCTAssertEqual(detail.run.healthStatus, .healthy)
        XCTAssertLessThan(detail.run.createdAt, detail.run.startedAt)
        XCTAssertEqual(detail.feed.map(\.sequence), [42, 1])
    }

    func testUnknownExecutionStateIsForwardCompatible() throws {
        let runs = try JSONDecoder.runBuoy.decode(
            [RunSnapshot].self,
            from: FixtureLoader.data("runs")
        )

        XCTAssertEqual(runs.first?.executionStatus, .unknown)
        XCTAssertEqual(runs.first?.healthStatus, .stale)
        XCTAssertEqual(runs.first?.sequence, 9)
    }

    func testMachineProjectionToleratesAbsentSubscriptionFields() throws {
        let machines = try JSONDecoder.runBuoy.decode(
            [MachineSnapshot].self,
            from: FixtureLoader.data("machines")
        )

        XCTAssertEqual(machines.count, 2)
        XCTAssertFalse(machines[0].isSubscribed)
        XCTAssertNil(machines[0].subscriptionID)
        XCTAssertTrue(machines[1].isSubscribed)
    }

    func testRichFieldsAcceptServerLabelKeyAndRemainPlainText() throws {
        let messages = try JSONDecoder.runBuoy.decode(
            [RichMessage].self,
            from: FixtureLoader.data("messages")
        )

        XCTAssertEqual(messages[0].fields[0].name, "Artifacts")
        XCTAssertEqual(messages[0].body, "<script>plain text only</script>")
    }

    func testLiveActivityContentStateDecodesISO8601Dates() throws {
        let state = try JSONDecoder().decode(
            RunActivityAttributes.ContentState.self,
            from: FixtureLoader.data("live-content-state")
        )

        XCTAssertEqual(state.sequence, 42)
        XCTAssertEqual(state.current, 37)
        XCTAssertEqual(state.healthStatus, "STALE")
        XCTAssertEqual(state.machineName, "Mac Studio")
        XCTAssertNotNil(state.createdAt)
        XCTAssertNotNil(state.estimatedEndAt)
    }

    func testRunSnapshotProjectsToMatchingLiveActivityContent() throws {
        let detail = try JSONDecoder.runBuoy.decode(
            RunDetail.self,
            from: FixtureLoader.data("run-detail")
        )

        let state = RunLiveActivityProjection.contentState(for: detail.run)

        XCTAssertEqual(state.sequence, detail.run.sequence)
        XCTAssertEqual(state.executionStatus, detail.run.executionStatus.rawValue)
        XCTAssertEqual(state.progress, detail.run.progress?.fraction)
        XCTAssertEqual(state.updatedAt, detail.run.updatedAt)
        XCTAssertEqual(state.endedAt, detail.run.endedAt)
        XCTAssertEqual(state.machineName, detail.run.machineName)
    }

    func testConfirmedDurationUsesCreationAndLastMachineUpdate() {
        let created = Date(timeIntervalSince1970: 1_000)
        let started = created.addingTimeInterval(2)
        let confirmed = created.addingTimeInterval(75)

        XCTAssertEqual(
            RunActivityDurationText.string(
                createdAt: created,
                startedAt: started,
                updatedAt: confirmed
            ),
            "1:15"
        )
        XCTAssertEqual(
            RunActivityDurationText.string(
                createdAt: created,
                startedAt: started,
                updatedAt: created.addingTimeInterval(3_661)
            ),
            "1:01:01"
        )
    }

    func testTerminalLiveActivityTimeUsesJustNowThenWholeMinutes() {
        let endedAt = Date(timeIntervalSince1970: 1_000)
        let locale = Locale(identifier: "en_US")

        XCTAssertEqual(
            RunActivityTerminalTimeText.string(
                endedAt: endedAt,
                currentDate: endedAt,
                locale: locale
            ),
            "just now"
        )
        XCTAssertEqual(
            RunActivityTerminalTimeText.string(
                endedAt: endedAt,
                currentDate: endedAt.addingTimeInterval(59.999),
                locale: locale
            ),
            "just now"
        )
        XCTAssertEqual(
            RunActivityTerminalTimeText.string(
                endedAt: endedAt,
                currentDate: endedAt.addingTimeInterval(60),
                locale: locale
            ),
            "1m ago"
        )
        XCTAssertEqual(
            RunActivityTerminalTimeText.string(
                endedAt: endedAt,
                currentDate: endedAt.addingTimeInterval(119.999),
                locale: locale
            ),
            "1m ago"
        )
        XCTAssertEqual(
            RunActivityTerminalTimeText.string(
                endedAt: endedAt,
                currentDate: endedAt.addingTimeInterval(120),
                locale: locale
            ),
            "2m ago"
        )
        XCTAssertEqual(
            RunActivityTerminalTimeText.string(
                endedAt: endedAt,
                currentDate: endedAt.addingTimeInterval(3_660),
                locale: locale
            ),
            "61m ago"
        )
        XCTAssertEqual(
            RunActivityTerminalTimeText.nextRefreshDate(
                endedAt: endedAt,
                currentDate: endedAt.addingTimeInterval(30)
            ),
            endedAt.addingTimeInterval(60)
        )
        XCTAssertEqual(
            RunActivityTerminalTimeText.nextRefreshDate(
                endedAt: endedAt,
                currentDate: endedAt.addingTimeInterval(60)
            ),
            endedAt.addingTimeInterval(120)
        )
    }

    func testTerminalLiveActivityTimeAnchorsToCompletionNotRunStart() {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let startedAt = createdAt.addingTimeInterval(30)
        let endedAt = startedAt.addingTimeInterval(3_600)
        let state = RunActivityAttributes.ContentState(
            sequence: 2,
            executionStatus: "SUCCEEDED",
            healthStatus: "HEALTHY",
            attentionStatus: "NONE",
            progressKind: "determinate",
            progress: 1,
            phase: "Completed",
            message: nil,
            createdAt: createdAt,
            startedAt: startedAt,
            updatedAt: endedAt,
            endedAt: endedAt,
            estimatedEndAt: nil,
            exitCode: 0
        )

        XCTAssertEqual(state.completionDate, endedAt)
        XCTAssertEqual(
            RunActivityTerminalTimeText.string(
                endedAt: state.completionDate,
                currentDate: endedAt.addingTimeInterval(59.999),
                locale: Locale(identifier: "en_US")
            ),
            "just now"
        )
    }

    func testTerminalLiveActivityTimeLocalizesChineseMinutes() {
        let endedAt = Date(timeIntervalSince1970: 1_000)
        let locale = Locale(identifier: "zh-Hans")

        XCTAssertEqual(
            RunActivityTerminalTimeText.string(
                endedAt: endedAt,
                currentDate: endedAt,
                locale: locale
            ),
            "刚刚"
        )
        XCTAssertEqual(
            RunActivityTerminalTimeText.string(
                endedAt: endedAt,
                currentDate: endedAt.addingTimeInterval(60),
                locale: locale
            ),
            "1分钟前"
        )
    }

    func testRunDurationUsesStartAndLatestMachineConfirmation() {
        let started = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(
            RunDurationText.string(
                from: started,
                to: started.addingTimeInterval(75)
            ),
            "1:15"
        )
        XCTAssertEqual(
            RunDurationText.string(
                from: started,
                to: started.addingTimeInterval(3_661)
            ),
            "1:01:01"
        )
    }

    func testLiveActivityContentStateKeepsOldPayloadCompatibility() throws {
        let data = Data(
            """
            {
              "sequence": 1,
              "executionStatus": "RUNNING",
              "healthStatus": "HEALTHY",
              "attentionStatus": "NONE",
              "progressKind": "indeterminate",
              "startedAt": "2026-07-29T08:00:00Z",
              "updatedAt": "2026-07-29T08:00:15Z"
            }
            """.utf8
        )

        let state = try JSONDecoder().decode(
            RunActivityAttributes.ContentState.self,
            from: data
        )

        XCTAssertNil(state.createdAt)
        XCTAssertNil(state.machineName)
        XCTAssertEqual(
            RunActivityDurationText.string(
                createdAt: state.createdAt,
                startedAt: state.startedAt,
                updatedAt: state.updatedAt
            ),
            "0:15"
        )
    }

    func testProgressFractionIsBoundedForRendering() {
        let progress = RunProgress(
            kind: .determinate,
            current: 125,
            total: 100,
            fraction: 1.25,
            unit: "items",
            source: "explicit"
        )

        XCTAssertEqual(progress.boundedFraction, 1)
    }

    func testLongEnglishAndChineseFixturesPreserveContent() {
        XCTAssertGreaterThan(PreviewFixtures.longEnglishDetail.run.title.count, 70)
        XCTAssertGreaterThan(PreviewFixtures.longChineseDetail.run.safeMessage?.count ?? 0, 30)
    }

    func testSafeRunSummaryIncludesOnlyApprovedPresentationFields() {
        let run = summaryRun(
            executionStatus: .running,
            healthStatus: .healthy,
            safeMessage: "Safe checkpoint confirmed.",
            source: "command --token SECRET /private/project",
            safeLogTail: [
                "RAW_LOG_SENTINEL",
                "API_KEY=SECRET_VALUE"
            ]
        )

        let summary = SafeRunSummary.text(
            for: run,
            includesSafeMessage: true,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertTrue(summary.contains("Safe summary test"))
        XCTAssertTrue(summary.contains("Name: Test Mac"))
        XCTAssertTrue(summary.contains("Running"))
        XCTAssertTrue(summary.contains("Phase: Uploading artifacts"))
        XCTAssertTrue(summary.contains("Progress: 31 / 50 files"))
        XCTAssertTrue(summary.contains(run.updatedAt.formatted(
            .dateTime
                .year()
                .month()
                .day()
                .hour()
                .minute()
                .second()
                .locale(Locale(identifier: "en_US"))
        )))
        XCTAssertTrue(summary.contains("Safe Message: Safe checkpoint confirmed."))
        XCTAssertFalse(summary.contains(run.id.uuidString.lowercased()))
        XCTAssertFalse(summary.contains("RAW_LOG_SENTINEL"))
        XCTAssertFalse(summary.contains("command --token"))
        XCTAssertFalse(summary.contains("/private/project"))
        XCTAssertFalse(summary.contains("API_KEY"))
        XCTAssertFalse(summary.contains("SECRET"))
    }

    func testSafeRunSummaryRespectsSafeMessagePreferenceAndRejectsUntrustedProgress() {
        let invalidProgress = RunProgress(
            kind: .determinate,
            current: 31,
            total: 0,
            fraction: 0.62,
            unit: "files",
            source: "untrusted"
        )
        let run = summaryRun(
            progress: invalidProgress,
            safeMessage: "SAFE_MESSAGE_SENTINEL"
        )

        let summary = SafeRunSummary.text(
            for: run,
            includesSafeMessage: false,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertFalse(summary.contains("SAFE_MESSAGE_SENTINEL"))
        XCTAssertFalse(summary.contains("Progress:"))
    }

    func testUnavailableRunHasNoSummaryActions() {
        XCTAssertFalse(RunDetailSummaryActionsPolicy.isAvailable(detail: nil))
        XCTAssertTrue(
            RunDetailSummaryActionsPolicy.isAvailable(
                detail: RunDetail(run: summaryRun(), feed: [])
            )
        )
    }

    func testCancelledRunIsTerminalWithoutLiveEmphasisAndKeepsConfirmedProgress() {
        let run = summaryRun(executionStatus: .cancelled, healthStatus: .healthy)
        let status = run.statusVisualState
        let progress = run.progressVisualState

        XCTAssertEqual(status.kind, .cancelled)
        XCTAssertTrue(status.isTerminal)
        XCTAssertFalse(status.isActive)
        XCTAssertFalse(status.allowsLiveEmphasis)
        XCTAssertEqual(progress.kind, .determinate)
        XCTAssertEqual(progress.fraction, 0.62)
        XCTAssertFalse(progress.allowsLiveMotion)
        XCTAssertFalse(progress.allowsGlow)
        XCTAssertEqual(RunDetailTiming.elapsedEndDate(for: run), run.updatedAt)
    }

    func testDetailElapsedOnlyAdvancesForHealthyActiveRun() {
        let running = summaryRun(executionStatus: .running, healthStatus: .healthy)
        let stale = summaryRun(executionStatus: .running, healthStatus: .stale)
        let offline = summaryRun(executionStatus: .running, healthStatus: .offline)
        let succeeded = summaryRun(executionStatus: .succeeded, healthStatus: .healthy)

        XCTAssertNil(RunDetailTiming.elapsedEndDate(for: running))
        XCTAssertEqual(RunDetailTiming.elapsedEndDate(for: stale), stale.updatedAt)
        XCTAssertEqual(RunDetailTiming.elapsedEndDate(for: offline), offline.updatedAt)
        XCTAssertEqual(RunDetailTiming.elapsedEndDate(for: succeeded), succeeded.endedAt)
    }

    private func summaryRun(
        executionStatus: ExecutionStatus = .running,
        healthStatus: HealthStatus = .healthy,
        progress: RunProgress? = RunProgress(
            kind: .determinate,
            current: 31,
            total: 50,
            fraction: 0.62,
            unit: "files",
            source: "explicit"
        ),
        safeMessage: String? = "Safe checkpoint confirmed.",
        source: String? = "cli",
        safeLogTail: [String]? = nil
    ) -> RunSnapshot {
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let updatedAt = startedAt.addingTimeInterval(252)
        return RunSnapshot(
            id: UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000009999")!,
            machineID: "machine_test",
            machineName: "Test Mac",
            title: "Safe summary test",
            source: source,
            executionStatus: executionStatus,
            healthStatus: healthStatus,
            attentionStatus: .none,
            progress: progress,
            phase: "Uploading artifacts",
            safeMessage: safeMessage,
            startedAt: startedAt,
            updatedAt: updatedAt,
            endedAt: executionStatus.isTerminal ? updatedAt : nil,
            estimatedEndAt: nil,
            exitCode: executionStatus.isTerminal ? 0 : nil,
            safeLogTail: safeLogTail,
            sequence: 99
        )
    }
}
