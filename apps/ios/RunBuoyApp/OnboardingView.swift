import SwiftUI
import UIKit

enum OnboardingStep: Int, CaseIterable, Hashable {
    case welcome
    case region
    case notifications
    case pairMac

    var next: Self? {
        Self(rawValue: rawValue + 1)
    }
}

private enum OnboardingSheet: String, Identifiable {
    case scanner

    var id: String { rawValue }
}

struct OnboardingView: View {
    @Environment(RunBuoyStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let notificationCoordinator: NotificationCoordinator
    let bypassesSystemPermissions: Bool
    let onFinished: () -> Void

    @State private var page: OnboardingStep = .welcome
    @State private var sheet: OnboardingSheet?
    @State private var selectedRegion: RunBuoyRegion? = AppConfiguration.selectedRegion()
    @State private var pairingCode: PairingCode?
    @State private var rawPairingCode = ""
    @State private var pairingSucceeded = false
    @State private var pairingFailed = false
    @State private var errorMessage: String?
    @State private var isWorking = false

    init(
        notificationCoordinator: NotificationCoordinator,
        bypassesSystemPermissions: Bool = false,
        onFinished: @escaping () -> Void
    ) {
        self.notificationCoordinator = notificationCoordinator
        self.bypassesSystemPermissions = bypassesSystemPermissions
        self.onFinished = onFinished
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingPageControl(selection: page)

            Group {
                if pairingSucceeded {
                    OnboardingOutcomePage(
                        symbol: "checkmark.circle.fill",
                        title: "onboarding.pairing_success_title",
                        detail: pairingCode?.machineDisplayName,
                        tone: .success
                    )
                    .accessibilityIdentifier("onboarding.pairing-success")
                } else if pairingFailed {
                    OnboardingOutcomePage(
                        symbol: "exclamationmark.triangle.fill",
                        title: "onboarding.pairing_failed_title",
                        detail: errorMessage,
                        tone: .warning
                    )
                    .accessibilityIdentifier("onboarding.pairing-failure")
                } else {
                    onboardingPages
                }
            }

            actionArea
        }
        .runBuoyCanvas()
        .sheet(item: $sheet) { _ in
            ScannerSheet(onCode: receiveScannedCode)
        }
        .onAppear {
            receivePendingPairingCode(router.pendingPairingCode)
        }
        .onChange(of: router.pendingPairingCode) { _, code in
            receivePendingPairingCode(code)
        }
    }

    @ViewBuilder
    private var onboardingPages: some View {
        if reduceMotion {
            pageContent(page)
        } else {
            TabView(selection: $page) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    pageContent(step)
                        .tag(step)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth, value: page)
        }
    }

    @ViewBuilder
    private func pageContent(_ step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            ProductIntroduction()
        case .region:
            RegionIntroduction(selection: $selectedRegion)
        case .notifications:
            PermissionIntroduction()
        case .pairMac:
            PairingIntroduction(
                rawCode: $rawPairingCode,
                pairingCode: pairingCode,
                onValidate: validateEnteredPairingCode
            )
        }
    }

    private var actionArea: some View {
        VStack(spacing: 8) {
            if let errorMessage, !pairingFailed {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Button(action: advanceAction) {
                if isWorking {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label(primaryTitle, systemImage: primarySymbol)
                        .frame(maxWidth: .infinity)
                }
            }
            .runBuoyProminentButtonStyle()
            .controlSize(.large)
            .disabled(isWorking || (page == .region && selectedRegion == nil))
            .accessibilityIdentifier("onboarding.primary-action")

            if pairingFailed {
                Button("common.cancel", action: finishWithoutPairing)
                    .disabled(isWorking)
            } else if !pairingSucceeded {
                switch page {
                case .notifications:
                    Button("onboarding.not_now") {
                        Task { await completePermissionStep(requestPermission: false) }
                    }
                    .disabled(isWorking)
                case .pairMac:
                    Button("onboarding.set_up_later", action: finishWithoutPairing)
                        .disabled(isWorking)
                default:
                    EmptyView()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.bar)
    }

    private var primaryTitle: LocalizedStringKey {
        if pairingSucceeded { return "onboarding.finish" }
        if pairingFailed { return "common.try_again" }
        return switch page {
        case .welcome: "onboarding.continue"
        case .region: "onboarding.confirm_region"
        case .notifications: "onboarding.enable_notifications"
        case .pairMac:
            pairingCode == nil ? "onboarding.scan_code" : "onboarding.confirm_machine"
        }
    }

    private var primarySymbol: String {
        if pairingSucceeded { return "arrow.right" }
        if pairingFailed { return "arrow.clockwise" }
        return switch page {
        case .welcome: "arrow.right"
        case .region: "lock.shield"
        case .notifications: "bell.badge"
        case .pairMac: pairingCode == nil ? "qrcode.viewfinder" : "checkmark.shield"
        }
    }

    private func advanceAction() {
        Task { await advance() }
    }

    private func receiveScannedCode(_ value: String) {
        do {
            let decoded = try PairingCode.decode(value)
            try decoded.requireSelectedRegion()
            pairingCode = decoded
            rawPairingCode = value
            pairingFailed = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func validateEnteredPairingCode() {
        receiveScannedCode(rawPairingCode.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func advance() async {
        errorMessage = nil
        if pairingSucceeded {
            finishOnboarding()
            return
        }
        if pairingFailed {
            pairingFailed = false
            pairingCode = nil
            rawPairingCode = ""
            return
        }

        switch page {
        case .welcome, .notifications:
            if page == .notifications {
                await completePermissionStep(requestPermission: true)
            } else if let next = page.next {
                page = next
            }
        case .region:
            guard let selectedRegion else { return }
            do {
                if pairingCode?.region != selectedRegion {
                    pairingCode = nil
                }
                try AppConfiguration.selectRegion(selectedRegion)
                page = .notifications
            } catch {
                errorMessage = error.localizedDescription
            }
        case .pairMac:
            guard let pairingCode else {
                sheet = .scanner
                return
            }
            isWorking = true
            do {
                try await store.claim(pairingCode)
                pairingSucceeded = true
            } catch {
                errorMessage = error.localizedDescription
                pairingFailed = true
            }
            isWorking = false
        }
    }

    private func completePermissionStep(requestPermission: Bool) async {
        isWorking = true
        errorMessage = nil
        do {
            if !bypassesSystemPermissions, requestPermission {
                _ = try await notificationCoordinator.requestAuthorization()
            }
            _ = try await store.bootstrapDevice()
            if !bypassesSystemPermissions, requestPermission {
                UIApplication.shared.registerForRemoteNotifications()
            }
            page = .pairMac
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    private func finishWithoutPairing() {
        finishOnboarding()
    }

    private func finishOnboarding() {
        router.clearPendingPairing()
        router.selectedTab = .activeRuns
        onFinished()
    }

    private func receivePendingPairingCode(_ code: PairingCode?) {
        guard let code else { return }
        guard AppConfiguration.selectedRegion() != nil else {
            pairingCode = code
            errorMessage = nil
            return
        }
        do {
            try code.requireSelectedRegion()
            pairingCode = code
            errorMessage = nil
        } catch {
            pairingCode = nil
            errorMessage = error.localizedDescription
        }
    }
}

private struct ProductIntroduction: View {
    var body: some View {
        OnboardingPage(
            hero: .signalBuoy,
            kicker: "onboarding.step_1_of_4",
            title: "onboarding.hero_title",
            bodyText: "onboarding.hero_body"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                BoundaryRow(symbol: "checkmark.seal.fill", title: "onboarding.benefit_confirmed")
                BoundaryRow(symbol: "iphone", title: "onboarding.benefit_native")
                BoundaryRow(symbol: "lock.shield.fill", title: "onboarding.benefit_privacy")
            }
        }
        .accessibilityIdentifier("onboarding.page.product")
    }
}

private struct PermissionIntroduction: View {
    var body: some View {
        OnboardingPage(
            hero: .symbol("bell.badge.fill"),
            kicker: "onboarding.step_3_of_4",
            title: "onboarding.notifications",
            bodyText: "onboarding.notifications_body"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "water.waves")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("onboarding.notification_preview_title")
                            .font(.headline)
                        Text("onboarding.notification_preview_body")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Text("onboarding.notification_preview_time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                BoundaryRow(symbol: "waveform.path.ecg", title: "onboarding.live_updates")
                BoundaryRow(symbol: "lock.fill", title: "onboarding.tokens_private")
            }
        }
        .accessibilityIdentifier("onboarding.page.permissions")
    }
}

private struct RegionIntroduction: View {
    @Binding var selection: RunBuoyRegion?

    var body: some View {
        OnboardingPage(
            hero: .symbol("globe.asia.australia.fill"),
            kicker: "onboarding.step_2_of_4",
            title: "onboarding.region",
            bodyText: "onboarding.region_body"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Picker("onboarding.region", selection: $selection) {
                    ForEach(AppConfiguration.hostedRegions) { region in
                        Text(region.displayName)
                            .tag(Optional(region))
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("onboarding.region-picker")

                if let selection {
                    Label(selection.detail, systemImage: "server.rack")
                        .font(.headline)
                        .accessibilityIdentifier("onboarding.region-detail")
                }

                Label("onboarding.region_locked", systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("onboarding.page.region")
    }
}

private struct PairingIntroduction: View {
    @Binding var rawCode: String
    let pairingCode: PairingCode?
    let onValidate: () -> Void

    var body: some View {
        OnboardingPage(
            hero: .symbol("qrcode.viewfinder"),
            kicker: "onboarding.step_4_of_4",
            title: "onboarding.pair",
            bodyText: "onboarding.pair_body"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                if let pairingCode {
                    PairingIdentityCard(code: pairingCode)
                } else {
                    Label("onboarding.one_time_code", systemImage: "clock.badge.checkmark")
                        .font(.headline)

                    DisclosureGroup("pairing.enter_code") {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("pairing.code_placeholder", text: $rawCode)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.asciiCapable)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .onSubmit(onValidate)
                                .accessibilityIdentifier("onboarding.pairing-code")
                            Button("pairing.continue", action: onValidate)
                                .buttonStyle(.bordered)
                                .disabled(rawCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.top, 10)
                    }
                }
            }
        }
        .accessibilityIdentifier("onboarding.page.pairing")
    }
}

private enum OnboardingHero {
    case signalBuoy
    case symbol(String)
}

private struct OnboardingPage<Content: View>: View {
    let hero: OnboardingHero
    let kicker: LocalizedStringKey
    let title: LocalizedStringKey
    let bodyText: LocalizedStringKey
    let content: Content

    init(
        hero: OnboardingHero,
        kicker: LocalizedStringKey,
        title: LocalizedStringKey,
        bodyText: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) {
        self.hero = hero
        self.kicker = kicker
        self.title = title
        self.bodyText = bodyText
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(kicker)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                OnboardingHeroView(hero: hero)
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(bodyText)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                content
                    .padding(18)
                    .frame(maxWidth: 420, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct OnboardingHeroView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let hero: OnboardingHero

    var body: some View {
        switch hero {
        case .signalBuoy:
            ZStack {
                Circle()
                    .trim(from: 0.09, to: 0.91)
                    .stroke(
                        LinearGradient(
                            colors: [theme.liveStart, theme.liveEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(theme.status(.live))
            }
            .frame(width: 160, height: 160)
            .accessibilityHidden(true)
        case .symbol(let symbol):
            Image(systemName: symbol)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 82, height: 82)
                .background(theme.badgeBackground(.live), in: Circle())
                .accessibilityHidden(true)
        }
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

private struct OnboardingPageControl: View {
    let selection: OnboardingStep

    var body: some View {
        HStack(spacing: 7) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step == selection ? Color.accentColor : Color.secondary.opacity(0.24))
                    .frame(width: step == selection ? 24 : 7, height: 7)
            }
        }
        .accessibilityHidden(true)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

private struct OnboardingOutcomePage: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let symbol: String
    let title: LocalizedStringKey
    let detail: String?
    let tone: RunBuoyTone

    var body: some View {
        ScrollView {
            ContentUnavailableView {
                Label(title, systemImage: symbol)
                    .foregroundStyle(theme.status(tone))
            } description: {
                if let detail, !detail.isEmpty {
                    Text(detail)
                }
            }
            .frame(maxWidth: 520, minHeight: 360)
            .padding(24)
        }
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

private struct BoundaryRow: View {
    let symbol: String
    let title: LocalizedStringKey

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .accessibilityElement(children: .combine)
    }
}

private struct PairingIdentityCard: View {
    let code: PairingCode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("pairing.confirm_identity", systemImage: "checkmark.shield")
                .font(.headline)
            Text(code.machineDisplayName)
                .font(.title3.bold())
            if let platform = code.platform {
                Text(platform)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("onboarding.pairing-identity")
    }
}

#Preview("English") {
    OnboardingView(notificationCoordinator: NotificationCoordinator(), onFinished: {})
        .environment(PreviewFixtures.store())
        .environment(AppRouter())
}

#Preview("简体中文 · 大字体") {
    OnboardingView(notificationCoordinator: NotificationCoordinator(), onFinished: {})
        .environment(PreviewFixtures.store())
        .environment(AppRouter())
        .environment(\.locale, Locale(identifier: "zh-Hans"))
        .environment(\.dynamicTypeSize, .accessibility3)
}
