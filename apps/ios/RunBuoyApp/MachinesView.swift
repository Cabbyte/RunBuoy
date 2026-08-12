import SwiftUI

struct MachinesView: View {
    @Environment(RunBuoyStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            if !store.machines.isEmpty {
                Section {
                    Text("machines.intro")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    Button(action: showPairingCode) {
                        Label("settings.pair_machine", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .labelStyle(.titleAndIcon)
                    .runBuoyProminentButtonStyle()
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityIdentifier("machines.enterPairingCode")
                }

                Section {
                    ForEach(store.machines) { machine in
                        NavigationLink(value: AppRoute.machine(machine.id)) {
                            MachineRow(machine: machine)
                        }
                        .accessibilityIdentifier("machine.row.\(machine.id)")
                    }
                } header: {
                    Text("machines.paired")
                } footer: {
                    Text("machines.footer")
                }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("screen.machines")
        .navigationTitle("machines.title")
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if store.machines.isEmpty {
                MachinesEmptyState(
                    state: store.state,
                    retry: refresh,
                    pair: showPairingCode
                )
            }
        }
        .refreshable { await reload() }
        .task { await loadIfNeeded() }
    }

    private func showPairingCode() {
        router.settingsPath.append(.pairMachine)
    }

    private func refresh() {
        Task { await reload() }
    }

    private func loadIfNeeded() async {
        guard store.state == .idle else { return }
        await store.refresh()
    }

    private func reload() async {
        await store.refresh()
    }
}

private struct MachinesEmptyState: View {
    let state: RunBuoyStore.LoadState
    let retry: () -> Void
    let pair: () -> Void

    var body: some View {
        Group {
            if state == .loading {
                ProgressView("machines.loading")
            } else if isFailure {
                ContentUnavailableView {
                    Label("machines.unavailable", systemImage: "exclamationmark.icloud")
                } description: {
                    Text("runs.pull_to_refresh")
                } actions: {
                    Button("common.try_again", action: retry)
                        .runBuoyProminentButtonStyle()
                }
            } else {
                ContentUnavailableView {
                    Label("machines.empty", systemImage: "desktopcomputer.and.macbook")
                } description: {
                    Text("machines.empty_description")
                } actions: {
                    Button("settings.pair_machine", systemImage: "plus", action: pair)
                        .labelStyle(.titleAndIcon)
                        .runBuoyProminentButtonStyle()
                        .buttonBorderShape(.capsule)
                        .accessibilityIdentifier("machines.enterPairingCode")
                }
            }
        }
        .padding()
    }

    private var isFailure: Bool {
        if case .failed = state { return true }
        return false
    }
}

struct MachineRow: View {
    let machine: MachineSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    machineIcon
                    machineMetadata
                }
            } else {
                HStack(spacing: 12) {
                    machineIcon
                    machineMetadata
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var machineIcon: some View {
        MachineIconImage(machineID: machine.id)
            .font(.title2)
            .foregroundStyle(machine.isSubscribed ? Color.accentColor : .secondary)
            .frame(width: 34)
            .overlay(alignment: .bottomTrailing) {
                if !machine.isSubscribed {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .background(.background, in: Circle())
                }
            }
            .accessibilityHidden(true)
    }

    private var machineMetadata: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(machine.displayName)
                    .font(.headline)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 4) {
                    Text(machine.platform)
                    Text("·")
                        .accessibilityHidden(true)
                    Text("machines.last_seen_prefix")
                    Text(
                        machine.lastSeenAt,
                        format: .relative(
                            presentation: .numeric,
                            unitsStyle: .abbreviated
                        )
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            HStack(spacing: 4) {
                Circle()
                    .fill(machineStateColor)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text(machineStateTitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
    }

    private var isRecentlySeen: Bool {
        Date().timeIntervalSince(machine.lastSeenAt) < 10 * 60
    }

    private var machineStateTitle: LocalizedStringKey {
        if !machine.isSubscribed { return "machines.updates_off" }
        return isRecentlySeen ? "machines.online" : "machines.idle"
    }

    private var machineStateColor: Color {
        if !machine.isSubscribed { return .orange }
        return isRecentlySeen ? .green : .secondary
    }

}

struct MachineDetailView: View {
    let machineID: String
    @Environment(RunBuoyStore.self) private var store

    var body: some View {
        ZStack {
            Color.clear
            if let machine = store.machines.first(where: { $0.id == machineID }) {
                MachineDetailContent(machine: machine)
            } else {
                ContentUnavailableView {
                    Label {
                        Text("machines.not_found")
                    } icon: {
                        MachineIconImage(machineID: machineID)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct MachineDetailContent: View {
    @Environment(RunBuoyStore.self) private var store

    let machine: MachineSnapshot
    @State private var notice: String?
    @State private var pendingAction: MachineLifecycleAction?
    @State private var isPerformingAction = false
    @AppStorage private var machineIconName: String

    init(machine: MachineSnapshot) {
        self.machine = machine
        _machineIconName = AppStorage(
            wrappedValue: MachineIcon.defaultValue.rawValue,
            MachineIcon.key(for: machine.id)
        )
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    MachineIconImage(machineID: machine.id)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.tint)
                        .frame(width: 72, height: 72)
                        .background(Color.accentColor.opacity(0.12), in: Circle())
                        .accessibilityHidden(true)
                    Text(machine.displayName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Label {
                        Text(machineStateTitle)
                    } icon: {
                        Circle()
                            .fill(machineStateColor)
                            .frame(width: 8, height: 8)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
            }

            Section {
                LabeledContent("machine.platform", value: machine.platform)
                if let architecture = machine.architecture {
                    LabeledContent("machine.architecture", value: architecture)
                }
                LabeledContent("machine.cli_version", value: machine.cliVersion)
                LabeledContent("machine.last_seen") {
                    Text(machine.lastSeenAt, format: .dateTime)
                }
                LabeledContent("machine.paired") {
                    Text(machine.pairedAt, format: .dateTime)
                }
            } header: {
                Text("machine.identity")
            } footer: {
                Text("machine.name_cli_hint")
            }

            Section("machine.appearance") {
                Picker(selection: $machineIconName) {
                    ForEach(MachineIcon.allCases) { icon in
                        Label {
                            Text(icon.title)
                        } icon: {
                            Image(systemName: icon.rawValue)
                        }
                        .tag(icon.rawValue)
                    }
                } label: {
                    Label {
                        Text("machine.icon")
                    } icon: {
                        MachineIconImage(machineID: machine.id)
                    }
                }
            }

            Section {
                if machine.isSubscribed, machine.subscriptionID != nil {
                    Button("machine.stop_receiving", role: .destructive) {
                        pendingAction = .stopReceiving
                    }
                    .disabled(isPerformingAction)
                    .accessibilityIdentifier("machine.stopReceiving")
                }
                Button("machine.revoke", role: .destructive) {
                    pendingAction = .revoke
                }
                .disabled(isPerformingAction)
                .accessibilityIdentifier("machine.revoke")

                if isPerformingAction {
                    ProgressView("machine.lifecycle_working")
                }
            } footer: {
                Text("machine.lifecycle_explanation")
            }

            if let notice {
                Section {
                    Label(notice, systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("screen.machineDetail")
        .navigationTitle(machine.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            pendingAction?.title ?? "",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pendingAction {
                Button(pendingAction.confirmationTitle, role: .destructive) {
                    perform(pendingAction)
                }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text(pendingAction?.message ?? "")
        }
    }

    private var isRecentlySeen: Bool {
        Date().timeIntervalSince(machine.lastSeenAt) < 10 * 60
    }

    private var machineStateTitle: LocalizedStringKey {
        if !machine.isSubscribed { return "machines.updates_off" }
        return isRecentlySeen ? "machines.online" : "machines.idle"
    }

    private var machineStateColor: Color {
        if !machine.isSubscribed { return .orange }
        return isRecentlySeen ? .green : .secondary
    }

    private func perform(_ action: MachineLifecycleAction) {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        notice = nil
        Task { @MainActor in
            let authorized = await LocalDeviceOwnerAuthorizer().authorize(
                reason: action.authorizationReason
            )
            guard authorized else {
                notice = String(localized: "machine.lifecycle_auth_cancelled")
                isPerformingAction = false
                return
            }
            do {
                switch action {
                case .stopReceiving:
                    guard let subscriptionID = machine.subscriptionID else {
                        notice = String(localized: "machine.subscription_missing")
                        isPerformingAction = false
                        return
                    }
                    try await store.stopReceiving(subscriptionID: subscriptionID)
                    notice = String(localized: "machine.receiving_stopped")
                case .revoke:
                    try await store.revokeMachine(machineID: machine.id)
                    notice = String(localized: "machine.revoked")
                }
            } catch {
                notice = String(
                    format: String(localized: "machine.lifecycle_failed"),
                    error.localizedDescription
                )
            }
            isPerformingAction = false
        }
    }
}

private enum MachineLifecycleAction {
    case stopReceiving
    case revoke

    var title: String {
        switch self {
        case .stopReceiving: String(localized: "machine.stop_receiving_confirm_title")
        case .revoke: String(localized: "machine.revoke_confirm_title")
        }
    }

    var confirmationTitle: LocalizedStringKey {
        switch self {
        case .stopReceiving: "machine.stop_receiving_confirm"
        case .revoke: "machine.revoke_confirm"
        }
    }

    var message: String {
        switch self {
        case .stopReceiving: String(localized: "machine.stop_receiving_confirm_message")
        case .revoke: String(localized: "machine.revoke_confirm_message")
        }
    }

    var authorizationReason: String {
        switch self {
        case .stopReceiving: String(localized: "machine.stop_receiving_auth_reason")
        case .revoke: String(localized: "machine.revoke_auth_reason")
        }
    }
}

private extension MachineIcon {
    var title: LocalizedStringKey {
        switch self {
        case .desktopcomputer:
            "machine.icon.desktopcomputer"
        case .macProServer:
            "machine.icon.macpro_server"
        case .macbook:
            "machine.icon.macbook"
        case .macMini:
            "machine.icon.macmini"
        case .macStudio:
            "machine.icon.macstudio"
        case .macPro:
            "machine.icon.macpro"
        }
    }
}

#Preview("Machines") {
    NavigationStack { MachinesView() }
        .environment(PreviewFixtures.store())
}

#Preview("Machine Detail · Large Type") {
    NavigationStack {
        MachineDetailView(machineID: PreviewFixtures.machine.id)
    }
    .environment(PreviewFixtures.store())
    .environment(\.dynamicTypeSize, .accessibility2)
}
