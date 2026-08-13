import SwiftUI

enum MachineReceivingVisualState: Equatable {
    case receiving
    case recentConfirmation
    case updatesDisabled

    static func resolve(
        isSubscribed: Bool,
        lastSeenAt: Date,
        now: Date = Date(),
        recentInterval: TimeInterval = 10 * 60
    ) -> Self {
        guard isSubscribed else { return .updatesDisabled }
        guard now.timeIntervalSince(lastSeenAt) >= recentInterval else {
            return .recentConfirmation
        }
        return .receiving
    }

    var tone: RunBuoyTone {
        switch self {
        case .receiving: .live
        case .recentConfirmation: .success
        case .updatesDisabled: .warning
        }
    }

    var symbol: String {
        switch self {
        case .receiving: "antenna.radiowaves.left.and.right"
        case .recentConfirmation: "checkmark.seal.fill"
        case .updatesDisabled: "bell.slash.fill"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .receiving: "machines.receiving_updates"
        case .recentConfirmation: "machines.recent_confirmation"
        case .updatesDisabled: "machines.updates_off"
        }
    }
}

struct MachinesView: View {
    @Environment(RunBuoyStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            if !store.machines.isEmpty {
                Section {
                    MachinesSummary(machines: store.machines)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    Button(action: showPairingCode) {
                        Label("settings.pair_machine", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.borderedProminent)
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
                    Button("settings.pair_machine", systemImage: "qrcode.viewfinder", action: pair)
                        .labelStyle(.titleAndIcon)
                        .buttonStyle(.borderedProminent)
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

private struct MachinesSummary: View {
    let machines: [MachineSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("machines.paired", systemImage: "desktopcomputer.and.macbook")
                .font(.headline)

            Text(machines.count, format: .number)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) { stateCounts }
                VStack(alignment: .leading, spacing: 6) { stateCounts }
            }

            Text("machines.intro")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var stateCounts: some View {
        MachineStateCount(
            state: .recentConfirmation,
            count: count(for: .recentConfirmation)
        )
        MachineStateCount(
            state: .receiving,
            count: count(for: .receiving)
        )
        MachineStateCount(
            state: .updatesDisabled,
            count: count(for: .updatesDisabled)
        )
    }

    private func count(for state: MachineReceivingVisualState) -> Int {
        machines.count { machine in
            MachineReceivingVisualState.resolve(
                isSubscribed: machine.isSubscribed,
                lastSeenAt: machine.lastSeenAt
            ) == state
        }
    }
}

private struct MachineStateCount: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let state: MachineReceivingVisualState
    let count: Int

    var body: some View {
        Label {
            HStack(spacing: 3) {
                Text(count, format: .number)
                Text(state.title)
            }
        } icon: {
            Image(systemName: state.symbol)
                .foregroundStyle(theme.status(state.tone))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

struct MachineRow: View {
    let machine: MachineSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

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
        MachineStatusIcon(machineID: machine.id, state: state, size: 48)
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
                Image(systemName: state.symbol)
                    .foregroundStyle(stateColor)
                    .accessibilityHidden(true)
                Text(state.title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: false, vertical: true)
        .layoutPriority(1)
    }

    private var state: MachineReceivingVisualState {
        .resolve(isSubscribed: machine.isSubscribed, lastSeenAt: machine.lastSeenAt)
    }

    private var stateColor: Color {
        theme.status(state.tone)
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

private struct MachineStatusIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let machineID: String
    let state: MachineReceivingVisualState
    let size: CGFloat

    var body: some View {
        MachineIconImage(machineID: machineID)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(theme.status(state.tone))
            .frame(width: size, height: size)
            .background(theme.elevatedSurface, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .stroke(theme.border(state.tone), lineWidth: contrast == .increased ? 2 : 1)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: state.symbol)
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(theme.status(state.tone))
                    .padding(3)
                    .background(theme.surface, in: Circle())
            }
            .accessibilityHidden(true)
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
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
                    MachineStatusIcon(machineID: machine.id, state: state, size: 72)
                    Text(machine.displayName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Label(state.title, systemImage: state.symbol)
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

    private var state: MachineReceivingVisualState {
        .resolve(isSubscribed: machine.isSubscribed, lastSeenAt: machine.lastSeenAt)
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
