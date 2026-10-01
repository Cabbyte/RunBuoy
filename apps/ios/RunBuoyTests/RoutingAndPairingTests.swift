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

    func testDemoTourUsesApprovedContinuousSequence() {
        let now = Date(timeIntervalSince1970: 1_785_076_800)
        let expected: [CapabilityDemoStep] = [
            .running35,
            .running72,
            .warning,
            .stale,
            .succeeded
        ]

        XCTAssertEqual(CapabilityDemoStep.allCases, expected)
        XCTAssertEqual(expected.map(\.next), [
            .running72,
            .warning,
            .stale,
            .succeeded,
            nil
        ])
        XCTAssertEqual(expected.map(\.previewProgress), [0.35, 0.72, 0.72, 0.72, 1])

        for step in expected {
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
            XCTAssertNil(state.estimatedEndAt)
            XCTAssertEqual(state.progressKind, "determinate")
            XCTAssertEqual(state.current, state.progress.map { $0 * 100 })
            XCTAssertEqual(state.total, 100)
        }

        XCTAssertFalse(CapabilityDemoStep.stale.isTerminal)
        XCTAssertTrue(CapabilityDemoStep.succeeded.isTerminal)
    }
}

@MainActor
final class ActiveRunPresentationTests: XCTestCase {
    func testHeroOrderingUsesSeverityThenRecencyThenStableID() {
        let running = makeRun(
            id: "00000000-0000-0000-0000-000000000005",
            execution: .running,
            updatedOffset: 10
        )
        let starting = makeRun(
            id: "00000000-0000-0000-0000-000000000004",
            execution: .starting,
            updatedOffset: 20
        )
        let offline = makeRun(
            id: "00000000-0000-0000-0000-000000000003",
            health: .offline,
            updatedOffset: 30
        )
        let warning = makeRun(
            id: "00000000-0000-0000-0000-000000000002",
            attention: .warning,
            updatedOffset: 40
        )
        let action = makeRun(
            id: "00000000-0000-0000-0000-000000000001",
            attention: .actionRequired,
            updatedOffset: 1
        )

        let sorted = ActiveRunPresentation.sorted(
            [running, action, offline, starting, warning].map(RunSummaryModel.init)
        )

        XCTAssertEqual(
            sorted.map(\.id),
            [action.id, warning.id, offline.id, starting.id, running.id]
        )

        let laterID = makeRun(
            id: "00000000-0000-0000-0000-000000000012",
            updatedOffset: 50
        )
        let earlierID = makeRun(
            id: "00000000-0000-0000-0000-000000000011",
            updatedOffset: 50
        )
        XCTAssertTrue(ActiveRunPresentation.orderedBefore(earlierID, laterID))
    }

    func testSystemSummaryReportsActualIssuesAndLatestConfirmation() {
        let healthy = makeRun(
            id: "00000000-0000-0000-0000-000000000021",
            updatedOffset: 20
        )
        let warning = makeRun(
            id: "00000000-0000-0000-0000-000000000022",
            attention: .warning,
            updatedOffset: 40
        )
        let offline = makeRun(
            id: "00000000-0000-0000-0000-000000000023",
            health: .offline,
            updatedOffset: 30
        )

        let summary = ActiveSystemSummary(runs: [healthy, warning, offline])

        XCTAssertEqual(summary.activeCount, 3)
        XCTAssertEqual(summary.issueCount, 2)
        XCTAssertEqual(summary.lastConfirmedAt, warning.updatedAt)
        XCTAssertFalse(summary.isHealthy)
        XCTAssertTrue(ActiveSystemSummary(runs: [healthy]).isHealthy)
        XCTAssertFalse(ActiveSystemSummary(runs: []).isHealthy)
    }

    private func makeRun(
        id: String,
        execution: ExecutionStatus = .running,
        health: HealthStatus = .healthy,
        attention: AttentionStatus = .none,
        updatedOffset: TimeInterval
    ) -> RunSnapshot {
        let startedAt = PreviewFixtures.baseDate
        return RunSnapshot(
            id: UUID(uuidString: id)!,
            machineID: "machine_test",
            machineName: "Test Mac",
            title: "Test run",
            executionStatus: execution,
            healthStatus: health,
            attentionStatus: attention,
            progress: nil,
            phase: nil,
            safeMessage: nil,
            startedAt: startedAt,
            updatedAt: startedAt.addingTimeInterval(updatedOffset),
            endedAt: nil,
            estimatedEndAt: nil,
            exitCode: nil,
            safeLogTail: nil,
            sequence: Int(updatedOffset)
        )
    }
}

@MainActor
final class SettingsOnboardingMachinesFoundationTests: XCTestCase {
    func testAdvancedDataHasDedicatedSettingsRoute() {
        let router = AppRouter()

        router.settingsPath.append(.advancedData)

        XCTAssertEqual(router.settingsPath, [.advancedData])
        XCTAssertNotEqual(AppRoute.advancedData, .machines)
    }

    func testAdvancedDataKeepsExactlyTheExistingDangerActions() {
        XCTAssertEqual(
            SettingsLifecycleAction.allCases.map(\.accessibilityIdentifier),
            [
                "settings.resetDevice",
                "settings.resetLocalOnly",
                "settings.deleteWorkspace"
            ]
        )
    }

    func testSettingsConnectionSummaryUsesConfirmedRefreshAndCacheSemantics() {
        XCTAssertEqual(
            SettingsConnectionState.resolve(loadState: .loaded, isRefreshing: false),
            .confirmed
        )
        XCTAssertEqual(
            SettingsConnectionState.resolve(loadState: .loaded, isRefreshing: true),
            .refreshing
        )
        XCTAssertEqual(
            SettingsConnectionState.resolve(loadState: .offline("cached"), isRefreshing: false),
            .cached
        )
        XCTAssertEqual(
            SettingsConnectionState.resolve(loadState: .failed("unavailable"), isRefreshing: false),
            .unavailable
        )
    }

    func testOnboardingHasFourOrderedSteps() {
        XCTAssertEqual(
            OnboardingStep.allCases,
            [.welcome, .region, .notifications, .pairMac]
        )
        XCTAssertEqual(OnboardingStep.welcome.next, .region)
        XCTAssertEqual(OnboardingStep.region.next, .notifications)
        XCTAssertEqual(OnboardingStep.notifications.next, .pairMac)
        XCTAssertNil(OnboardingStep.pairMac.next)
    }

    func testMachineVisualStateDoesNotClaimOnlinePresence() {
        let now = Date(timeIntervalSince1970: 10_000)

        XCTAssertEqual(
            MachineReceivingVisualState.resolve(
                isSubscribed: true,
                lastSeenAt: now.addingTimeInterval(-30),
                now: now
            ),
            .recentConfirmation
        )
        XCTAssertEqual(
            MachineReceivingVisualState.resolve(
                isSubscribed: true,
                lastSeenAt: now.addingTimeInterval(-601),
                now: now
            ),
            .awaitingConfirmation
        )
        XCTAssertEqual(
            MachineReceivingVisualState.resolve(
                isSubscribed: false,
                lastSeenAt: now,
                now: now
            ),
            .updatesDisabled
        )
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
