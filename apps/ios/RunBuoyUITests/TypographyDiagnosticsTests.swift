import UIKit
import Vision
import XCTest

final class TypographyDiagnosticsTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        if app.state != .notRunning {
            attachScreenshot("diagnostic-final-screen")
            app.terminate()
        }
        app = nil
    }

    func testMinimalSwiftUITextNativeAuditWithoutFilters() throws {
        launch(extraArguments: ["-runbuoy-ui-typography-probe"])
        XCTAssertTrue(app.staticTexts["probe.hint"].waitForExistence(timeout: 5))
        try recordUnfilteredAudit()
    }

    func testMinimalUIKitLabelNativeAuditWithoutFilters() throws {
        launch(extraArguments: ["-runbuoy-ui-typography-probe", "-runbuoy-probe-uikit"])
        XCTAssertTrue(app.staticTexts["probe.hint"].waitForExistence(timeout: 5))
        try recordUnfilteredAudit()
    }

    func testCombinedSwiftUITextNativeAuditWithoutFilters() throws {
        launch(extraArguments: ["-runbuoy-ui-typography-probe", "-runbuoy-probe-combined"])
        XCTAssertTrue(app.staticTexts["probe.hint"].waitForExistence(timeout: 5))
        try recordUnfilteredAudit()
    }

    func testFormNativeAuditWithoutFilters() throws {
        launch(extraArguments: ["-runbuoy-ui-typography-probe", "-runbuoy-probe-form"])
        XCTAssertTrue(app.staticTexts["probe.title"].waitForExistence(timeout: 5))
        try recordUnfilteredAudit()
    }

    func testLowerFormRowNativeAuditWithoutFilters() throws {
        launch(extraArguments: ["-runbuoy-ui-typography-probe", "-runbuoy-probe-form", "-runbuoy-probe-lower-row"])
        XCTAssertTrue(app.staticTexts["probe.title"].waitForExistence(timeout: 5))
        try recordUnfilteredAudit()
    }

    func testActiveNativeAuditWithoutFilters() throws {
        launch()
        XCTAssertTrue(element("screen.activeRuns").waitForExistence(timeout: 5))
        try recordUnfilteredAudit()
    }

    func testSettingsNativeAuditWithoutFilters() throws {
        launch()
        tapTab("Settings")
        XCTAssertTrue(element("screen.settings").waitForExistence(timeout: 5))
        try recordUnfilteredAudit()
    }

    func testRuntimeFontSwitchPreservesAppAndMachineNavigation() throws {
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        if !settings.switches["Larger Accessibility Sizes"].exists {
            tapSettingsEntry("Accessibility", in: settings)
            tapSettingsEntry("Display & Text Size", in: settings)
            tapSettingsEntry("Larger Text", in: settings)
        }
        let expandedSizes = settings.switches["Larger Accessibility Sizes"]
        XCTAssertTrue(expandedSizes.waitForExistence(timeout: 5), settings.debugDescription)
        XCTAssertTrue(settings.sliders.firstMatch.waitForExistence(timeout: 5))
        let originalSwitch = try XCTUnwrap(expandedSizes.value as? String)
        let originalPosition = settings.sliders.firstMatch.normalizedSliderPosition
        XCTAssertTrue(["0", "1"].contains(originalSwitch))
        XCTAssertTrue((0...1).contains(originalPosition))
        print("SYSTEM SIZE SNAPSHOT switch=\(originalSwitch) slider=\(originalPosition)")

        // Registered before the first change. XCTest runs this even when an
        // assertion aborts the test, before tearDownWithError terminates the app.
        addTeardownBlock { [self] in
            continueAfterFailure = true
            attachScreenshot("runtime-before-state-restoration")
            settings.activate()
            XCTAssertTrue(setSystemSwitch(expandedSizes, to: originalSwitch, in: settings))
            XCTAssertTrue(setSystemSlider(in: settings, to: originalPosition))
            XCTAssertEqual(expandedSizes.value as? String, originalSwitch)
            XCTAssertEqual(settings.sliders.firstMatch.normalizedSliderPosition,
                           originalPosition, accuracy: 0.01)
            print("SYSTEM SIZE RESTORED switch=\(String(describing: expandedSizes.value)) slider=\(settings.sliders.firstMatch.normalizedSliderPosition) expectedSwitch=\(originalSwitch) expectedSlider=\(originalPosition)")
            attachScreenshot("system-settings-restored-original-size")
        }

        XCTAssertTrue(setSystemSwitch(expandedSizes, to: "0", in: settings))
        XCTAssertTrue(setSystemSlider(in: settings, to: 0.5))
        launch()
        try verifyRenderedTextAndNavigation(category: .large)
        settings.activate()
        XCTAssertTrue(setSystemSwitch(expandedSizes, to: "1", in: settings))
        XCTAssertTrue(setSystemSlider(in: settings, to: 1))
        attachScreenshot("system-settings-maximum-accessibility-size")
        XCTAssertTrue(app.state == .runningBackground || app.state == .runningBackgroundSuspended,
                      "RunBuoy must remain alive during the system setting change")
        app.activate()
        try verifyRenderedTextAndNavigation(category: .accessibilityExtraExtraExtraLarge)
        settings.activate()
        XCTAssertTrue(setSystemSwitch(expandedSizes, to: "0", in: settings))
        XCTAssertTrue(setSystemSlider(in: settings, to: 0.5))
        attachScreenshot("system-settings-restored-default-size")
        XCTAssertTrue(app.state == .runningBackground || app.state == .runningBackgroundSuspended)
        app.activate()
        try verifyRenderedTextAndNavigation(category: .large)
        print("RUNTIME FONT SWITCH LARGE -> ACCESSIBILITY XXXL -> LARGE PASSED WITHOUT RELAUNCH")
    }

    private func setSystemSwitch(_ control: XCUIElement, to value: String,
                                 in settings: XCUIApplication) -> Bool {
        guard control.waitForExistence(timeout: 5) else { return false }
        print("SYSTEM SWITCH before=\(String(describing: control.value)) target=\(value) frame=\(control.frame)")
        if control.value as? String != value {
            // Settings exposes the whole row as a switch. Its center can hit
            // the label without changing the right-hand toggle.
            control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", value), object: control
        )
        let matched = XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
        print("SYSTEM SWITCH after=\(String(describing: control.value))")
        return matched
    }

    private func setSystemSlider(in settings: XCUIApplication, to target: CGFloat) -> Bool {
        guard settings.sliders.firstMatch.waitForExistence(timeout: 5) else { return false }
        for attempt in 0..<4 {
            // Re-query after changing the switch: the slider now has 12 stops,
            // whereas the standard range has 7. Never assume adjust succeeded.
            let slider = settings.sliders.firstMatch
            let before = slider.normalizedSliderPosition
            print("SYSTEM SLIDER attempt=\(attempt) before=\(before) target=\(target) value=\(String(describing: slider.value)) frame=\(slider.frame)")
            if abs(before - target) <= 0.01 { return true }
            if attempt == 0 {
                slider.adjust(toNormalizedSliderPosition: target)
            } else {
                // iOS 26.5's adjust can stop at 6/11 despite a requested 1.0.
                // Drag the visible thumb, then require the same strict readback.
                let start = slider.coordinate(withNormalizedOffset: CGVector(dx: before, dy: 0.5))
                let end = slider.coordinate(withNormalizedOffset: CGVector(
                    dx: min(0.99, max(0.01, target)), dy: 0.5
                ))
                start.press(forDuration: 0.1, thenDragTo: end)
            }
            let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                abs(settings.sliders.firstMatch.normalizedSliderPosition - target) <= 0.01
            }, object: nil)
            let matched = XCTWaiter.wait(for: [expectation], timeout: 2) == .completed
            print("SYSTEM SLIDER readback=\(settings.sliders.firstMatch.normalizedSliderPosition) target=\(target) matched=\(matched)")
            if matched { return true }
        }
        let attachment = XCTAttachment(string: settings.debugDescription)
        attachment.name = "System slider failed readback"
        attachment.lifetime = .keepAlways
        add(attachment)
        attachScreenshot("system-slider-failed-readback")
        return false
    }

    private func tapSettingsEntry(_ label: String, in settings: XCUIApplication) {
        let entry = settings.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@ OR identifier == %@", label, label)
        ).firstMatch
        for _ in 0..<10 {
            if entry.exists && entry.isHittable {
                entry.tap()
                return
            }
            settings.swipeUp()
        }
        let attachment = XCTAttachment(string: settings.debugDescription)
        attachment.name = "System text-size settings hierarchy"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTFail("System settings entry not reachable: \(label)")
    }

    func testRenderedGlyphsAndMachineNavigationAtAllSystemSizes() throws {
        for category in Self.categories {
            launch(category: category)
            try verifyRenderedTextAndNavigation(category: category)
        }
    }

    func testRenderedGlyphsAtLargestAccessibilitySize() throws {
        let category = UIContentSizeCategory.accessibilityExtraExtraExtraLarge
        launch(category: category)
        try verifyRenderedTextAndNavigation(category: category)
    }

    func testHistoryCompletedQuantityRemainsVisibleAtLargeType() throws {
        for category in [UIContentSizeCategory.large, .accessibilityExtraExtraExtraLarge] {
            launch(category: category, scenario: "showcaseEnglish")
            tapTab("History")
            let summary = element("run.progress.summary.018f0d8a-8c0a-7000-8000-000000000201")
            ensureFullyVisible([summary])
            attachScreenshot("history-quantity-\(category.rawValue)")
            let image = summary.screenshot().image
            attachImage(image, "history-quantity-node-\(category.rawValue)")
            let rendered = try recognizedText(in: image)
            print("HISTORY RENDERED \(category.rawValue): \(rendered)")
            let normalized = Self.normalized(rendered)
            XCTAssertTrue(normalized.contains("24002400") || normalized.contains("24k24k"),
                          "Completed quantity missing from actual pixels: \(rendered)")
        }
    }

    private func verifyRenderedTextAndNavigation(category: UIContentSizeCategory) throws {
        print("GLYPH CATEGORY \(category.rawValue)")
        tapTab("Active")
        let hint = app.staticTexts["activeRuns.confirmationHint"]
        ensureFullyVisible([hint])
        try verifyGlyph(hint, character: "C", style: .caption1, category: category,
                        expectedText: "Computer confirmation times are shown on each task.")
        try verifyCompleteText([hint.label], in: hint.screenshot().image)
        if category == .large || category == .accessibilityExtraExtraExtraLarge {
            attachScreenshot("active-glyphs-\(category.rawValue)")
        }
        tapTab("Settings")
        let title = app.staticTexts["settings.machines.title"]
        let count = app.staticTexts["settings.machines.count"]
        let suffix = app.staticTexts["settings.machines.suffix"]
        let machineRow = element("settings.machines")
        ensureFullyVisible([machineRow, title, count, suffix])
        try verifyGlyph(title, character: "M", style: .body, category: category, expectedText: "Machines")
        try verifyGlyph(count, character: "2", style: .body, category: category, expectedText: "2")
        try verifyGlyph(suffix, character: "p", style: .body, category: category, expectedText: "paired")
        // SwiftUI's flowing Label can draw the second line left of the text's AX frame.
        // Use the complete, fully visible row for text completeness, and the first
        // glyph crop above only for glyph dimensions.
        let rowImage = machineRow.screenshot().image
        attachImage(rowImage, "complete-machines-row-\(category.rawValue)")
        try verifyCompleteText(["Machines", "2", "paired"], in: rowImage)
        if category == .large || category == .accessibilityExtraExtraExtraLarge {
            attachScreenshot("settings-glyphs-\(category.rawValue)")
        }
        element("settings.machines").tap()
        XCTAssertTrue(element("screen.machines").waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element("screen.settings").waitForExistence(timeout: 5))
        ensureFullyVisible([title, count, suffix])
        print("MACHINE NAVIGATION ROUND TRIP PASSED \(category.rawValue)")
    }

    private func verifyGlyph(_ node: XCUIElement, character: String, style: UIFont.TextStyle,
                             category: UIContentSizeCategory, expectedText: String) throws {
        XCTAssertEqual(node.label, expectedText)
        XCTAssertTrue(visibleContentRect.contains(node.frame))
        let screenshot = node.screenshot().image
        attachImage(screenshot, "glyph-\(node.identifier)-\(category.rawValue)")
        let cgImage = try XCTUnwrap(screenshot.cgImage)
        // XCUI crops fractional point bounds to whole device pixels.
        let measuredScale = CGFloat(cgImage.width) / node.frame.width
        let scale = measuredScale.rounded()
        XCTAssertLessThanOrEqual(abs(CGFloat(cgImage.width) - node.frame.width * scale), 2,
                                 "Screenshot crop differs by more than pixel rounding")
        let actual = try GlyphEvidence.rendered(screenshot, scale: scale)
        let expected = try GlyphEvidence.reference(character: character, style: style, category: category, scale: scale)
        let referenceFont = UIFont.preferredFont(
            forTextStyle: style, compatibleWith: UITraitCollection(preferredContentSizeCategory: category)
        )
        let report = "\(node.identifier) \(category.rawValue) actual=\(actual.size) expected=\(expected.size) bounds=\(actual.pixelBounds) scale=\(scale) AXFrame=\(node.frame) referenceFont=\(referenceFont.fontName) referencePointSize=\(referenceFont.pointSize) referenceLineHeight=\(referenceFont.lineHeight)"
        print("GLYPH \(report)")
        let attachment = XCTAttachment(string: report)
        attachment.name = "Rendered glyph measurement"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(actual.size.height, expected.size.height, accuracy: max(1, expected.size.height * 0.08), report)
        XCTAssertEqual(actual.size.width, expected.size.width, accuracy: max(1, expected.size.width * 0.10), report)
    }

    private func verifyCompleteText(_ expected: [String], in image: UIImage) throws {
        let recognized = try recognizedText(in: image)
        print("COMPLETE TEXT OCR: \(recognized)")
        for text in expected {
            XCTAssertTrue(Self.normalized(recognized).contains(Self.normalized(text)),
                          "Full text absent from rendered pixels: \(text); OCR: \(recognized)")
        }
    }

    private func ensureFullyVisible(_ nodes: [XCUIElement]) {
        for _ in 0..<12 {
            let visible = visibleContentRect
            if nodes.allSatisfy({ $0.exists && !$0.frame.isEmpty && visible.contains($0.frame) && $0.isHittable }) { return }
            let existing = nodes.filter(\.exists)
            let union = existing.reduce(CGRect.null) { $0.union($1.frame) }
            let moveDown = !union.isNull && union.minY < visible.minY
            let direction: CGFloat = moveDown ? -1 : 1
            let start = app.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: visible.midX, dy: visible.midY + direction * 90))
            let end = app.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: visible.midX, dy: visible.midY - direction * 90))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        attachScreenshot("full-visibility-failure")
        for node in nodes {
            XCTAssertTrue(node.exists && !node.frame.isEmpty && visibleContentRect.contains(node.frame) && node.isHittable,
                          "Not fully visible: \(node.identifier), frame \(node.frame), viewport \(visibleContentRect)")
        }
    }

    private var visibleContentRect: CGRect {
        let window = app.windows.firstMatch.frame
        let navigation = app.navigationBars.firstMatch
        let tabs = app.tabBars.firstMatch
        var top = navigation.exists ? navigation.frame.maxY : window.minY
        if app.tabBars.buttons["History"].isSelected {
            let filters = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history.filter."))
            let visibleFilters = filters.allElementsBoundByIndex.filter { $0.frame.intersects(window) }
            top = max(top, visibleFilters.map { $0.frame.maxY }.max() ?? top)
        }
        let bottom = tabs.exists ? tabs.frame.minY : window.maxY
        return CGRect(x: window.minX, y: top + 2, width: window.width, height: bottom - top - 4)
    }

    private func tapTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func recognizedText(in image: UIImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: XCTUnwrap(image.cgImage)).perform([request])
        let lines = (request.results ?? []).sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        print("OCR LINE EVIDENCE count=\(lines.count) " + lines.map {
            "text=\($0.topCandidates(1).first?.string ?? "") bounds=\($0.boundingBox)"
        }.joined(separator: "; "))
        return lines.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
    }

    private static func normalized(_ text: String) -> String {
        // Vision occasionally reads the isolated line "Ma-" with a Cyrillic M.
        // Transliterate OCR output before removing line breaks and hyphenation;
        // the separate pixel measurement still verifies the rendered M itself.
        let latin = text.applyingTransform(.toLatin, reverse: false) ?? text
        return String(latin.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }

    private func attachImage(_ image: UIImage, _ name: String) {
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private static let categories: [UIContentSizeCategory] = [
        .extraSmall, .small, .medium, .large, .extraLarge, .extraExtraLarge,
        .extraExtraExtraLarge, .accessibilityMedium, .accessibilityLarge,
        .accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge
    ]

    private func launch(category: UIContentSizeCategory? = nil, scenario: String = "loaded", extraArguments: [String] = []) {
        if app.state != .notRunning { app.terminate() }
        app.launchArguments = [
            "-runbuoy-ui-testing", "-runbuoy-ui-scenario", scenario, "-runbuoy-ui-reset-state",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ] + extraArguments
        if let category {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", category.rawValue]
        }
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    private func recordUnfilteredAudit() throws {
        continueAfterFailure = true
        try app.performAccessibilityAudit { issue in
            let node = issue.element
            let details = """
            OS: \(ProcessInfo.processInfo.operatingSystemVersionString)
            type: \(issue.auditType.rawValue)
            compact: \(issue.compactDescription)
            detailed: \(issue.detailedDescription)
            identifier: \(node?.identifier ?? "nil")
            label: \(node?.label ?? "nil")
            elementTypeRawValue: \(String(describing: node?.elementType.rawValue))
            isStaticText: \(node?.elementType == .staticText)
            frame: \(String(describing: node?.frame))
            intersectsNavigationBar: \(node.map { self.app.navigationBars.firstMatch.exists && $0.frame.intersects(self.app.navigationBars.firstMatch.frame) } ?? false)
            hittable: \(node?.isHittable ?? false)
            """
            print("UNFILTERED AUDIT\n\(details)")
            let attachment = XCTAttachment(string: details)
            attachment.name = "Unfiltered audit signature"
            attachment.lifetime = .keepAlways
            self.add(attachment)
            return false
        }
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
