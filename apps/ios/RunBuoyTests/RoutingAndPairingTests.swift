import XCTest
@testable import RunBuoyApp

@MainActor
final class RoutingAndPairingTests: XCTestCase {
    func testRunDeepLinkSelectsRunsAndRoutesToDetail() throws {
        let id = UUID(uuidString: "018f0d8a-8c0a-7000-8000-000000000001")!
        let router = AppRouter()
        router.selectedTab = .settings

        XCTAssertTrue(router.handle(URL(string: "runbuoy://runs/\(id.uuidString)")!))
        XCTAssertEqual(router.selectedTab, .activeRuns)
        XCTAssertEqual(router.activeRunsPath, [.runDetail(id)])
    }

    func testUnrelatedURLIsNotConsumed() {
        let router = AppRouter()
        XCTAssertFalse(router.handle(URL(string: "https://example.com/runs/1")!))
        XCTAssertTrue(router.activeRunsPath.isEmpty)
    }

    func testDemoDeepLinkOpensFeatureTourInSettings() {
        let router = AppRouter()
        router.selectedTab = .activeRuns

        XCTAssertTrue(router.handle(URL(string: "runbuoy://demo/live-activity")!))
        XCTAssertEqual(router.selectedTab, .settings)
        XCTAssertEqual(router.settingsPath, [.capabilityDemo])
    }

    func testPairDeepLinkOpensConfirmationWithoutClaiming() throws {
        let router = AppRouter()
        let url = URL(
            string: "runbuoy://pair/session_123?challenge=once-only&machine=Mac%20Studio&platform=macOS"
        )!

        XCTAssertTrue(router.handle(url))
        XCTAssertEqual(router.selectedTab, .settings)
        XCTAssertEqual(router.settingsPath, [.pairMachine])
        XCTAssertEqual(router.pendingPairingCode?.sessionID, "session_123")
        XCTAssertEqual(router.pendingPairingCode?.challenge, "once-only")
    }

    func testHomeTabsDoNotIncludeMachines() {
        XCTAssertEqual(AppTab.allCases, [.activeRuns, .history, .settings])
    }

    func testCanonicalPairingURL() throws {
        let code = try PairingCode.decode(
            "runbuoy://pair/session_123?challenge=once-only&machine=Mac%20Studio&platform=macOS"
        )

        XCTAssertEqual(code.sessionID, "session_123")
        XCTAssertEqual(code.challenge, "once-only")
        XCTAssertEqual(code.machineDisplayName, "Mac Studio")
        XCTAssertEqual(code.platform, "macOS")
        XCTAssertEqual(code.region, .global)
    }

    func testChinaPairingCodeCarriesRegion() throws {
        let code = try PairingCode.decode(
            "runbuoy://pair/session_cn?challenge=c&machine=Builder&region=cn"
        )

        XCTAssertEqual(code.region, .china)
    }

    func testHostedRegionUsesGlobalWhileChinaDeploymentIsDeferred() throws {
        let suiteName = "RegionSelectionTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        try AppConfiguration.selectRegion(.china, userDefaults: userDefaults)

        XCTAssertEqual(AppConfiguration.hostedRegions, [.global])
        XCTAssertEqual(AppConfiguration.selectedRegion(userDefaults: userDefaults), .global)
        XCTAssertEqual(
            AppConfiguration.apiBaseURL(for: .china).absoluteString,
            AppConfiguration.bundledAPIBaseURL.absoluteString
        )
        let chinaCode = PairingCode(
            sessionID: "session_cn",
            challenge: "c",
            machineDisplayName: "Builder",
            platform: "linux",
            region: .china
        )
        let globalCode = PairingCode(
            sessionID: "session_global",
            challenge: "c",
            machineDisplayName: "Builder",
            platform: "linux"
        )
        XCTAssertThrowsError(try chinaCode.requireSelectedRegion(userDefaults: userDefaults))
        XCTAssertNoThrow(try globalCode.requireSelectedRegion(userDefaults: userDefaults))
        XCTAssertNoThrow(try AppConfiguration.selectRegion(.global, userDefaults: userDefaults))
    }

    func testQuerySessionPairingURLCompatibility() throws {
        let code = try PairingCode.decode(
            "runbuoy://pair?session=session_456&challenge=c&machine=Builder"
        )
        XCTAssertEqual(code.sessionID, "session_456")
    }

    func testJSONPairingPayloadCompatibility() throws {
        let code = try PairingCode.decode(
            #"{"pairing_session_id":"session_789","challenge":"c","machine_display_name":"Linux Builder","platform":"linux"}"#
        )
        XCTAssertEqual(code.machineDisplayName, "Linux Builder")
    }

    func testMachineIconsExposeOnlySupportedSymbols() {
        XCTAssertEqual(
            MachineIcon.allCases.map(\.rawValue),
            [
                "desktopcomputer",
                "macpro.gen3.server",
                "macbook",
                "macmini",
                "macstudio",
                "macpro.gen2"
            ]
        )
    }

    func testMachineConnectionStatesRemainSemanticallyDistinct() {
        let now = Date(timeIntervalSince1970: 1_785_076_800)

        XCTAssertEqual(
            MachineConnectionState.resolve(
                machine: machine(lastSeenAt: now.addingTimeInterval(-30)),
                now: now
            ),
            .online
        )
        XCTAssertEqual(
            MachineConnectionState.resolve(
                machine: machine(lastSeenAt: now.addingTimeInterval(-5 * 60)),
                now: now
            ),
            .idle
        )
        XCTAssertEqual(
            MachineConnectionState.resolve(
                machine: machine(lastSeenAt: now.addingTimeInterval(-10 * 60)),
                now: now
            ),
            .offline
        )
        XCTAssertEqual(
            MachineConnectionState.resolve(
                machine: machine(lastSeenAt: now, isSubscribed: false),
                now: now
            ),
            .updatesDisabled
        )
    }

    func testMachineIconSelectionIsStoredPerMachine() throws {
        let suiteName = "MachineIconTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        XCTAssertEqual(
            MachineIcon.selected(for: "machine_a", userDefaults: userDefaults),
            .desktopcomputer
        )

        userDefaults.set(
            MachineIcon.macStudio.rawValue,
            forKey: MachineIcon.key(for: "machine_a")
        )

        XCTAssertEqual(
            MachineIcon.selected(for: "machine_a", userDefaults: userDefaults),
            .macStudio
        )
        XCTAssertEqual(
            MachineIcon.selected(for: "machine_b", userDefaults: userDefaults),
            .desktopcomputer
        )
    }

    func testLegacyMachineLabelsAreRemoved() throws {
        let suiteName = "MachineNameMigrationTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        userDefaults.set("Local Builder", forKey: "runbuoy.machine-label.machine_a")
        userDefaults.set("keep", forKey: "unrelated")

        MachineNameMigration.removeLegacyLocalLabels(userDefaults: userDefaults)

        XCTAssertNil(userDefaults.string(forKey: "runbuoy.machine-label.machine_a"))
        XCTAssertEqual(userDefaults.string(forKey: "unrelated"), "keep")
    }

    func testAboutLinksUseCanonicalWebsite() {
        XCTAssertEqual(RunBuoyLinks.website.absoluteString, "https://www.runbuoy.cloud")
        XCTAssertEqual(RunBuoyLinks.privacy.absoluteString, "https://www.runbuoy.cloud/privacy")
        XCTAssertEqual(RunBuoyLinks.support.absoluteString, "https://www.runbuoy.cloud/support")
        XCTAssertEqual(
            RunBuoyLinks.privateDeployment.absoluteString,
            "https://www.runbuoy.cloud/self-hosting"
        )
    }

    func testDemoActivitiesAreExcludedFromServerSynchronization() {
        let production = RunActivityAttributes(
            runID: UUID().uuidString,
            title: "Production",
            machineName: "Mac Studio"
        )
        let demo = RunActivityAttributes(
            runID: UUID().uuidString,
            title: "Demo",
            machineName: "This iPhone",
            demoSessionID: UUID().uuidString
        )

        XCTAssertTrue(ActivityTokenCoordinator.shouldSynchronize(production))
        XCTAssertFalse(ActivityTokenCoordinator.shouldSynchronize(demo))
    }

    func testLegacyActivityAttributesDecodeWithoutDemoMarker() throws {
        let data = try XCTUnwrap(
            #"{"runID":"018f0d8a-8c0a-7000-8000-000000000001","title":"Build","machineName":"Mac Studio","schemaVersion":1}"#
                .data(using: .utf8)
        )

        let attributes = try JSONDecoder().decode(RunActivityAttributes.self, from: data)

        XCTAssertNil(attributes.demoSessionID)
        XCTAssertTrue(ActivityTokenCoordinator.shouldSynchronize(attributes))
    }

    private func machine(
        lastSeenAt: Date,
        isSubscribed: Bool = true
    ) -> MachineSnapshot {
        MachineSnapshot(
            id: "machine_state_test",
            displayName: "State Test",
            platform: "macOS",
            architecture: "arm64",
            cliVersion: "1.0.0",
            lastSeenAt: lastSeenAt,
            pairedAt: lastSeenAt.addingTimeInterval(-86_400),
            subscriptionID: isSubscribed ? "subscription_state_test" : nil,
            isSubscribed: isSubscribed
        )
    }

    func testDemoStepBuildsAndRestoresStaleState() {
        let now = Date(timeIntervalSince1970: 1_785_076_800)
        let state = CapabilityDemoStep.stale.contentState(
            now: now,
            createdAt: now.addingTimeInterval(-120),
            startedAt: now.addingTimeInterval(-100)
        )

        XCTAssertEqual(state.executionStatus, "RUNNING")
        XCTAssertEqual(state.healthStatus, "STALE")
        XCTAssertEqual(state.progress, 0.72)
        XCTAssertEqual(CapabilityDemoStep.step(for: state), .stale)
    }

    func testDemoTourUsesExactlyFiveContinuousSignalBuoyStates() {
        let now = Date(timeIntervalSince1970: 1_785_076_800)

        XCTAssertEqual(
            CapabilityDemoStep.allCases,
            [.running35, .running72Phase, .warning, .stale, .succeeded]
        )

        for step in CapabilityDemoStep.allCases {
            let state = step.contentState(
                now: now,
                createdAt: now.addingTimeInterval(-120),
                startedAt: now.addingTimeInterval(-100)
            )
            XCTAssertEqual(
                CapabilityDemoStep.step(for: state),
                step,
                "Expected demo state to round-trip: \(step)"
            )
            XCTAssertNotNil(state.trustedProgress)
            XCTAssertNil(state.estimatedEndAt)
        }

        XCTAssertEqual(CapabilityDemoStep.running35.previewProgress, 0.35)
        XCTAssertEqual(CapabilityDemoStep.running72Phase.previewProgress, 0.72)
        XCTAssertEqual(CapabilityDemoStep.running35.next, .running72Phase)
        XCTAssertEqual(CapabilityDemoStep.running72Phase.next, .warning)
        XCTAssertEqual(CapabilityDemoStep.warning.next, .stale)
        XCTAssertEqual(CapabilityDemoStep.stale.next, .succeeded)
        XCTAssertNil(CapabilityDemoStep.succeeded.next)
        XCTAssertTrue(CapabilityDemoStep.succeeded.isTerminal)

        let running35 = CapabilityDemoStep.running35.contentState(
            now: now,
            createdAt: now.addingTimeInterval(-120),
            startedAt: now.addingTimeInterval(-100)
        )
        let running72 = CapabilityDemoStep.running72Phase.contentState(
            now: now,
            createdAt: now.addingTimeInterval(-120),
            startedAt: now.addingTimeInterval(-100)
        )
        XCTAssertNil(running35.phase)
        XCTAssertNotNil(running72.phase)
        XCTAssertEqual(running35.trustedProgress?.fraction, 0.35)
        XCTAssertEqual(running72.trustedProgress?.fraction, 0.72)
    }
}

@MainActor
final class HistoryFilteringTests: XCTestCase {
    func testHistorySectionsShowFiveItemsUntilExpanded() {
        XCTAssertEqual(
            HistorySectionPresentation.visibleCount(totalCount: 12, isExpanded: false),
            5
        )
        XCTAssertEqual(
            HistorySectionPresentation.visibleCount(totalCount: 12, isExpanded: true),
            12
        )
        XCTAssertEqual(HistorySectionPresentation.remainingCount(totalCount: 12), 7)
        XCTAssertEqual(HistorySectionPresentation.remainingCount(totalCount: 4), 0)
    }

    func testMachineOptionsMergeSourcesAndPreferServerNames() {
        let messageOnly = RichMessage(
            id: "notification_message_only",
            machineID: "machine_message_only",
            title: "Message",
            subtitle: nil,
            body: "Body",
            level: "info",
            fields: [],
            createdAt: PreviewFixtures.baseDate,
            expiresAt: nil
        )

        let options = HistoryMachineOption.makeOptions(
            machines: [PreviewFixtures.machine],
            runs: [PreviewFixtures.activeRun, PreviewFixtures.failedRun],
            messages: [PreviewFixtures.message, messageOnly]
        )

        XCTAssertEqual(
            options,
            [
                HistoryMachineOption(id: PreviewFixtures.failedRun.machineID, name: "CI Builder"),
                HistoryMachineOption(id: PreviewFixtures.machine.id, name: "Mac Studio"),
                HistoryMachineOption(id: "machine_message_only", name: "machine_message_only")
            ]
        )
    }

    func testSelectedMachineFiltersRunsAndMessagesIncludingUnscopedMessages() {
        let unscopedMessage = RichMessage(
            id: "notification_unscoped",
            machineID: nil,
            title: "Workspace message",
            subtitle: nil,
            body: "Body",
            level: "info",
            fields: [],
            createdAt: PreviewFixtures.baseDate,
            expiresAt: nil
        )
        let runs = [PreviewFixtures.activeRun, PreviewFixtures.failedRun]
        let messages = [PreviewFixtures.message, PreviewFixtures.ciMessage, unscopedMessage]

        let all = HistoryContentFilter(machineID: nil)
        XCTAssertEqual(runs.filter { all.includes(machineID: $0.machineID) }, runs)
        XCTAssertEqual(messages.filter { all.includes(machineID: $0.machineID) }, messages)

        let selected = HistoryContentFilter(machineID: PreviewFixtures.ciMachine.id)
        XCTAssertEqual(
            runs.filter { selected.includes(machineID: $0.machineID) },
            [PreviewFixtures.failedRun]
        )
        XCTAssertEqual(
            messages.filter { selected.includes(machineID: $0.machineID) },
            [PreviewFixtures.ciMessage]
        )
    }
}

@MainActor
final class RunDetailSafetyTests: XCTestCase {
    func testSafeRunSummaryIncludesOnlyApprovedFields() throws {
        let run = PreviewFixtures.failedRun
        let summary = SafeRunSummary(run: run).rendered(locale: Locale(identifier: "en_US"))

        XCTAssertTrue(summary.contains(run.title))
        XCTAssertTrue(summary.contains(run.machineName))
        XCTAssertTrue(summary.contains(try XCTUnwrap(run.safeMessage)))
        XCTAssertTrue(summary.contains(try XCTUnwrap(run.phase)))
        XCTAssertFalse(summary.contains(run.id.uuidString.lowercased()))
        XCTAssertFalse(summary.contains(run.machineID))
        XCTAssertFalse(summary.contains(run.source ?? "source-not-present"))
        for line in run.safeLogTail ?? [] {
            XCTAssertFalse(summary.contains(line))
        }
    }

    func testSafeRunSummaryUsesLocalizedExecutionAndTrustedProgress() throws {
        let run = PreviewFixtures.activeRun
        let trusted = try XCTUnwrap(run.progress?.trustedProjection)
        let summary = SafeRunSummary(run: run).rendered(locale: Locale(identifier: "en_US"))

        XCTAssertTrue(summary.contains(String(localized: "status.running", locale: Locale(identifier: "en_US"))))
        XCTAssertTrue(summary.contains(trusted.current.formatted(.number.locale(Locale(identifier: "en_US")))))
        XCTAssertTrue(summary.contains(trusted.total.formatted(.number.locale(Locale(identifier: "en_US")))))
        XCTAssertFalse(summary.contains(run.id.uuidString))
    }
}
