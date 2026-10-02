import XCTest

final class RunBuoyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        if app.state != .notRunning {
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "\(name)-final-screen"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
            app.terminate()
        }
        app = nil
    }

    func testPluginConsentRequiresExplicitAllowAndSupportsRevocation() {
        let link = "runbuoy://connect/pca_" + String(repeating: "a", count: 32)
            + "?challenge=pcc_" + String(repeating: "b", count: 43)
        launch(initialURL: link)
        XCTAssertTrue(element("plugin.allow").waitForExistence(timeout: 5))
        XCTAssertTrue(element("plugin.requestWorkspace").exists)
        XCTAssertFalse(element("plugin.revoke").exists)
        attachScreenshot(named: "plugin-phone-consent-en")
        element("plugin.allow").tap()
        XCTAssertTrue(element("plugin.completion").waitForExistence(timeout: 3))
        let connection = element("plugin.connection.preview-grant")
        XCTAssertTrue(connection.waitForExistence(timeout: 3))
        XCTAssertFalse(element("plugin.revoke").exists)
        connection.tap()
        XCTAssertTrue(element("screen.agentConnectionDetails").waitForExistence(timeout: 3))
        let revoke = element("plugin.revoke")
        if !revoke.isHittable { app.swipeUp() }
        XCTAssertTrue(revoke.waitForExistence(timeout: 3))
        revoke.tap()
        XCTAssertTrue(element("plugin.confirmRevoke").waitForExistence(timeout: 3))
        element("plugin.confirmRevoke").tap()
        XCTAssertTrue(app.staticTexts["No active connections confirmed by this iPhone."].waitForExistence(timeout: 3))
    }

    func testPluginConsentCanBeDenied() {
        let link = "runbuoy://connect/pca_" + String(repeating: "a", count: 32)
            + "?challenge=pcc_" + String(repeating: "b", count: 43)
        launch(initialURL: link)
        XCTAssertTrue(element("plugin.deny").waitForExistence(timeout: 5))
        element("plugin.deny").tap()
        let completion = app.staticTexts["plugin.completion"]
        XCTAssertTrue(completion.waitForExistence(timeout: 3))
        XCTAssertTrue(completion.label.contains("Connection denied."), app.debugDescription)
        XCTAssertFalse(element("plugin.revoke").exists)
    }

    func testAgentConnectionLinkRequiresReviewAndExplicitConsent() {
        launch()
        tapTab("tab.settings", label: "Settings")
        let entry = element("settings.pluginConnections")
        XCTAssertTrue(entry.waitForExistence(timeout: 3))
        XCTAssertTrue(entry.label.contains("Agent connections"))
        entry.tap()
        XCTAssertTrue(element("screen.agentConnections").waitForExistence(timeout: 3))
        element("plugin.pasteAction").tap()
        let field = element("plugin.link")
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        XCTAssertFalse(element("plugin.review").isEnabled)
        field.tap()
        field.typeText("invalid-link")
        element("plugin.review").tap()
        XCTAssertTrue(element("plugin.linkError").waitForExistence(timeout: 3))
        XCTAssertFalse(element("plugin.allow").exists)
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "invalid-link".count))
        let link = "runbuoy://connect/pca_" + String(repeating: "a", count: 32)
            + "?challenge=pcc_" + String(repeating: "b", count: 43)
        field.typeText(link)
        element("plugin.review").tap()
        XCTAssertTrue(element("plugin.allow").waitForExistence(timeout: 5))
        XCTAssertFalse(element("plugin.connection.preview-grant").exists)
        element("plugin.deny").tap()
        XCTAssertTrue(element("plugin.completion").waitForExistence(timeout: 3))
        XCTAssertFalse(element("plugin.connection.preview-grant").exists)
    }

    func testAgentConnectionsOverviewAndDetail() {
        openConfirmedAgentConnection()
        XCTAssertTrue(element("plugin.connection.preview-grant").isHittable)
        XCTAssertTrue(element("plugin.scan").isHittable)
        XCTAssertTrue(element("plugin.pasteAction").isHittable)
        XCTAssertTrue(element("plugin.shareWorkspace").isHittable)
        XCTAssertFalse(element("plugin.revoke").exists)
        attachScreenshot(named: "agent-connections-overview-en")
        element("plugin.connection.preview-grant").tap()
        XCTAssertTrue(element("plugin.revoke").waitForExistence(timeout: 3))
        attachScreenshot(named: "agent-connection-detail-en")
    }

    func testAgentConnectionsLargestChineseTextKeepsActionsReachable() {
        openConfirmedAgentConnection(
            language: "zh-Hans",
            extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        )
        XCTAssertTrue(app.navigationBars["智能体连接"].exists)
        let connection = element("plugin.connection.preview-grant")
        XCTAssertTrue(connection.waitForExistence(timeout: 3))
        attachScreenshot(named: "agent-connections-zh-largest-top")
        connection.tap()
        let revoke = element("plugin.revoke")
        for _ in 0..<6 where !revoke.isHittable { app.swipeUp() }
        XCTAssertTrue(revoke.isHittable)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let paste = element("plugin.pasteAction")
        for _ in 0..<6 where !paste.isHittable { app.swipeUp() }
        XCTAssertTrue(paste.isHittable)
        let share = element("plugin.shareWorkspace")
        for _ in 0..<6 where !share.isHittable { app.swipeUp() }
        XCTAssertTrue(share.isHittable)
        attachScreenshot(named: "agent-connections-zh-largest-bottom")
    }

    private func openConfirmedAgentConnection(language: String = "en", extraArguments: [String] = []) {
        let link = "runbuoy://connect/pca_" + String(repeating: "a", count: 32)
            + "?challenge=pcc_" + String(repeating: "b", count: 43)
        launch(initialURL: link, language: language, extraArguments: extraArguments)
        let allow = element("plugin.allow")
        XCTAssertTrue(element("screen.agentConnections").waitForExistence(timeout: 5))
        for _ in 0..<6 where !allow.isHittable { app.swipeUp() }
        XCTAssertTrue(allow.isHittable)
        allow.tap()
        XCTAssertTrue(element("plugin.completion").waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let entry = element("settings.pluginConnections")
        for _ in 0..<6 where !entry.isHittable { app.swipeUp() }
        XCTAssertTrue(entry.waitForExistence(timeout: 3))
        entry.tap()
        XCTAssertTrue(element("screen.agentConnections").waitForExistence(timeout: 3))
    }

    func testOnboardingCompletesWithSeededPairingCode() {
        launch(
            onboarding: true,
            initialURL: Self.pairingURL
        )

        XCTAssertTrue(element("onboarding.page.product").waitForExistence(timeout: 5))
        element("onboarding.primary-action").tap()
        XCTAssertTrue(element("onboarding.page.region").waitForExistence(timeout: 2))
        app.segmentedControls.buttons["Global"].tap()

        element("onboarding.primary-action").tap()
        XCTAssertTrue(element("onboarding.page.permissions").waitForExistence(timeout: 2))

        element("onboarding.primary-action").tap()
        XCTAssertTrue(element("onboarding.page.pairing").waitForExistence(timeout: 2))
        XCTAssertTrue(element("onboarding.pairing-identity").exists)

        element("onboarding.primary-action").tap()
        XCTAssertTrue(element("onboarding.pairing-success").waitForExistence(timeout: 2))

        element("onboarding.primary-action").tap()
        XCTAssertTrue(element("screen.activeRuns").waitForExistence(timeout: 3))
    }

    func testActiveRunOpensDetailAndNavigatesBack() {
        launch()

        let activeRow = element("run.row.\(Self.activeRunID)")
        XCTAssertTrue(activeRow.waitForExistence(timeout: 5))
        XCTAssertTrue(activeRow.label.contains("Run time"))
        XCTAssertTrue(activeRow.label.contains("Last Confirmed"))
        activeRow.tap()

        XCTAssertTrue(element("screen.runDetail").waitForExistence(timeout: 3))
        element("screen.runDetail").swipeDown()
        XCTAssertTrue(element("screen.runDetail").exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("screen.activeRuns").waitForExistence(timeout: 3))
    }

    func testColdLaunchURLRoutesToRunDetail() {
        launch(initialURL: "runbuoy://runs/\(Self.activeRunID)")

        XCTAssertTrue(element("screen.runDetail").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Gurobi experiment"].exists)
    }

    func testHistoryFiltersRunsAndMessagesByMachine() {
        launch()
        tapTab("tab.history", label: "History")

        XCTAssertTrue(element("screen.history").waitForExistence(timeout: 3))
        let macMessage = element("history.message.notification_1")
        let ciMessage = element("history.message.notification_2")
        XCTAssertTrue(macMessage.exists)
        XCTAssertTrue(ciMessage.exists)

        element("history.filter.machine_ci").tap()

        XCTAssertTrue(ciMessage.waitForExistence(timeout: 2))
        XCTAssertTrue(macMessage.waitForNonExistence(timeout: 2))
        XCTAssertTrue(element("run.row.\(Self.failedRunID)").exists)

        let allFilter = element("history.filter.all")
        XCTAssertGreaterThanOrEqual(allFilter.frame.width, 44)
        XCTAssertGreaterThanOrEqual(allFilter.frame.height, 44)
        allFilter.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        XCTAssertTrue(macMessage.waitForExistence(timeout: 2))
        XCTAssertTrue(ciMessage.exists)
    }

    func testHistoryLoadsMachineFiltersWhenInitialSnapshotIsEmpty() {
        launch(scenario: "empty")
        tapTab("tab.history", label: "History")

        XCTAssertTrue(
            element("history.filter.machine_ci").waitForExistence(timeout: 3)
        )
    }

    func testNotificationPreferencePersistsAcrossRelaunch() {
        launch()
        tapTab("tab.settings", label: "Settings")

        let toggle = element("settings.notifications")
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.coordinate(
            withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
        ).tap()
        waitForValue("0", of: toggle)

        app.terminate()
        launch(resetState: false)
        tapTab("tab.settings", label: "Settings")

        let relaunchedToggle = element("settings.notifications")
        XCTAssertTrue(relaunchedToggle.waitForExistence(timeout: 3))
        XCTAssertEqual(relaunchedToggle.value as? String, "0")
    }

    func testMachineNameIsReadOnlyAndMatchesServer() {
        launch()
        openMachines()

        element("machine.row.machine_mac_studio").tap()
        XCTAssertTrue(element("screen.machineDetail").waitForExistence(timeout: 3))

        XCTAssertTrue(app.navigationBars["Mac Studio"].waitForExistence(timeout: 3))
        XCTAssertFalse(element("machine.localLabel").exists)
    }

    func testMachineStopReceivingAndRevokeHaveDistinctDestructiveConfirmations() {
        launch()
        openMachines()

        element("machine.row.machine_mac_studio").tap()
        XCTAssertTrue(element("screen.machineDetail").waitForExistence(timeout: 3))

        let stopReceiving = element("machine.stopReceiving")
        if !stopReceiving.isHittable {
            element("screen.machineDetail").swipeUp()
        }
        XCTAssertTrue(stopReceiving.waitForExistence(timeout: 3))
        stopReceiving.tap()
        XCTAssertTrue(
            app.staticTexts[
                "Only this iPhone’s subscription is removed. The computer stays paired and other devices are unaffected."
            ].waitForExistence(timeout: 2)
        )

        // Relaunch instead of relying on the system action sheet's cancel
        // accessibility node, which differs across iOS 18 and the latest SDK.
        app.terminate()
        launch()
        openMachines()
        element("machine.row.machine_mac_studio").tap()
        XCTAssertTrue(element("screen.machineDetail").waitForExistence(timeout: 3))

        let revoke = element("machine.revoke")
        if !revoke.isHittable {
            element("screen.machineDetail").swipeUp()
        }
        waitForHittable(revoke)
        revoke.tap()
        XCTAssertTrue(
            app.staticTexts
                .matching(
                    NSPredicate(
                        format: "label CONTAINS %@",
                        "immediately invalidates the computer and webhook credentials"
                    )
                )
                .firstMatch
                .waitForExistence(timeout: 2)
        )
    }

    func testManualPairingCodeCanBeConfirmed() {
        launch()
        openMachines()

        element("machines.enterPairingCode").tap()
        let codeField = element("pairing.code")
        XCTAssertTrue(codeField.waitForExistence(timeout: 3))
        codeField.tap()
        codeField.typeText(Self.pairingURL)
        element("pairing.continue").tap()

        let claimButton = element("pairing.claim")
        XCTAssertTrue(claimButton.waitForExistence(timeout: 3))
        XCTAssertTrue(element("pairing.machineName").exists)
        claimButton.tap()

        XCTAssertTrue(element("screen.machines").waitForExistence(timeout: 3))
        XCTAssertTrue(element("screen.pairMachine").waitForNonExistence(timeout: 3))
    }

    func testClearCacheShowsCompletionFeedback() {
        launch()
        tapTab("tab.settings", label: "Settings")

        let advancedData = element("settings.advancedData")
        if !advancedData.exists {
            element("screen.settings").swipeUp()
        }
        XCTAssertTrue(advancedData.waitForExistence(timeout: 3))
        advancedData.tap()
        XCTAssertTrue(element("screen.advancedData").waitForExistence(timeout: 3))

        let clearButton = element("settings.clearCache")
        XCTAssertTrue(clearButton.waitForExistence(timeout: 3))
        clearButton.tap()

        XCTAssertTrue(element("settings.cacheCleared").waitForExistence(timeout: 3))
    }

    func testCapabilityDemoOpensFromSettings() {
        launch()
        tapTab("tab.settings", label: "Settings")

        openCapabilityDemo()
        XCTAssertTrue(element("demo.startLiveActivity").exists)
    }

    func testRunDetailDisclosureUnavailableAndHistoryNavigationBoundaries() {
        launch()

        element("run.row.\(Self.activeRunID)").tap()
        XCTAssertTrue(element("screen.runDetail").waitForExistence(timeout: 3))
        XCTAssertFalse(element("run.copyID").exists)
        element("run.technicalDetails").tap()
        for _ in 0..<3 where !element("run.copyID").exists {
            element("screen.runDetail").swipeUp()
        }
        XCTAssertTrue(element("run.copyID").waitForExistence(timeout: 3))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        tapTab("tab.history", label: "History")
        XCTAssertTrue(element("screen.history").waitForExistence(timeout: 3))
        element("run.row.\(Self.failedRunID)").tap()
        XCTAssertTrue(element("screen.runDetail").waitForExistence(timeout: 3))

        launch(
            scenario: "unavailable",
            initialURL: "runbuoy://runs/\(Self.unavailableRunID)"
        )
        XCTAssertTrue(element("screen.runDetail").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Run unavailable"].exists)
        XCTAssertFalse(element("run.summaryActions").exists)
        XCTAssertFalse(element("run.copySummary").exists)
        XCTAssertFalse(element("run.shareSummary").exists)
    }

    func testAdvancedConfirmationsPreferenceTogglesAndScannerSheet() {
        launch()
        tapTab("tab.settings", label: "Settings")

        let safeMessages = element("settings.safeMessages")
        XCTAssertTrue(safeMessages.waitForExistence(timeout: 3))
        ensureSettingsControlVisible(safeMessages)
        let initialSafeMessagesValue = safeMessages.value as? String ?? "1"
        safeMessages.coordinate(
            withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
        ).tap()
        waitForValue(initialSafeMessagesValue == "1" ? "0" : "1", of: safeMessages)

        let liveActivities = element("settings.liveActivities")
        XCTAssertTrue(liveActivities.exists)
        if liveActivities.isEnabled {
            ensureSettingsControlVisible(liveActivities)
            let initialLiveActivitiesValue = liveActivities.value as? String ?? "1"
            liveActivities.coordinate(
                withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
            ).tap()
            waitForValue(
                initialLiveActivitiesValue == "1" ? "0" : "1",
                of: liveActivities
            )
        }

        openAdvancedData()
        attachScreenshot(named: "advanced-data-en")
        assertConfirmation(
            actionID: "settings.resetDevice",
            messagePrefix: "The server revokes this iPhone’s credential"
        )
        assertConfirmation(
            actionID: "settings.resetLocalOnly",
            messagePrefix: "Emergency option: local Keychain"
        )
        assertConfirmation(
            actionID: "settings.deleteWorkspace",
            messagePrefix: "This permanently deletes this workspace’s credentials"
        )

        app.navigationBars.buttons.element(boundBy: 0).tap()
        openMachines(fromSettings: true)
        attachScreenshot(named: "machines-en")
        element("machines.enterPairingCode").tap()
        XCTAssertTrue(element("screen.pairMachine").waitForExistence(timeout: 3))
        element("machines.scanPairingCode").tap()
        XCTAssertTrue(element("screen.qrScanner").waitForExistence(timeout: 3))
        attachScreenshot(named: "scanner-simulator-unavailable-en")
    }

    func testAccessibilityAuditForCoreScreensAndScenarios() throws {
        launch()
        XCTAssertTrue(element("screen.activeRuns").waitForExistence(timeout: 5))
        try auditCurrentScreen()

        element("run.row.\(Self.activeRunID)").tap()
        XCTAssertTrue(element("screen.runDetail").waitForExistence(timeout: 3))
        try auditCurrentScreen()

        app.navigationBars.buttons.element(boundBy: 0).tap()
        tapTab("tab.history", label: "History")
        XCTAssertTrue(element("screen.history").waitForExistence(timeout: 3))
        try auditCurrentScreen()

        tapTab("tab.settings", label: "Settings")
        XCTAssertTrue(element("screen.settings").waitForExistence(timeout: 3))
        waitForValue("Phone connected to server", of: element("settings.connectionSummary"), timeout: 5)
        try auditCurrentScreen()

        openCapabilityDemo()
        try auditCurrentScreen()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("screen.settings").waitForExistence(timeout: 3))

        let advancedData = element("settings.advancedData")
        if !advancedData.exists {
            element("screen.settings").swipeUp()
        }
        waitForHittable(advancedData)
        advancedData.tap()
        XCTAssertTrue(element("screen.advancedData").waitForExistence(timeout: 3))
        waitForHittable(element("settings.clearCache"))
        try auditCurrentScreen()

        app.swipeUp()
        try auditCurrentScreen()

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("screen.settings").waitForExistence(timeout: 3))
        openMachines(fromSettings: true)
        try auditCurrentScreen()

        launch(scenario: "empty")
        XCTAssertTrue(element("activeRuns.state.empty").waitForExistence(timeout: 3))
        try auditCurrentScreen()

        launch(scenario: "offline")
        XCTAssertTrue(element("runs.offlineBanner").waitForExistence(timeout: 3))
        try auditCurrentScreen()

        launch(scenario: "failed")
        XCTAssertTrue(element("activeRuns.state.failed").waitForExistence(timeout: 3))
        try auditCurrentScreen()
    }

    private func launch(
        scenario: String = "loaded",
        resetState: Bool = true,
        onboarding: Bool = false,
        initialURL: String? = nil,
        language: String = "en",
        extraArguments: [String] = []
    ) {
        if app.state != .notRunning {
            app.terminate()
        }
        app = XCUIApplication()
        app.launchArguments = [
            "-runbuoy-ui-testing",
            "-runbuoy-ui-scenario", scenario,
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "en" ? "en_US" : "zh_CN"
        ] + extraArguments
        // A developer's physical iPhone may contain real RunBuoy preferences.
        // Fixtures use an in-memory identity; only disposable simulators reset defaults.
#if targetEnvironment(simulator)
        if resetState {
            app.launchArguments.append("-runbuoy-ui-reset-state")
        }
#endif
        if onboarding {
            app.launchArguments.append("-runbuoy-ui-onboarding")
        }
        if let initialURL {
            app.launchArguments += ["-runbuoy-ui-url", initialURL]
        }
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 5),
            "RunBuoy did not reach the foreground after launch. Current state: \(app.state.rawValue)"
        )
    }

    private func openMachines(fromSettings: Bool = false) {
        if !fromSettings {
            tapTab("tab.settings", label: "Settings")
            XCTAssertTrue(element("screen.settings").waitForExistence(timeout: 3))
        }
        let machines = element("settings.machines")
        for _ in 0..<4 where !machines.isHittable {
            element("screen.settings").swipeDown()
        }
        XCTAssertTrue(machines.waitForExistence(timeout: 3))
        waitForHittable(machines)
        machines.tap()
        XCTAssertTrue(element("screen.machines").waitForExistence(timeout: 3))
    }

    private func openCapabilityDemo() {
        let featureTour = element("settings.capabilityDemo")
        for _ in 0..<4 where !featureTour.isHittable {
            element("screen.settings").swipeUp()
        }
        XCTAssertTrue(featureTour.waitForExistence(timeout: 3))
        waitForHittable(featureTour)
        featureTour.tap()
        XCTAssertTrue(element("screen.capabilityDemo").waitForExistence(timeout: 3))
    }

    private func openAdvancedData() {
        let advancedData = element("settings.advancedData")
        for _ in 0..<4 where !advancedData.isHittable {
            element("screen.settings").swipeUp()
        }
        waitForHittable(advancedData)
        advancedData.tap()
        XCTAssertTrue(element("screen.advancedData").waitForExistence(timeout: 3))
    }

    private func assertConfirmation(actionID: String, messagePrefix: String) {
        let action = element(actionID)
        if !action.isHittable {
            element("screen.advancedData").swipeUp()
        }
        waitForHittable(action)
        action.tap()
        XCTAssertTrue(
            app.staticTexts.matching(
                NSPredicate(format: "label BEGINSWITH %@", messagePrefix)
            ).firstMatch.waitForExistence(timeout: 2)
        )
        app.terminate()
        launch(resetState: false)
        tapTab("tab.settings", label: "Settings")
        openAdvancedData()
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
    }

    private func tapTab(
        _ identifier: String,
        label: String
    ) {
        let identifiedTab = element(identifier)
        if identifiedTab.waitForExistence(timeout: 1) {
            identifiedTab.tap()
            return
        }

        let labeledTab = app.tabBars.buttons[label]
        XCTAssertTrue(
            labeledTab.waitForExistence(timeout: 3),
            "Missing tab \(label) (\(identifier))"
        )
        labeledTab.tap()
    }

    private func ensureSettingsControlVisible(_ control: XCUIElement) {
        let settings = element("screen.settings")
        let top = app.navigationBars.firstMatch.frame.maxY + 8
        let bottom = app.tabBars.firstMatch.frame.minY - 12
        for _ in 0..<4 {
            let frame = control.frame
            if control.isHittable && frame.minY >= top && frame.maxY <= bottom {
                return
            }
            if frame.maxY > bottom {
                settings.swipeUp()
            } else {
                settings.swipeDown()
            }
        }
        XCTAssertTrue(control.isHittable, "Settings control must be tappable")
        XCTAssertGreaterThanOrEqual(control.frame.minY, top)
        XCTAssertLessThanOrEqual(control.frame.maxY, bottom)
    }

    private func waitForValue(
        _ value: String,
        of element: XCUIElement,
        timeout: TimeInterval = 2
    ) {
        let expectation: XCTestExpectation
        if element.value as? String == value {
            // A matching live value needs no delayed predicate polling.
            expectation = XCTestExpectation(description: "Control already has expected value")
            expectation.fulfill()
        } else {
            expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value == %@", value),
                object: element
            )
        }
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }

    private func waitForHittable(
        _ element: XCUIElement,
        timeout: TimeInterval = 3
    ) {
        let expectation: XCTestExpectation
        if element.isHittable {
            expectation = XCTestExpectation(description: "Control is already hittable")
            expectation.fulfill()
        } else {
            expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "hittable == true"),
                object: element
            )
        }
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }

    private func auditCurrentScreen() throws {
        try app.performAccessibilityAudit { issue in
            let isKnownSystemSectionHeaderIssue = issue.auditType == .contrast
                && issue.compactDescription == "Contrast nearly passed"
                && (
                    issue.element == nil
                        || issue.element.map {
                            Self.knownSystemSectionHeaderLabels.contains($0.label)
                        } == true
                )
            let isUnmappedSwiftUIRootContrastIssue = issue.auditType == .contrast
                && (
                    (
                        issue.element?.elementType == .application
                            && issue.element?.label == "RunBuoy"
                            && issue.detailedDescription.contains("SwiftUI.AccessibilityNode1")
                    )
                        || (
                            issue.element == nil
                                && (
                                    self.element("screen.settings").exists
                                        || self.element("screen.capabilityDemo").exists
                                        || self.element("screen.machines").exists
                                )
                                && issue.detailedDescription
                                == "Contrast failed for SwiftUI.AccessibilityNode"
                        )
                )
            let isSemanticallyScalingSwiftUIContainerIssue = issue.auditType == .dynamicType
                && issue.detailedDescription.contains("SwiftUI.AccessibilityNode")
                && issue.element.map { element in
                    Self.semanticallyScalingIdentifiers.contains(element.identifier)
                        || element.identifier.hasPrefix("history.message.")
                        || element.identifier.hasPrefix("settings.connectionSummary.")
                        || Self.knownSystemSectionHeaderLabels.contains(element.label)
                        || Self.semanticallyScalingLabelPrefixes.contains {
                            element.label.hasPrefix($0)
                        }
                } == true
            let tabBar = self.app.tabBars.firstMatch
            let isCoveredBySystemTabBar = issue.auditType == .contrast
                && issue.element.map {
                    tabBar.exists
                        && $0.frame.intersects(tabBar.frame)
                        && !$0.isHittable
                } == true
            let navigationBar = self.app.navigationBars.firstMatch
            let isCoveredBySystemNavigationBar = issue.element.map {
                navigationBar.exists
                    && $0.frame.intersects(navigationBar.frame)
            } == true
            let isUnmappedOffscreenSettingsIssue =
                issue.compactDescription == "Text clipped"
                    && issue.element == nil
                    && (
                        self.element("screen.settings").exists
                            || self.element("screen.advancedData").exists
                    )
            let isKnownToolIssue =
                isKnownSystemSectionHeaderIssue
                    || isUnmappedSwiftUIRootContrastIssue
                    || isSemanticallyScalingSwiftUIContainerIssue
                    || isCoveredBySystemTabBar
                    || isCoveredBySystemNavigationBar
                    || isUnmappedOffscreenSettingsIssue

            if !isKnownToolIssue {
                XCTContext.runActivity(
                    named: "Accessibility audit: \(issue.compactDescription) [\(issue.element?.label ?? "unknown element")]"
                ) { activity in
                    let attachment = XCTAttachment(string: issue.detailedDescription)
                    attachment.name = "Accessibility audit details"
                    attachment.lifetime = .keepAlways
                    activity.add(attachment)

                    let hierarchy = XCTAttachment(string: self.app.debugDescription)
                    hierarchy.name = "Accessibility hierarchy"
                    hierarchy.lifetime = .keepAlways
                    activity.add(hierarchy)
                }
            }
            return isKnownToolIssue
        }
    }

    private static let activeRunID = "018f0d8a-8c0a-7000-8000-000000000001"
    private static let failedRunID = "018f0d8a-8c0a-7000-8000-000000000002"
    private static let unavailableRunID = "018f0d8a-8c0a-7000-8000-000000000099"
    private static let pairingURL =
        "runbuoy://pair/session_ui_test?challenge=once-only&machine=UI%20Test%20Mac&platform=macOS&region=global"
    private static let semanticallyScalingIdentifiers: Set<String> = [
        "run.timing.execution",
        "run.timing.heartbeat",
        "run.timing.completion",
        "run.metric.elapsed",
        "run.metric.lastConfirmed",
        "settings.regionLock",
        "demo.liveActivityIntro",
        "demo.startLiveActivity",
        "demo.nextStep",
        "demo.chooseState",
        "demo.stopLiveActivity",
        "demo.startAgain",
        "demo.sendNotification",
        "run.copySummary",
        "run.shareSummary"
    ]
    private static let semanticallyScalingLabelPrefixes = [
        "Run time",
        "Heartbeat",
        "Elapsed",
        "Last Confirmed",
        "Completed",
        "The selected data region cannot be changed.",
        "Start Live Activity",
        "Copy Summary",
        "Share Summary"
    ]
    private static let knownSystemSectionHeaderLabels: Set<String> = [
        "Active Runs",
        "Timing",
        "Safe Message",
        "Run Feed",
        "Uploaded Safe Log Snippet",
        "Run ID",
        "Recent Runs",
        "Recent Messages",
        "Connections",
        "Notifications and Display",
        "Local Data",
        "Destructive Actions",
        "These actions never stop, retry, or control a run on a Mac.",
        "Paired Machines",
        "Pull to refresh machine availability. Pairing and notification preferences stay private to this workspace.",
        "Pair New Machine",
        "Try Again",
        "Storage",
        "Identity and Data",
        "About"
    ]
}
