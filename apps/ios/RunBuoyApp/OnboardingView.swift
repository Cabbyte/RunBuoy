import SwiftUI
import UIKit

private enum OnboardingSheet: String, Identifiable {
    case scanner

    var id: String { rawValue }
}

struct OnboardingView: View {
    @Environment(RunBuoyStore.self) private var store
    @Environment(AppRouter.self) private var router
    let notificationCoordinator: NotificationCoordinator
    let bypassesSystemPermissions: Bool
    let onFinished: () -> Void

    @State private var page = 0
    @State private var sheet: OnboardingSheet?
    @State private var selectedRegion: RunBuoyRegion? = AppConfiguration.selectedRegion()
    @State private var pairingCode: PairingCode?
    @State private var rawPairingCode = ""
    @State private var pairingSucceeded = false
    @State private var pairingFailed = false
    @State private var errorMessage: String?
    @State private var isWorking = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            Group {
                if pairingSucceeded {
                    OnboardingOutcomePage(
                        symbol: "checkmark.circle.fill",
                        title: "onboarding.pairing_success_title",
                        bodyText: "onboarding.pairing_success_body",
                        color: .green
                    )
                    .accessibilityIdentifier("onboarding.pairing-success")
                } else if pairingFailed {
                    OnboardingOutcomePage(
                        symbol: "exclamationmark.triangle.fill",
                        title: "onboarding.pairing_failed_title",
                        bodyText: "onboarding.pairing_failed_body",
                        color: .orange
                    )
                    .accessibilityIdentifier("onboarding.pairing-failure")
                } else {
                    onboardingPages
                }
            }
            actionArea
        }
        .background(Color(uiColor: .systemGroupedBackground))
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

    private var onboardingPages: some View {
        TabView(selection: $page) {
            ProductIntroduction()
                .tag(0)
            RegionIntroduction(selection: $selectedRegion)
                .tag(1)
            PermissionIntroduction()
                .tag(2)
            PairingIntroduction(
                rawCode: $rawPairingCode,
                onValidate: validateEnteredPairingCode
            )
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(reduceMotion ? nil : .smooth, value: page)
        .overlay(alignment: .bottom) {
            HStack(spacing: 7) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.accentColor : Color.secondary.opacity(0.24))
                        .frame(width: index == page ? 24 : 7, height: 7)
                }
            }
            .accessibilityHidden(true)
            .padding(.bottom, 8)
        }
    }

    private var actionArea: some View {
        VStack(spacing: 8) {
            if page == 3, let pairingCode, !pairingSucceeded, !pairingFailed {
                PairingIdentityCard(code: pairingCode)
            }
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
            .disabled(isWorking || (page == 1 && selectedRegion == nil))
            .accessibilityIdentifier("onboarding.primary-action")

            if !pairingSucceeded, !pairingFailed {
                if page == 2 {
                    Button("onboarding.not_now") {
                        Task { await completePermissionStep(requestPermission: false) }
                    }
                    .disabled(isWorking)
                } else if page == 3 {
                    Button("onboarding.set_up_later", action: finishWithoutPairing)
                        .disabled(isWorking)
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
        case 0: "onboarding.continue"
        case 1: "onboarding.confirm_region"
        case 2: "onboarding.enable_notifications"
        default:
            pairingCode == nil ? "onboarding.scan_code" : "onboarding.confirm_machine"
        }
    }

    private var primarySymbol: String {
        if pairingSucceeded { return "arrow.right" }
        if pairingFailed { return "arrow.clockwise" }
        return switch page {
        case 0: "arrow.right"
        case 1: "lock.shield"
        case 2: "bell.badge"
        default: pairingCode == nil ? "qrcode.viewfinder" : "checkmark.shield"
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
        case 0:
            page = 1
        case 1:
            guard let selectedRegion else { return }
            do {
                if pairingCode?.region != selectedRegion {
                    pairingCode = nil
                }
                try AppConfiguration.selectRegion(selectedRegion)
                page = 2
            } catch {
                errorMessage = error.localizedDescription
            }
        case 2:
            await completePermissionStep(requestPermission: true)
        default:
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
            page = 3
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
            symbol: "water.waves",
            kicker: "onboarding.step_1_of_4",
            title: "onboarding.welcome",
            bodyText: "onboarding.welcome_body"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                BoundaryRow(symbol: "waveform.path.ecg", title: "onboarding.benefit_live")
                BoundaryRow(symbol: "bell.badge", title: "onboarding.benefit_notifications")
                BoundaryRow(symbol: "lock.shield", title: "onboarding.benefit_private")
            }
        }
        .accessibilityIdentifier("onboarding.page.product")
    }
}

private struct PermissionIntroduction: View {
    var body: some View {
        OnboardingPage(
            symbol: "bell.badge.fill",
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
            symbol: "globe.asia.australia.fill",
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
    let onValidate: () -> Void

    var body: some View {
        OnboardingPage(
            symbol: "qrcode.viewfinder",
            kicker: "onboarding.step_4_of_4",
            title: "onboarding.pair",
            bodyText: "onboarding.pair_body"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Label("onboarding.one_time_code", systemImage: "clock.badge.checkmark")
                    .font(.headline)
                TextField("pairing.code_placeholder", text: $rawCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(onValidate)
                    .accessibilityIdentifier("onboarding.pairing-code")
                Button("pairing.continue", action: onValidate)
                    .disabled(rawCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .accessibilityIdentifier("onboarding.page.pairing")
    }
}

private struct OnboardingPage<Content: View>: View {
    let symbol: String
    let kicker: LocalizedStringKey
    let title: LocalizedStringKey
    let bodyText: LocalizedStringKey
    let content: Content

    init(
        symbol: String,
        kicker: LocalizedStringKey,
        title: LocalizedStringKey,
        bodyText: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) {
        self.symbol = symbol
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
                Image(systemName: symbol)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 82, height: 82)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
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
            .padding(.top, 24)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct OnboardingOutcomePage: View {
    let symbol: String
    let title: LocalizedStringKey
    let bodyText: LocalizedStringKey
    let color: Color

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
                .foregroundStyle(color)
        } description: {
            Text(bodyText)
        }
        .frame(maxWidth: 520, maxHeight: .infinity)
        .padding(24)
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
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
