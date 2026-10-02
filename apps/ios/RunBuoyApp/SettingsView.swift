import ActivityKit
import LocalAuthentication
import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(RunBuoyStore.self) private var store
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("runbuoy.notifications-enabled") private var notificationsEnabled = true
    @AppStorage("runbuoy.live-activities-enabled") private var liveActivitiesEnabled = true
    @AppStorage("runbuoy.safe-messages-enabled") private var safeMessagesEnabled = true
    @State private var notificationsSystemDenied = false

    var body: some View {
        Form {
            connectionSummarySection
            connectionSection
            preferencesSection
            productSection
            aboutSection
        }
        .runBuoyBottomScrollEdgeStyle()
        .accessibilityIdentifier("screen.settings")
        .navigationTitle("settings.title")
        .onChange(of: notificationsEnabled) { _, _ in savePreferences() }
        .onChange(of: liveActivitiesEnabled) { _, _ in savePreferences() }
        .onChange(of: safeMessagesEnabled) { _, _ in savePreferences() }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await refreshNotificationAuthorization()
        }
    }

    private var connectionSummarySection: some View {
        Section {
            SettingsConnectionSummary(
                state: SettingsConnectionState.resolve(
                    loadState: store.state,
                    isRefreshing: store.isRefreshing
                ),
                machineCount: store.machines.count,
                regionName: selectedRegionName,
                serverAddress: AppConfiguration.displayAddress(
                    for: AppConfiguration.live.apiBaseURL
                ),
                lastConfirmedAt: store.lastRefreshAt
            )
        }
    }

    private var connectionSection: some View {
        Section {
            LabeledContent {
                Text(selectedRegionName)
                    .runBuoySecondaryText()
            } label: {
                Label("settings.region", systemImage: "globe")
                    .foregroundStyle(.primary)
            }

            LabeledContent {
                Text(AppConfiguration.displayAddress(for: AppConfiguration.live.apiBaseURL))
                    .runBuoySecondaryText()
                    .lineLimit(1)
                    .accessibilityLabel(
                        serverAccessibilityLabel(
                            AppConfiguration.displayAddress(for: AppConfiguration.live.apiBaseURL)
                        )
                    )
            } label: {
                Label("settings.server", systemImage: "server.rack")
                    .foregroundStyle(.primary)
            }

            NavigationLink(value: AppRoute.pluginConnections) {
                Label("plugin.title", systemImage: "rectangle.connected.to.line.below")
                    .foregroundStyle(.primary)
            }
            .accessibilityIdentifier("settings.pluginConnections")

            NavigationLink(value: AppRoute.machines) {
                LabeledContent {
                    HStack(spacing: 4) {
                        Text(store.machines.count, format: .number)
                            .accessibilityIdentifier("settings.machines.count")
                        Text("settings.machines_paired_suffix")
                            .accessibilityIdentifier("settings.machines.suffix")
                    }
                    .runBuoySecondaryText()
                } label: {
                    Label {
                        Text("settings.machines")
                            .accessibilityIdentifier("settings.machines.title")
                    } icon: {
                        Image(systemName: "desktopcomputer")
                    }
                    .labelStyle(SettingsMachinesLabelStyle())
                    .foregroundStyle(.primary)
                }
                .labeledContentStyle(SettingsMachinesContentStyle())
            }
            .accessibilityIdentifier("settings.machines")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.fill")
                    .accessibilityHidden(true)
                Text("settings.region_locked")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.footnote)
            .foregroundStyle(.primary)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("settings.regionLock")
        } header: {
            Text("settings.connections")
                .runBuoySecondaryText()
        }
    }

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                Label("settings.notifications_enabled", systemImage: "bell.badge")
                    .foregroundStyle(.primary)
            }
            .disabled(notificationsSystemDenied)
            .accessibilityIdentifier("settings.notifications")

            Toggle(isOn: $liveActivitiesEnabled) {
                Label("settings.live_activities", systemImage: "shippingbox.fill")
                    .foregroundStyle(.primary)
            }
            .disabled(!liveActivitiesAvailable)
            .accessibilityIdentifier("settings.liveActivities")

            Toggle(isOn: $safeMessagesEnabled) {
                Label("settings.safe_messages", systemImage: "lock.shield.fill")
                    .foregroundStyle(.primary)
            }
            .accessibilityIdentifier("settings.safeMessages")

            if !liveActivitiesAvailable {
                Label(
                    "settings.live_activities_system_disabled",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.footnote)
                .runBuoySecondaryText()
            }

            if notificationsSystemDenied {
                Label("settings.notifications_system_disabled", systemImage: "bell.slash")
                    .font(.footnote)
                    .runBuoySecondaryText()
            }

            if notificationsSystemDenied || !liveActivitiesAvailable {
                Button("settings.open_system_settings", action: openSystemSettings)
                    .accessibilityIdentifier("settings.openSystemSettings")
            }
        } header: {
            Text("settings.notifications")
                .runBuoySecondaryText()
        }
    }

    private func serverAccessibilityLabel(_ address: String) -> String {
        String(
            format: String(localized: "settings.server_accessibility_value"),
            address
        )
    }

    private var productSection: some View {
        Section {
            NavigationLink(value: AppRoute.capabilityDemo) {
                Label("demo.settings_entry", systemImage: "sparkles")
                    .foregroundStyle(.primary)
            }
            .accessibilityIdentifier("settings.capabilityDemo")

            NavigationLink(value: AppRoute.advancedData) {
                Label("settings.advanced_data", systemImage: "gearshape.fill")
                    .foregroundStyle(.primary)
            }
            .accessibilityIdentifier("settings.advancedData")
        } header: {
            Text("settings.product")
                .runBuoySecondaryText()
        }
    }

    private var aboutSection: some View {
        Section {
            settingsLink(
                title: "settings.website",
                symbol: "globe",
                destination: RunBuoyLinks.website
            )
            settingsLink(
                title: "settings.privacy",
                symbol: "lock.shield.fill",
                destination: RunBuoyLinks.privacy
            )
            settingsLink(
                title: "settings.support",
                symbol: "info.circle",
                destination: RunBuoyLinks.support
            )
            settingsLink(
                title: "settings.private_deployment",
                symbol: "server.rack",
                destination: RunBuoyLinks.privateDeployment
            )
        } header: {
            Text("settings.about")
                .runBuoySecondaryText()
        }
    }

    private func settingsLink(
        title: LocalizedStringKey,
        symbol: String,
        destination: URL
    ) -> some View {
        Link(destination: destination) {
            Label(title, systemImage: symbol)
                .foregroundStyle(.primary)
        }
        .tint(.primary)
    }

    private var liveActivitiesAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    private func savePreferences() {
        let preferences = DevicePreferences(
            notificationsEnabled: notificationsEnabled,
            liveActivitiesEnabled: liveActivitiesEnabled,
            showSafeMessages: safeMessagesEnabled
        )
        Task { await store.savePreferences(preferences) }
    }

    private func refreshNotificationAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsSystemDenied = settings.authorizationStatus == .denied
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private var selectedRegionName: String {
        AppConfiguration.selectedRegion()?.displayName
            ?? String(localized: "region.private_deployment")
    }
}

private struct SettingsMachinesLabelStyle: LabelStyle {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func makeBody(configuration: Configuration) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))

        layout {
            configuration.icon
            configuration.title
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SettingsMachinesContentStyle: LabeledContentStyle {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func makeBody(configuration: Configuration) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))

        layout {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
            configuration.content
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum SettingsConnectionState: Equatable {
    case awaitingConfirmation
    case refreshing
    case confirmed
    case cached
    case unavailable

    static func resolve(
        loadState: RunBuoyStore.LoadState,
        isRefreshing: Bool
    ) -> Self {
        if isRefreshing { return .refreshing }
        return switch loadState {
        case .idle: .awaitingConfirmation
        case .loading: .refreshing
        case .loaded: .confirmed
        case .offline: .cached
        case .failed: .unavailable
        }
    }

    var tone: RunBuoyTone {
        switch self {
        case .confirmed: .success
        case .refreshing: .live
        case .cached: .warning
        case .awaitingConfirmation, .unavailable: .neutral
        }
    }

    var symbol: String {
        switch self {
        case .confirmed: "checkmark.circle.fill"
        case .refreshing: "arrow.clockwise"
        case .cached: "wifi.slash"
        case .awaitingConfirmation: "clock"
        case .unavailable: "exclamationmark.circle"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .confirmed: "settings.connection_confirmed"
        case .refreshing: "settings.connection_refreshing"
        case .cached: "settings.connection_cached"
        case .awaitingConfirmation: "settings.connection_awaiting"
        case .unavailable: "settings.connection_unavailable"
        }
    }
}

private struct SettingsConnectionSummary: View {
    let state: SettingsConnectionState
    let machineCount: Int
    let regionName: String
    let serverAddress: String
    let lastConfirmedAt: Date?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        summaryLayout {
            icon
            content
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(state.title))
        .accessibilityIdentifier("settings.connectionSummary")
    }

    private var summaryLayout: AnyLayout {
        // Keep the same content identity when Dynamic Type changes the arrangement.
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
    }

    private var icon: some View {
        Image(systemName: state.symbol)
            .font(.title3.weight(.semibold))
            .foregroundStyle(theme.status(state.tone))
            .accessibilityHidden(true)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(state.title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("settings.connectionSummary.title")
            HStack(spacing: 4) {
                Text(machineCount, format: .number)
                    .font(.subheadline)
                    .accessibilityIdentifier("settings.connectionSummary.machineCount")
                Text("settings.machines_count_suffix")
                    .font(.subheadline)
                    .accessibilityIdentifier("settings.connectionSummary.machineSuffix")
                Circle()
                    .fill(Color.primary)
                    .frame(width: 3, height: 3)
                    .accessibilityHidden(true)
                Text(regionName)
                    .font(.subheadline)
                    .accessibilityIdentifier("settings.connectionSummary.region")
            }
            .runBuoySecondaryText()
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text(serverAddress)
                    .font(.caption)
                    .accessibilityIdentifier("settings.connectionSummary.server")
                    .accessibilityLabel(
                        String(
                            format: String(localized: "settings.server_accessibility_value"),
                            serverAddress
                        )
                    )
                if let lastConfirmedAt {
                    HStack(spacing: 4) {
                        Text("settings.connection_last_confirmed")
                            .font(.caption)
                            .accessibilityIdentifier("settings.connectionSummary.confirmedLabel")
                        Text(
                            lastConfirmedAt,
                            format: .relative(
                                presentation: .numeric,
                                unitsStyle: .abbreviated
                            )
                        )
                        .font(.caption)
                        .accessibilityIdentifier("settings.connectionSummary.confirmedDate")
                    }
                }
            }
            .runBuoySecondaryText()
            .fixedSize(horizontal: false, vertical: true)
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

struct AdvancedDataView: View {
    @Environment(RunBuoyStore.self) private var store
    @AppStorage("runbuoy.onboarding-complete") private var onboardingComplete = false
    @State private var cacheMessage: LocalizedStringKey?
    @State private var confirmsCacheClear = false
    @State private var pendingAction: SettingsLifecycleAction?
    @State private var isPerformingDestructiveAction = false
    @State private var lifecycleNotice: String?
    private let ownerAuthorizer: any DeviceOwnerAuthorizing

    init(ownerAuthorizer: any DeviceOwnerAuthorizing = LocalDeviceOwnerAuthorizer()) {
        self.ownerAuthorizer = ownerAuthorizer
    }

    var body: some View {
        Form {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("settings.safe_data_only")
                            .font(.headline)
                        Text("settings.safe_data_only_description")
                            .font(.footnote)
                            .runBuoySecondaryText()
                    }
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.tint)
                }
            }

            Section("settings.local_data") {
                Button(action: requestCacheClear) {
                    Label("settings.clear_cache", systemImage: "trash")
                        .foregroundStyle(.primary)
                }
                .tint(.primary)
                .accessibilityIdentifier("settings.clearCache")

                if let cacheMessage {
                    Text(cacheMessage)
                        .font(.footnote)
                        .runBuoySecondaryText()
                        .accessibilityIdentifier("settings.cacheCleared")
                }
            }

            Section {
                ForEach(SettingsLifecycleAction.allCases) { action in
                    Button(role: .destructive) {
                        pendingAction = action
                    } label: {
                        Label(action.buttonTitle, systemImage: action.symbol)
                    }
                    .disabled(isPerformingDestructiveAction || action.requiresIdentity && store.deviceIdentity == nil)
                    .accessibilityIdentifier(action.accessibilityIdentifier)
                }

                if isPerformingDestructiveAction {
                    HStack {
                        ProgressView()
                        Text("settings.lifecycle_working")
                    }
                    .accessibilityIdentifier("settings.lifecycleWorking")
                }

                if let lifecycleNotice {
                    Text(lifecycleNotice)
                        .font(.footnote)
                        .runBuoySecondaryText()
                        .accessibilityIdentifier("settings.lifecycleNotice")
                }
            } header: {
                Text("settings.destructive_actions")
            } footer: {
                Text("settings.read_only_boundary")
                    .foregroundStyle(.primary)
            }
        }
        .runBuoyBottomScrollEdgeStyle()
        .accessibilityIdentifier("screen.advancedData")
        .navigationTitle("settings.advanced_data")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "settings.clear_cache_confirm_title",
            isPresented: $confirmsCacheClear,
            titleVisibility: .visible
        ) {
            Button("settings.clear_cache_confirm", role: .destructive, action: clearCache)
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("settings.clear_cache_confirm_message")
        }
        .confirmationDialog(
            pendingAction?.confirmationTitle ?? "",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pendingAction {
                Button(pendingAction.confirmationButtonTitle, role: .destructive) {
                    performLifecycleAction(pendingAction)
                }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text(pendingAction?.confirmationMessage ?? "")
        }
    }

    private func requestCacheClear() {
        cacheMessage = nil
        if UITestConfiguration.current.isEnabled {
            clearCache()
        } else {
            confirmsCacheClear = true
        }
    }

    private func clearCache() {
        Task { @MainActor in
            do {
                try await store.clearCache()
                cacheMessage = "settings.cache_cleared"
            } catch {
                lifecycleNotice = String(
                    format: String(localized: "settings.lifecycle_failed"),
                    error.localizedDescription
                )
            }
        }
    }

    private func performLifecycleAction(_ action: SettingsLifecycleAction) {
        guard !isPerformingDestructiveAction else { return }
        isPerformingDestructiveAction = true
        lifecycleNotice = nil
        Task { @MainActor in
            let authorized = await ownerAuthorizer.authorize(reason: action.authorizationReason)
            guard authorized else {
                lifecycleNotice = String(localized: "settings.lifecycle_auth_cancelled")
                isPerformingDestructiveAction = false
                return
            }
            do {
                switch action {
                case .resetDevice:
                    try await store.resetDevice()
                case .resetLocalOnly:
                    try await store.resetDeviceLocalOnly()
                case .deleteWorkspace:
                    try await store.deleteWorkspace()
                }
                onboardingComplete = false
                lifecycleNotice = String(localized: action.successKey)
            } catch {
                lifecycleNotice = String(
                    format: String(localized: "settings.lifecycle_failed"),
                    error.localizedDescription
                )
            }
            isPerformingDestructiveAction = false
        }
    }
}

protocol DeviceOwnerAuthorizing: Sendable {
    func authorize(reason: String) async -> Bool
}

struct LocalDeviceOwnerAuthorizer: DeviceOwnerAuthorizing {
    func authorize(reason: String) async -> Bool {
        let context = LAContext()
        var evaluationError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &evaluationError) else {
            // The destructive confirmation remains the fallback on a device
            // that has no owner-authentication policy configured.
            return true
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}

enum SettingsLifecycleAction: String, CaseIterable, Identifiable {
    case resetDevice
    case resetLocalOnly
    case deleteWorkspace

    var id: String { rawValue }

    var buttonTitle: LocalizedStringKey {
        switch self {
        case .resetDevice: "settings.reset_device"
        case .resetLocalOnly: "settings.reset_local_only"
        case .deleteWorkspace: "settings.delete_workspace"
        }
    }

    var symbol: String {
        switch self {
        case .resetDevice: "iphone.slash"
        case .resetLocalOnly: "externaldrive.badge.xmark"
        case .deleteWorkspace: "trash.slash"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .resetDevice: "settings.resetDevice"
        case .resetLocalOnly: "settings.resetLocalOnly"
        case .deleteWorkspace: "settings.deleteWorkspace"
        }
    }

    var requiresIdentity: Bool {
        self != .resetLocalOnly
    }

    var confirmationTitle: String {
        switch self {
        case .resetDevice: String(localized: "settings.reset_device_confirm_title")
        case .resetLocalOnly: String(localized: "settings.reset_local_confirm_title")
        case .deleteWorkspace: String(localized: "settings.delete_workspace_confirm_title")
        }
    }

    var confirmationButtonTitle: LocalizedStringKey {
        switch self {
        case .resetDevice: "settings.reset_device_confirm"
        case .resetLocalOnly: "settings.reset_local_confirm"
        case .deleteWorkspace: "settings.delete_workspace_confirm"
        }
    }

    var confirmationMessage: String {
        switch self {
        case .resetDevice: String(localized: "settings.reset_device_confirm_message")
        case .resetLocalOnly: String(localized: "settings.reset_local_confirm_message")
        case .deleteWorkspace: String(localized: "settings.delete_workspace_confirm_message")
        }
    }

    var authorizationReason: String {
        switch self {
        case .resetDevice: String(localized: "settings.reset_device_auth_reason")
        case .resetLocalOnly: String(localized: "settings.reset_local_auth_reason")
        case .deleteWorkspace: String(localized: "settings.delete_workspace_auth_reason")
        }
    }

    var successKey: String.LocalizationValue {
        switch self {
        case .resetDevice: "settings.reset_device_succeeded"
        case .resetLocalOnly: "settings.reset_local_succeeded"
        case .deleteWorkspace: "settings.delete_workspace_succeeded"
        }
    }
}

enum RunBuoyLinks {
    static let website = URL(string: "https://www.runbuoy.cloud")!
    static let privacy = URL(string: "https://www.runbuoy.cloud/privacy")!
    static let support = URL(string: "https://www.runbuoy.cloud/support")!
    static let privateDeployment = URL(string: "https://www.runbuoy.cloud/self-hosting")!
}

#Preview("Settings") {
    NavigationStack { SettingsView() }
        .environment(PreviewFixtures.store())
        .environment(AppRouter())
}

#Preview("Advanced & Data") {
    NavigationStack { AdvancedDataView() }
        .environment(PreviewFixtures.store())
}
