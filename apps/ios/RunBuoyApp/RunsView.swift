import Foundation
import SwiftUI

struct ActiveRunsView: View {
    @Environment(RunBuoyStore.self) private var store

    private var sortedModels: [RunSummaryModel] {
        ActiveRunPresentation.sorted(store.activeRunModels)
    }

    private var isEmpty: Bool {
        sortedModels.isEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if case .offline(let message) = store.state {
                    OfflineBanner(message: message)
                }

                if let hero = sortedModels.first {
                    ActiveSystemSummaryCard(
                        runs: sortedModels.map(\.snapshot),
                        lastSyncedAt: store.lastRefreshAt
                    )
                    ActiveRunHeroLink(model: hero)

                    let secondary = Array(sortedModels.dropFirst())
                    if !secondary.isEmpty {
                        Text("runs.also_active")
                            .font(.caption.weight(.semibold))
                            .runBuoySecondaryText()
                            .textCase(.uppercase)
                        ForEach(secondary) { model in
                            ActiveRunCompactLink(model: model)
                        }
                    }
                } else if store.state == .loading {
                    ActiveRunsLoadingSkeleton()
                } else {
                    ActiveRunsEmptyState(state: store.state, retry: refresh)
                        .frame(maxWidth: .infinity, minHeight: 360)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .runBuoyCanvas()
        .runBuoyBottomScrollEdgeStyle()
        .accessibilityIdentifier("screen.activeRuns")
        .navigationTitle("runs.active")
        .refreshable { await reload() }
        .task { await loadIfNeeded() }
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

enum ActiveRunPresentation {
    @MainActor
    static func sorted(_ models: [RunSummaryModel]) -> [RunSummaryModel] {
        models.sorted { orderedBefore($0.snapshot, $1.snapshot) }
    }

    static func orderedBefore(_ lhs: RunSnapshot, _ rhs: RunSnapshot) -> Bool {
        let leftRank = rank(lhs)
        let rightRank = rank(rhs)
        if leftRank != rightRank { return leftRank < rightRank }
        if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt > rhs.updatedAt }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    static func rank(_ run: RunSnapshot) -> Int {
        if run.attentionStatus == .actionRequired { return 0 }
        if run.attentionStatus == .warning { return 1 }
        if run.healthStatus == .stale || run.healthStatus == .offline { return 2 }
        if run.executionStatus == .starting || run.executionStatus == .running { return 3 }
        return 4
    }
}

struct ActiveSystemSummary: Equatable {
    let activeCount: Int
    let issueCount: Int
    let lastConfirmedAt: Date?

    init(runs: [RunSnapshot]) {
        activeCount = runs.count
        issueCount = runs.filter {
            let kind = $0.statusVisualState.kind
            return kind == .actionRequired || kind == .warning || kind == .stale || kind == .offline
        }.count
        lastConfirmedAt = runs.map(\.updatedAt).max()
    }

    var isHealthy: Bool { activeCount > 0 && issueCount == 0 }
}

private struct ActiveSystemSummaryCard: View {
    let summary: ActiveSystemSummary
    let lastSyncedAt: Date?

    init(runs: [RunSnapshot], lastSyncedAt: Date?) {
        summary = ActiveSystemSummary(runs: runs)
        self.lastSyncedAt = lastSyncedAt
    }

    var body: some View {
        RunStateBanner(
            tone: summary.isHealthy ? .live : (summary.issueCount > 0 ? .warning : .neutral),
            symbol: summary.isHealthy ? "waveform.path.ecg" : "exclamationmark.triangle.fill"
        ) {
            VStack(alignment: .leading, spacing: 2) {
                Text(summaryTitle)
                    .font(.subheadline.weight(.semibold))
                if let lastSyncedAt {
                    Text("\(String(localized: "runs.phone_synced")) \(lastSyncedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .runBuoySecondaryText()
                }
                Text("runs.confirmation_hint")
                    .font(.caption)
                    .runBuoySecondaryText()
                    .accessibilityIdentifier("activeRuns.confirmationHint")
            }
        }
        .accessibilityIdentifier("activeRuns.systemSummary")
    }

    private var summaryTitle: String {
        if summary.isHealthy {
            return String(
                format: String(localized: "runs.system_summary.healthy"),
                summary.activeCount
            )
        }
        return String(
            format: String(localized: "runs.system_summary.issues"),
            summary.activeCount,
            summary.issueCount
        )
    }
}

private struct ActiveRunHeroLink: View {
    let model: RunSummaryModel

    var body: some View {
        NavigationLink(value: AppRoute.runDetail(model.id)) {
            ActiveRunHero(run: model.snapshot)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("run.row.\(model.id.uuidString.lowercased())")
    }
}

private struct ActiveRunHero: View {
    let run: RunSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        RunHeroCard(
            tone: run.statusVisualState.tone,
            allowsLiveEmphasis: run.statusVisualState.kind == .running
                && run.statusVisualState.allowsLiveEmphasis
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 8) { status; title }
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 10) { status; title }
                    }
                }
                Label {
                    Text(run.machineName)
                } icon: {
                    MachineIconImage(machineID: run.machineID).accessibilityHidden(true)
                }
                .font(.subheadline)
                RunProgressView(
                    progress: run.progress,
                    phase: run.phase,
                    status: run.statusVisualState,
                    emphasis: .prominent
                )
                ActiveRunTiming(run: run)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var status: some View {
        StatusBadge(presentation: StatusPresentation(visualState: run.statusVisualState), showsLabel: true)
    }

    private var title: some View {
        Text(run.title)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ActiveRunCompactLink: View {
    let model: RunSummaryModel

    var body: some View {
        NavigationLink(value: AppRoute.runDetail(model.id)) {
            RunCompactCard(tone: model.snapshot.statusVisualState.tone) {
                RunRow(model: model, showsLiveTiming: true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("run.row.\(model.id.uuidString.lowercased())")
    }
}

private struct ActiveRunTiming: View {
    let run: RunSnapshot

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { runtime; confirmed }
            VStack(alignment: .leading, spacing: 6) { runtime; confirmed }
        }
        .font(.caption)
    }

    private var runtime: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer").accessibilityHidden(true)
            (
                Text("run.execution_time")
                    + Text(" \(RunDurationText.string(from: run.startedAt, to: run.updatedAt))")
                    .fontWeight(.semibold)
            )
            .font(.caption)
            .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("run.timing.execution")
    }

    private var confirmed: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg").accessibilityHidden(true)
            (
                Text("run.last_confirmed")
                    + Text(" \(run.updatedAt, format: .relative(presentation: .named))")
                    .fontWeight(.semibold)
            )
            .font(.caption)
            .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("run.timing.heartbeat")
    }
}

private struct ActiveRunsLoadingSkeleton: View {
    var body: some View {
        VStack(spacing: 14) {
            ForEach([56.0, 230.0, 116.0], id: \.self) { height in
                RoundedRectangle(cornerRadius: RunBuoyMetrics.cardCornerRadius)
                    .fill(.quaternary)
                    .frame(height: height)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("runs.loading")
    }
}

struct RunHistoryView: View {
    @Environment(RunBuoyStore.self) private var store
    @AppStorage("runbuoy.safe-messages-enabled") private var safeMessagesEnabled = true
    @State private var selectedMachineID: String?
    @State private var areRunsExpanded = false
    @State private var areMessagesExpanded = false

    init(initialMachineID: String? = nil) {
        _selectedMachineID = State(initialValue: initialMachineID)
    }

    private var machineOptions: [HistoryMachineOption] {
        HistoryMachineOption.makeOptions(
            machines: store.machines,
            runs: store.historyRunModels.map(\.snapshot),
            messages: store.messages
        )
    }

    private var machineOptionIDs: [String] {
        machineOptions.map(\.id)
    }

    private var selectedMachineName: String? {
        guard let selectedMachineID else { return nil }
        return machineOptions.first(where: { $0.id == selectedMachineID })?.name
    }

    private var contentFilter: HistoryContentFilter {
        HistoryContentFilter(machineID: selectedMachineID)
    }

    private var filteredRunModels: [RunSummaryModel] {
        store.historyRunModels.filter {
            contentFilter.includes(machineID: $0.snapshot.machineID)
        }
    }

    private var filteredMessages: [RichMessage] {
        guard safeMessagesEnabled else { return [] }
        return store.messages.filter {
            contentFilter.includes(machineID: $0.machineID)
        }
    }

    private var visibleRunModels: ArraySlice<RunSummaryModel> {
        filteredRunModels.prefix(
            HistorySectionPresentation.visibleCount(
                totalCount: filteredRunModels.count,
                isExpanded: areRunsExpanded
            )
        )
    }

    private var visibleMessages: ArraySlice<RichMessage> {
        filteredMessages.prefix(
            HistorySectionPresentation.visibleCount(
                totalCount: filteredMessages.count,
                isExpanded: areMessagesExpanded
            )
        )
    }

    private var isEmpty: Bool {
        filteredRunModels.isEmpty
            && filteredMessages.isEmpty
            && !store.canLoadMoreRuns(machineID: selectedMachineID)
            && !store.canLoadMoreMessages(machineID: selectedMachineID)
    }

    var body: some View {
        historyListWithFilter
        .accessibilityIdentifier("screen.history")
        .navigationTitle("history.title")
        .refreshable { await reload() }
        .task { await loadIfNeeded() }
        .onChange(of: selectedMachineID) { _, _ in
            areRunsExpanded = false
            areMessagesExpanded = false
        }
        .onChange(of: machineOptionIDs) { _, availableIDs in
            guard let selectedMachineID,
                  !availableIDs.contains(selectedMachineID)
            else {
                return
            }
            self.selectedMachineID = nil
        }
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                Section {
                    if case .offline(let message) = store.state {
                        OfflineBanner(message: message)
                    }

                    if !filteredRunModels.isEmpty || store.canLoadMoreRuns(machineID: selectedMachineID) {
                        HistorySectionTitle("runs.recent")
                        ForEach(visibleRunModels) { model in
                            NavigationLink(value: AppRoute.runDetail(model.id)) {
                                RunCompactCard(tone: model.snapshot.statusVisualState.tone) {
                                    RunRow(model: model)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("run.row.\(model.id.uuidString.lowercased())")
                        }
                        HistoryExpansionButton(
                            totalCount: filteredRunModels.count,
                            isExpanded: $areRunsExpanded
                        )
                        if store.canLoadMoreRuns(machineID: selectedMachineID) {
                            HistoryLoadMoreButton(
                                isLoading: store.isLoadingMoreRuns,
                                accessibilityID: "history.runs.loadMore"
                            ) {
                                await store.loadMoreHistoryRuns(machineID: selectedMachineID)
                                areRunsExpanded = true
                            }
                        }
                    }

                    if !filteredMessages.isEmpty || store.canLoadMoreMessages(machineID: selectedMachineID) {
                        HistorySectionTitle("runs.messages")
                        ForEach(visibleMessages) { message in
                            HistoryMessageCard(message: message)
                                .accessibilityIdentifier("history.message.\(message.id)")
                        }
                        HistoryExpansionButton(
                            totalCount: filteredMessages.count,
                            isExpanded: $areMessagesExpanded
                        )
                        if store.canLoadMoreMessages(machineID: selectedMachineID) {
                            HistoryLoadMoreButton(
                                isLoading: store.isLoadingMoreMessages,
                                accessibilityID: "history.messages.loadMore"
                            ) {
                                await store.loadMoreHistoryMessages(machineID: selectedMachineID)
                                areMessagesExpanded = true
                            }
                        }
                    }

                    if isEmpty, store.state == .loading {
                        HistoryLoadingSkeleton()
                    } else if isEmpty {
                        HistoryEmptyState(
                            state: store.state,
                            machineID: selectedMachineID,
                            machineName: selectedMachineName,
                            retry: refresh
                        )
                        .frame(maxWidth: .infinity, minHeight: 320)
                    }
                } header: {
                    if !machineOptions.isEmpty {
                        HistoryMachineFilterBar(
                            options: machineOptions,
                            selection: $selectedMachineID
                        )
                        .padding(.horizontal, -16)
                        .runBuoyCanvas()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .runBuoyCanvas()
        .runBuoyBottomScrollEdgeStyle()
    }

    private var historyListWithFilter: some View {
        // A native pinned header keeps the filter in the scroll layout instead
        // of covering the navigation title with a top safe-area inset.
        historyList
    }

    private func refresh() {
        Task { await reload() }
    }

    private func loadIfNeeded() async {
        guard store.state == .idle || machineOptions.isEmpty else { return }
        await store.refresh()
    }

    private func reload() async {
        await store.refresh()
    }
}

private struct HistorySectionTitle: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .runBuoySecondaryText()
            .textCase(.uppercase)
            .padding(.top, 4)
    }
}

private struct HistoryMessageCard: View {
    let message: RichMessage

    var body: some View {
        RunCompactCard(tone: messageTone) {
            RichMessageRow(message: message)
        }
    }

    private var messageTone: RunBuoyTone {
        switch message.level.lowercased() {
        case "success": .success
        case "warning": .warning
        case "error", "failure", "critical": .critical
        default: .neutral
        }
    }
}

private struct HistoryLoadingSkeleton: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardCornerRadius)
                    .fill(.quaternary)
                    .frame(height: 110)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("history.loading")
    }
}

private struct HistoryLoadMoreButton: View {
    let isLoading: Bool
    let accessibilityID: String
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(isLoading ? "history.loading_more" : "history.load_more")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .contentShape(Rectangle())
        }
        .disabled(isLoading)
        .accessibilityIdentifier(accessibilityID)
    }
}

enum HistorySectionPresentation {
    static let collapsedCount = 5

    static func visibleCount(totalCount: Int, isExpanded: Bool) -> Int {
        isExpanded ? totalCount : min(totalCount, collapsedCount)
    }

    static func remainingCount(totalCount: Int) -> Int {
        max(0, totalCount - collapsedCount)
    }
}

private struct HistoryExpansionButton: View {
    let totalCount: Int
    @Binding var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var remainingCount: Int {
        HistorySectionPresentation.remainingCount(totalCount: totalCount)
    }

    var body: some View {
        if remainingCount > 0 {
            Button(action: toggleExpansion) {
                Label {
                    Text(label)
                } icon: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .accessibilityLabel(label)
            .accessibilityIdentifier(
                isExpanded
                    ? "history.expansion.collapse"
                    : "history.expansion.expand"
            )
        }
    }

    private var label: String {
        if isExpanded {
            return String(localized: "history.show_less")
        }
        return String(
            format: String(localized: "history.show_remaining"),
            remainingCount
        )
    }

    private func toggleExpansion() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) {
            isExpanded.toggle()
        }
    }
}

struct HistoryMachineOption: Identifiable, Hashable {
    let id: String
    let name: String

    static func makeOptions(
        machines: [MachineSnapshot],
        runs: [RunSnapshot],
        messages: [RichMessage]
    ) -> [HistoryMachineOption] {
        var serverNamesByID: [String: String] = [:]

        for message in messages {
            guard let machineID = message.machineID, !machineID.isEmpty else { continue }
            serverNamesByID[machineID] = serverNamesByID[machineID] ?? machineID
        }
        for run in runs.reversed() {
            serverNamesByID[run.machineID] = run.machineName
        }
        for machine in machines {
            serverNamesByID[machine.id] = machine.displayName
        }

        return serverNamesByID.map { machineID, serverName in
            HistoryMachineOption(id: machineID, name: serverName)
        }
        .sorted { lhs, rhs in
            let comparison = lhs.name.localizedStandardCompare(rhs.name)
            if comparison == .orderedSame {
                return lhs.id < rhs.id
            }
            return comparison == .orderedAscending
        }
    }
}

struct HistoryContentFilter: Equatable {
    let machineID: String?

    func includes(machineID candidateMachineID: String?) -> Bool {
        guard let machineID else { return true }
        return candidateMachineID == machineID
    }
}

private struct HistoryMachineFilterBar: View {
    let options: [HistoryMachineOption]
    @Binding var selection: String?

    private var rowCount: Int { options.count > 1 ? 2 : 1 }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<rowCount, id: \.self) { row in
                    filterRow(row)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func filterRow(_ row: Int) -> some View {
        HStack(spacing: 6) {
            if row == 0 {
                filterButton(id: nil) {
                    Text("history.all")
                }
            }
            ForEach(
                options.enumerated().filter { ($0.offset + 1) % rowCount == row },
                id: \.element.id
            ) { _, option in
                filterButton(id: option.id) {
                    HStack(spacing: 4) {
                        MachineIconImage(machineID: option.id)
                            .accessibilityHidden(true)
                        Text(option.name)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 160, alignment: .leading)
                    }
                }
                .accessibilityLabel(option.name)
            }
        }
    }

    @ViewBuilder
    private func filterButton<Content: View>(
        id: String?,
        @ViewBuilder label: () -> Content
    ) -> some View {
        let isSelected = selection == id
        let button = Button {
            selection = id
        } label: {
            label()
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(Color.primary)
        }

        filterCapsule(button, isSelected: isSelected)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier(id.map { "history.filter.\($0)" } ?? "history.filter.all")
    }

    private func filterCapsule<Content: View>(
        _ content: Content,
        isSelected: Bool
    ) -> some View {
        content
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            // Keep the visible surface as wide as the minimum hit target.
            .frame(minWidth: 44)
            .contentShape(Capsule())
            .background {
                Capsule()
                    .fill(
                        isSelected
                            ? Color(.secondarySystemBackground)
                            : Color(.tertiarySystemFill)
                    )
            }
            .overlay {
                if isSelected {
                    Capsule().stroke(Color.accentColor, lineWidth: 1)
                }
            }
    }
}

private struct ActiveRunsEmptyState: View {
    let state: RunBuoyStore.LoadState
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(description)
        } actions: {
            if state.isFailure {
                Button(action: retry) {
                    Text("common.try_again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(Color.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .accessibilityIdentifier(
            state.isFailure
                ? "activeRuns.state.failed"
                : "activeRuns.state.empty"
        )
    }

    private var title: LocalizedStringKey {
        if case .failed = state {
            return "runs.unavailable"
        }
        return "runs.active_empty"
    }

    private var description: LocalizedStringKey {
        if case .failed = state {
            return "runs.pull_to_refresh"
        }
        return "runs.active_empty_description"
    }

    private var symbol: String {
        if case .failed = state {
            return "exclamationmark.icloud"
        }
        return "checkmark.circle"
    }
}

private extension RunBuoyStore.LoadState {
    var isFailure: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

private struct HistoryEmptyState: View {
    let state: RunBuoyStore.LoadState
    let machineID: String?
    let machineName: String?
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                if let machineID, !isFailure {
                    MachineIconImage(machineID: machineID)
                } else {
                    Image(systemName: symbol)
                }
            }
        } description: {
            Text(description)
        } actions: {
            if isFailure {
                Button("common.try_again", action: retry)
                    .runBuoyProminentButtonStyle()
            }
        }
        .padding()
    }

    private var title: String {
        if case .failed = state {
            return String(localized: "runs.unavailable")
        }
        if let machineName {
            return String(
                format: String(localized: "history.filtered_empty"),
                machineName
            )
        }
        return String(localized: "history.empty")
    }

    private var description: String {
        if case .failed = state {
            return String(localized: "runs.pull_to_refresh")
        }
        if machineName != nil {
            return String(localized: "history.filtered_empty_description")
        }
        return String(localized: "history.empty_description")
    }

    private var symbol: String {
        if isFailure {
            return "exclamationmark.icloud"
        }
        return "clock.arrow.circlepath"
    }

    private var isFailure: Bool {
        if case .failed = state {
            return true
        }
        return false
    }
}

struct RichMessageRow: View {
    let message: RichMessage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Image(systemName: messageSymbol)
                    .foregroundStyle(messageColor)
                    .accessibilityHidden(true)
                Text(message.title)
                    .font(.headline)
                    .accessibilityIdentifier("history.message.\(message.id).title")
                Spacer()
                Text(message.createdAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("history.message.\(message.id).date")
            }
            if let subtitle = message.subtitle {
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .accessibilityIdentifier("history.message.\(message.id).subtitle")
            }
            Text(message.body)
                .font(.body)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 10 : 6)
                .textSelection(.enabled)
                .accessibilityIdentifier("history.message.\(message.id).body")
            ForEach(message.fields) { field in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(field.name)
                        .accessibilityIdentifier("history.message.\(message.id).field.\(field.id).name")
                    Spacer(minLength: 8)
                    Text(field.value)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("history.message.\(message.id).field.\(field.id).value")
                }
                .font(.caption)
                .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .contain)
    }

    private var messageSymbol: String {
        switch message.level.lowercased() {
        case "success": "checkmark.circle.fill"
        case "warning": "exclamationmark.triangle.fill"
        case "error", "failure": "xmark.octagon.fill"
        default: "info.circle.fill"
        }
    }

    private var messageColor: Color {
        switch message.level.lowercased() {
        case "success": .green
        case "warning": .orange
        case "error", "failure": .red
        default: .blue
        }
    }
}

#Preview("Active Runs · Light") {
    NavigationStack { ActiveRunsView() }
        .environment(PreviewFixtures.store())
}

#Preview("History · Dark · Large Type") {
    NavigationStack { RunHistoryView() }
        .environment(PreviewFixtures.store())
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("History · Selected Machine") {
    NavigationStack {
        RunHistoryView(initialMachineID: PreviewFixtures.ciMachine.id)
    }
    .environment(PreviewFixtures.store())
}
