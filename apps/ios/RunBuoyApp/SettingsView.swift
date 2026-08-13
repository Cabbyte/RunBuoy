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
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            Section {
                ConnectionSummaryCard(
                    state: store.state,
                    machineCount: store.machines.count,
                    regionName: selectedRegionName,
                    address: AppConfiguration.displayAddress(for: AppConfiguration.live.apiBaseURL),
                    lastRefreshAt: store.lastRefreshAt,
                    hasDeviceIdentity: store.deviceIdentity != nil
                )

                LabeledContent {
                    Text(selectedRegionName)
                        .foregroundStyle(.primary)
                } label: {
                    Label("settings.region", systemImage: "globe")
                }

                LabeledContent {
                    Text(AppConfiguration.displayAddress(for: AppConfiguration.live.apiBaseURL))
                        .foregroundStyle(.primary)
                } label: {
                    Label("settings.server", systemImage: "server.rack")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("settings.server"))
                .accessibilityValue(Text(AppConfiguration.displayAddress(for: AppConfiguration.live.apiBaseURL)))

                NavigationLink(value: AppRoute.machines) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "desktopcomputer")
                                .accessibilityHidden(true)
                            Text("settings.machines")
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text(store.machines.count, format: .number)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityIdentifier("settings.machines")
            } header: {
                Text("settings.connections")
            } footer: {
                Text("settings.region_locked")
                    .foregroundStyle(Color(uiColor: .label))
            }

            Section {
                Toggle("settings.notifications_enabled", isOn: $notificationsEnabled)
                    .disabled(notificationsSystemDenied)
                    .accessibilityIdentifier("settings.notifications")
                Toggle("settings.live_activities", isOn: $liveActivitiesEnabled)
                    .disabled(!ActivityAuthorizationInfo().areActivitiesEnabled)
                    .accessibilityIdentifier("settings.liveActivities")
                Toggle("settings.safe_messages", isOn: $safeMessagesEnabled)
                    .accessibilityIdentifier("settings.safeMessages")
                if !ActivityAuthorizationInfo().areActivitiesEnabled {
                    Label("settings.live_activities_system_disabled", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                if notificationsSystemDenied {
                    Label("settings.notifications_system_disabled", systemImage: "bell.slash")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    Button("settings.open_system_settings", action: openSystemSettings)
                        .accessibilityIdentifier("settings.openSystemSettings")
                }
            } header: {
                Text("settings.preferences")
            } footer: {
                Color.clear
                    .frame(height: 8)
                    .accessibilityHidden(true)
            }

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
            } footer: {
                Text("demo.settings_footer")
                    .foregroundStyle(Color(uiColor: .label))
            }

            Section {
                Link(destination: RunBuoyLinks.website) {
                    Label("settings.website", systemImage: "globe")
                        .foregroundStyle(.primary)
                }
                .tint(.primary)
                Link(destination: RunBuoyLinks.privacy) {
                    Label("settings.privacy", systemImage: "hand.raised")
                        .foregroundStyle(.primary)
                }
                .tint(.primary)
                Link(destination: RunBuoyLinks.support) {
                    Label("settings.support", systemImage: "questionmark.circle")
                        .foregroundStyle(.primary)
                }
                .tint(.primary)
                Link(destination: RunBuoyLinks.privateDeployment) {
                    Label("settings.private_deployment", systemImage: "server.rack")
                        .foregroundStyle(.primary)
                }
                .tint(.primary)
            } header: {
                Text("settings.about")
            } footer: {
                Text("settings.preferences_saved_footer")
                    .foregroundStyle(Color(uiColor: .label))
            }
        }
        .padding(.bottom, 44)
        .background(Color(uiColor: .systemGroupedBackground))
        .runBuoyReadableBottomScrollEdgeStyle()
        .accessibilityIdentifier("screen.settings")
        .navigationTitle("settings.title")
        .onChange(of: notificationsEnabled) { _, enabled in
            Task { await updateNotificationPreference(enabled) }
        }
        .onChange(of: liveActivitiesEnabled) { _, _ in savePreferences() }
        .onChange(of: safeMessagesEnabled) { _, _ in savePreferences() }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await refreshNotificationAuthorization()
        }
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
        notificationAuthorizationStatus = settings.authorizationStatus
    }

    private func updateNotificationPreference(_ enabled: Bool) async {
        guard enabled, notificationAuthorizationStatus == .notDetermined else {
            savePreferences()
            return
        }
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        await refreshNotificationAuthorization()
        if granted {
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            notificationsEnabled = false
        }
        savePreferences()
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private var selectedRegionName: String {
        AppConfiguration.selectedRegion()?.displayName
            ?? String(localized: "region.private_deployment")
    }

    private var notificationsSystemDenied: Bool {
        notificationAuthorizationStatus == .denied
    }
}

private struct ConnectionSummaryCard: View {
    let state: RunBuoyStore.LoadState
    let machineCount: Int
    let regionName: String
    let address: String
    let lastRefreshAt: Date?
    let hasDeviceIdentity: Bool
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .accessibilityIdentifier("settings.connectionSummary")
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "settings.connection_machines_region"),
                        machineCount,
                        regionName
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.primary)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 4) {
                        Text(address)
                            .accessibilityLabel(Text("settings.server"))
                            .accessibilityValue(Text(address))
                        Circle()
                            .fill(.primary)
                            .frame(width: 3, height: 3)
                            .accessibilityHidden(true)
                        confirmationText
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(address)
                            .accessibilityLabel(Text("settings.server"))
                            .accessibilityValue(Text(address))
                        confirmationText
                    }
                }
                .font(.caption)
                .foregroundStyle(.primary)
            }
        } icon: {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tone.color)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var confirmationText: some View {
        if let lastRefreshAt {
            HStack(spacing: 3) {
                Text("settings.connection_confirmed")
                Text(lastRefreshAt, style: .relative)
            }
        } else {
            Text("settings.connection_not_confirmed")
        }
    }

    private var title: LocalizedStringKey {
        switch state {
        case .loaded: "settings.connection_connected"
        case .offline: "settings.connection_cached"
        case .loading: "settings.connection_loading"
        case .failed: "settings.connection_unavailable"
        case .idle:
            hasDeviceIdentity ? "settings.connection_ready" : "settings.connection_not_connected"
        }
    }

    private var symbol: String {
        switch state {
        case .loaded: "checkmark.circle.fill"
        case .offline: "wifi.slash"
        case .loading: "arrow.triangle.2.circlepath"
        case .failed: "exclamationmark.triangle.fill"
        case .idle: hasDeviceIdentity ? "link.circle" : "link.badge.plus"
        }
    }

    private var tone: RunBuoyTone {
        switch state {
        case .loaded: .success
        case .offline: .warning
        case .loading: .live
        case .failed: .critical
        case .idle: .neutral
        }
    }
}

struct AdvancedDataView: View {
    @Environment(RunBuoyStore.self) private var store
    @AppStorage("runbuoy.onboarding-complete") private var onboardingComplete = false
    @State private var cacheMessage: LocalizedStringKey?
    @State private var confirmsCacheClear = false
    @State private var confirmsDeviceReset = false
    @State private var confirmsLocalReset = false
    @State private var confirmsWorkspaceDeletion = false
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
                        Text("settings.safe_data_only_body")
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(RunBuoyTheme.brandPrimary)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }

            Section("settings.local_data") {
                Button(action: requestCacheClear) {
                    actionLabel(
                        title: "settings.clear_cache",
                        description: "settings.clear_cache_description",
                        symbol: "trash"
                    )
                }
                .tint(.primary)
                .accessibilityIdentifier("settings.clearCache")
                if let cacheMessage {
                    Text(cacheMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settings.cacheCleared")
                }
            }

            Section {
                Button(role: .destructive) {
                    confirmsDeviceReset = true
                } label: {
                    actionLabel(
                        title: "settings.reset_device",
                        description: "settings.reset_device_description",
                        symbol: "iphone.slash"
                    )
                }
                .disabled(isPerformingDestructiveAction || store.deviceIdentity == nil)
                .accessibilityIdentifier("settings.resetDevice")

                Button(role: .destructive) {
                    confirmsLocalReset = true
                } label: {
                    actionLabel(
                        title: "settings.reset_local_only",
                        description: "settings.reset_local_description",
                        symbol: "externaldrive.badge.xmark"
                    )
                }
                .disabled(isPerformingDestructiveAction)
                .accessibilityIdentifier("settings.resetLocalOnly")

                Button(role: .destructive) {
                    confirmsWorkspaceDeletion = true
                } label: {
                    actionLabel(
                        title: "settings.delete_workspace",
                        description: "settings.delete_workspace_description",
                        symbol: "trash.slash"
                    )
                }
                .disabled(isPerformingDestructiveAction || store.deviceIdentity == nil)
                .accessibilityIdentifier("settings.deleteWorkspace")

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
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settings.lifecycleNotice")
                }
            } header: {
                Text("settings.destructive_actions")
            } footer: {
                Text("settings.read_only_boundary")
                    .foregroundStyle(Color(uiColor: .label))
            }
        }
        .accessibilityIdentifier("screen.advancedData")
        .navigationTitle("settings.advanced_data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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
            "settings.reset_device_confirm_title",
            isPresented: $confirmsDeviceReset,
            titleVisibility: .visible
        ) {
            Button("settings.reset_device_confirm", role: .destructive) {
                performLifecycleAction(.resetDevice)
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("settings.reset_device_confirm_message")
        }
        .confirmationDialog(
            "settings.reset_local_confirm_title",
            isPresented: $confirmsLocalReset,
            titleVisibility: .visible
        ) {
            Button("settings.reset_local_confirm", role: .destructive) {
                performLifecycleAction(.resetLocalOnly)
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("settings.reset_local_confirm_message")
        }
        .confirmationDialog(
            "settings.delete_workspace_confirm_title",
            isPresented: $confirmsWorkspaceDeletion,
            titleVisibility: .visible
        ) {
            Button("settings.delete_workspace_confirm", role: .destructive) {
                performLifecycleAction(.deleteWorkspace)
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("settings.delete_workspace_confirm_message")
        }
    }

    private func actionLabel(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        symbol: String
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .label))
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(Color(uiColor: .label))
                    .multilineTextAlignment(.leading)
            }
        } icon: {
            Image(systemName: symbol)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
    }

    private func clearCache() {
        Task {
            try? await store.clearCache()
            cacheMessage = "settings.cache_cleared"
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
            // The explicit destructive confirmation remains the fallback on a
            // device that has no owner-authentication policy configured.
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

private enum SettingsLifecycleAction {
    case resetDevice
    case resetLocalOnly
    case deleteWorkspace

    var authorizationReason: String {
        switch self {
        case .resetDevice:
            String(localized: "settings.reset_device_auth_reason")
        case .resetLocalOnly:
            String(localized: "settings.reset_local_auth_reason")
        case .deleteWorkspace:
            String(localized: "settings.delete_workspace_auth_reason")
        }
    }

    var successKey: String.LocalizationValue {
        switch self {
        case .resetDevice:
            "settings.reset_device_succeeded"
        case .resetLocalOnly:
            "settings.reset_local_succeeded"
        case .deleteWorkspace:
            "settings.delete_workspace_succeeded"
        }
    }
}

enum RunBuoyLinks {
    static let website = URL(string: "https://www.runbuoy.cloud")!
    static let privacy = URL(string: "https://www.runbuoy.cloud/privacy")!
    static let support = URL(string: "https://www.runbuoy.cloud/support")!
    static let privateDeployment = URL(string: "https://www.runbuoy.cloud/self-hosting")!
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(PreviewFixtures.store())
        .environment(AppRouter())
}
