import SwiftUI

enum MachineReceivingVisualState: Hashable {
    case awaitingConfirmation
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
        return .awaitingConfirmation
    }

    var tone: RunBuoyTone {
        switch self {
        case .awaitingConfirmation: .neutral
        case .recentConfirmation: .success
        case .updatesDisabled: .warning
        }
    }

    var symbol: String {
        switch self {
        case .awaitingConfirmation: "clock"
        case .recentConfirmation: "checkmark.seal.fill"
        case .updatesDisabled: "bell.slash.fill"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .awaitingConfirmation: "machines.awaiting_confirmation"
        case .recentConfirmation: "machines.recent_confirmation"
        case .updatesDisabled: "machines.updates_off"
        }
    }

    func countTitle(_ count: Int) -> String {
        let format: String
        switch self {
        case .awaitingConfirmation:
            format = String(localized: "machines.awaiting_confirmation_count")
        case .recentConfirmation:
            format = String(localized: "machines.recent_confirmation_count")
        case .updatesDisabled:
            format = String(localized: "machines.updates_off_count")
        }
        return String(format: format, count)
    }
}

private enum MachineListMetrics {
    static let pageInset: CGFloat = 16
    static let rowInset: CGFloat = 16
    static let iconSize: CGFloat = 48
    static let iconSpacing: CGFloat = 16

    static func textInset(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        rowInset + (dynamicTypeSize.isAccessibilitySize ? 0 : iconSize + iconSpacing)
    }
}

struct MachinesView: View {
    @Environment(RunBuoyStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !store.machines.isEmpty {
                    MachinesSummary(machines: store.machines)
                        .padding(.bottom, 24)

                    Button(action: showPairingCode) {
                        Label("settings.pair_machine", systemImage: "qrcode.viewfinder")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(minHeight: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor, in: Capsule())
                    }
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("machines.enterPairingCode")
                    .padding(.bottom, 28)

                    LazyVStack(spacing: 0) {
                        ForEach(store.machines) { machine in
                            NavigationLink(value: AppRoute.machine(machine.id)) {
                                MachineRow(machine: machine)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("machine.row.\(machine.id)")

                            if machine.id != store.machines.last?.id {
                                Divider()
                                    .padding(.leading, MachineListMetrics.textInset(for: dynamicTypeSize))
                                    .padding(.trailing, MachineListMetrics.rowInset)
                            }
                        }
                    }
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )

                    Text("machines.confirmation_boundary")
                        .font(.footnote)
                        .runBuoySecondaryText()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, MachineListMetrics.pageInset)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .runBuoyCanvas()
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
        VStack(alignment: .leading, spacing: 4) {
            Text(pairedCount)
                .font(.title3.weight(.semibold))
            stateCounts
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private var pairedCount: String {
        let format = machines.count == 1
            ? String(localized: "machines.paired_count.one")
            : String(localized: "machines.paired_count.other")
        return String(format: format, machines.count)
    }

    @ViewBuilder
    private var stateCounts: some View {
        ForEach([MachineReceivingVisualState.recentConfirmation, .awaitingConfirmation, .updatesDisabled], id: \.self) { state in
            if count(for: state) > 0 {
                Text(state.countTitle(count(for: state)))
                    .font(.subheadline)
                    .runBuoySecondaryText()
            }
        }
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

struct MachineRow: View {
    let machine: MachineSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 12) {
                        machineIcon
                        machineMetadata
                    }
                } else {
                    HStack(alignment: .top, spacing: MachineListMetrics.iconSpacing) {
                        machineIcon
                        machineMetadata
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, MachineListMetrics.rowInset)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var machineIcon: some View {
        MachineStatusIcon(
            machineID: machine.id,
            state: state,
            size: MachineListMetrics.iconSize,
            showsStatus: false
        )
    }

    private var machineMetadata: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(machine.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                (
                    Text("\(machine.platform) · ")
                        + Text(machine.isSubscribed ? "machines.updates_on" : "machines.updates_off")
                )
                (
                    Text("machines.last_seen_prefix")
                        + Text(" \(machine.lastSeenAt, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))")
                )

                if machine.isSubscribed {
                    Text(state.title)
                }
            }
            .font(.footnote)
            .runBuoySecondaryText()
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var state: MachineReceivingVisualState {
        .resolve(isSubscribed: machine.isSubscribed, lastSeenAt: machine.lastSeenAt)
    }
}

private struct MachineStatusIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let machineID: String
    let state: MachineReceivingVisualState
    let size: CGFloat
    var showsStatus = true

    var body: some View {
        MachineIconImage(machineID: machineID)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(theme.status(showsStatus ? state.tone : .neutral))
            .frame(width: size, height: size)
            .background(
                showsStatus ? theme.elevatedSurface : theme.canvas,
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .stroke(theme.border(showsStatus ? state.tone : .neutral), lineWidth: contrast == .increased ? 2 : 1)
            }
            .overlay(alignment: .bottomTrailing) {
                if showsStatus {
                    Image(systemName: state.symbol)
                        .font(.system(size: size * 0.22, weight: .bold))
                        .foregroundStyle(theme.status(state.tone))
                        .padding(3)
                        .background(theme.surface, in: Circle())
                }
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
                HStack(spacing: 14) {
                    MachineStatusIcon(machineID: machine.id, state: state, size: 48)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(machine.displayName)
                            .font(.title2.bold())
                            .fixedSize(horizontal: false, vertical: true)
                        Label(state.title, systemImage: state.symbol)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
