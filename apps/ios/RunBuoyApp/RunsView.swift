import Foundation
import SwiftUI

enum ActiveRunsPresentation {
    @MainActor
    static func ordered(_ models: [RunSummaryModel]) -> [RunSummaryModel] {
        models.sorted { isOrderedBefore($0.snapshot, $1.snapshot) }
    }

    static func orderedSnapshots(_ runs: [RunSnapshot]) -> [RunSnapshot] {
        runs.sorted(by: isOrderedBefore)
    }

    static func summary(for runs: [RunSnapshot]) -> ActiveRunSystemSummary? {
        guard let lastConfirmed = runs.map(\.updatedAt).max() else { return nil }
        return ActiveRunSystemSummary(
            activeCount: runs.count,
            needsAttentionCount: runs.filter(needsAttention).count,
            lastConfirmed: lastConfirmed
        )
    }

    private static func isOrderedBefore(_ lhs: RunSnapshot, _ rhs: RunSnapshot) -> Bool {
        let lhsRank = priorityRank(lhs)
        let rhsRank = priorityRank(rhs)
        if lhsRank != rhsRank { return lhsRank < rhsRank }
        if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt > rhs.updatedAt }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private static func priorityRank(_ run: RunSnapshot) -> Int {
        if run.attentionStatus == .actionRequired { return 0 }
        if run.attentionStatus == .warning { return 1 }
        if run.healthStatus != .healthy { return 2 }
        if run.executionStatus.isActive { return 3 }
        return 4
    }

    private static func needsAttention(_ run: RunSnapshot) -> Bool {
        run.healthStatus != .healthy
            || run.attentionStatus == .warning
            || run.attentionStatus == .actionRequired
    }
}

struct ActiveRunSystemSummary: Equatable {
    let activeCount: Int
    let needsAttentionCount: Int
    let lastConfirmed: Date

    var allHealthy: Bool { needsAttentionCount == 0 }
}

struct ActiveRunsView: View {
    @Environment(RunBuoyStore.self) private var store

    private var orderedModels: [RunSummaryModel] {
        ActiveRunsPresentation.ordered(store.activeRunModels)
    }

    private var isEmpty: Bool { orderedModels.isEmpty }

    private var isOfflineCached: Bool {
        if case .offline = store.state { return true }
        return false
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if case .offline(let message) = store.state {
                    OfflineBanner(message: message)
                }

                if store.state == .loading, isEmpty {
                    ActiveRunsLoadingSkeleton()
                } else if isEmpty {
                    ActiveRunsEmptyState(state: store.state, retry: refresh)
                        .frame(maxWidth: .infinity, minHeight: 420)
                } else {
                    activeContent
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(RunBuoyTheme.canvas)
        .accessibilityIdentifier("screen.activeRuns")
        .navigationTitle("runs.active")
        .refreshable { await reload() }
        .task { await loadIfNeeded() }
    }

    @ViewBuilder
    private var activeContent: some View {
        if let summary = ActiveRunsPresentation.summary(for: orderedModels.map(\.snapshot)) {
            ActiveRunsSystemSummaryCard(
                summary: summary,
                runs: orderedModels.map(\.snapshot),
                isOfflineCached: isOfflineCached
            )
            .accessibilityIdentifier("activeRuns.systemSummary")
        }

        if let hero = orderedModels.first {
            NavigationLink(value: AppRoute.runDetail(hero.id)) {
                ActiveRunHeroCard(
                    run: hero.snapshot,
                    isOfflineCached: isOfflineCached
                )
                .accessibilityIdentifier("activeRuns.hero")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("run.row.\(hero.id.uuidString.lowercased())")
        }

        if orderedModels.count > 1 {
            Text("active.also_active")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .textCase(.uppercase)
                .padding(.top, 4)

            ForEach(orderedModels.dropFirst()) { model in
                NavigationLink(value: AppRoute.runDetail(model.id)) {
                    ActiveCompactRunCard(
                        run: model.snapshot,
                        isOfflineCached: isOfflineCached
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("run.row.\(model.id.uuidString.lowercased())")
            }
        }
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

private struct ActiveRunsSystemSummaryCard: View {
    let summary: ActiveRunSystemSummary
    let runs: [RunSnapshot]
    let isOfflineCached: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var tone: RunBuoyTone {
        if isOfflineCached { return .warning }
        if runs.contains(where: { $0.attentionStatus == .actionRequired }) { return .critical }
        if !summary.allHealthy { return .warning }
        return .live
    }

    private var symbol: String {
        if isOfflineCached { return "wifi.slash" }
        if tone == .critical { return "exclamationmark.bubble.fill" }
        if tone == .warning { return "exclamationmark.triangle.fill" }
        return "waveform.path.ecg"
    }

    private var headline: String {
        if summary.allHealthy {
            return String(
                format: String(localized: "active.summary.all_healthy"),
                locale: .autoupdatingCurrent,
                summary.activeCount
            )
        }
        return String(
            format: String(localized: "active.summary.needs_attention"),
            locale: .autoupdatingCurrent,
            summary.activeCount,
            summary.needsAttentionCount
        )
    }

    var body: some View {
        SignalCardSurface(tone: tone, usesLiveSurface: tone == .live) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    summarySymbol
                    summaryText
                }
            } else {
                HStack(spacing: 12) {
                    summarySymbol
                    summaryText
                }
            }
        }
    }

    private var summarySymbol: some View {
        Image(systemName: symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(tone.color)
            .frame(width: 22)
            .accessibilityHidden(true)
    }

    private var summaryText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(headline)
                .font(.callout.weight(.semibold))
            (
                Text("active.summary.last_confirmed")
                    + Text(" ")
                    + Text(summary.lastConfirmed, format: .relative(presentation: .named))
            )
            .font(.footnote)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ActiveRunHeroCard: View {
    let run: RunSnapshot
    let isOfflineCached: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visualState: RunStatusVisualState {
        run.listVisualState(isOfflineCached: isOfflineCached)
    }

    var body: some View {
        SignalCardSurface(
            tone: visualState.tone,
            usesLiveSurface: visualState.allowsLiveEmphasis
        ) {
            VStack(alignment: .leading, spacing: 14) {
                header
                machine
                RunProgressView(
                    progress: run.progress,
                    phase: run.phase,
                    visualState: visualState,
                    showsIndeterminate: run.executionStatus.isActive && !isOfflineCached,
                    emphasis: .prominent
                )
                metadata
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                RunStatusBadge(state: visualState, showsLabel: true)
                title
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                RunStatusBadge(state: visualState, showsLabel: true)
                title
            }
        }
    }

    private var title: some View {
        Text(run.title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var machine: some View {
        Label {
            Text(run.machineName)
        } icon: {
            MachineIconImage(machineID: run.machineID)
                .accessibilityHidden(true)
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 6) {
            confirmedRuntime
            lastConfirmed
        }
        .font(.caption)
    }

    private var confirmedRuntime: some View {
        Label {
            (
                Text("run.execution_time")
                    + Text(" ")
                    + Text(RunDurationText.string(from: run.startedAt, to: run.updatedAt))
                    .fontWeight(.semibold)
                    .monospacedDigit()
            )
        } icon: {
            Image(systemName: "timer")
        }
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("run.timing.execution")
    }

    private var lastConfirmed: some View {
        Label {
            (
                Text("active.summary.last_confirmed")
                    + Text(" ")
                    + Text(run.updatedAt, format: .relative(presentation: .named))
                    .fontWeight(.semibold)
                    .monospacedDigit()
            )
        } icon: {
            Image(systemName: "waveform.path.ecg")
        }
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("run.timing.heartbeat")
    }
}

private struct ActiveCompactRunCard: View {
    let run: RunSnapshot
    let isOfflineCached: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visualState: RunStatusVisualState {
        run.listVisualState(isOfflineCached: isOfflineCached)
    }

    var body: some View {
        SignalCardSurface(tone: visualState.tone) {
            VStack(alignment: .leading, spacing: 8) {
                header
                machineAndProgress
                progress
                lastConfirmed
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardRadius))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                RunStatusBadge(state: visualState)
                title
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                RunStatusBadge(state: visualState)
                title
            }
        }
    }

    private var title: some View {
        Text(run.title)
            .font(.headline)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var machineAndProgress: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                machine
                Spacer(minLength: 8)
                trustedProgressSummary
            }
            VStack(alignment: .leading, spacing: 6) {
                machine
                trustedProgressSummary
            }
        }
    }

    private var machine: some View {
        Label {
            Text(run.machineName)
                .lineLimit(1)
                .truncationMode(.tail)
        } icon: {
            MachineIconImage(machineID: run.machineID)
                .accessibilityHidden(true)
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var trustedProgressSummary: some View {
        if let projection = run.progress?.trustedProjection {
            Text(RunListProgressText.summary(projection))
                .font(.caption)
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var progress: some View {
        if let projection = run.progress?.trustedProjection {
            DeterminateRunProgressBar(
                fraction: projection.fraction,
                tone: visualState.tone,
                height: RunBuoyMetrics.compactProgressHeight,
                addsGlow: false
            )
            if let phase = run.phase, !phase.isEmpty {
                Text(phase)
                    .font(.footnote)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
            }
        } else {
            RunProgressView(
                progress: run.progress,
                phase: run.phase,
                visualState: visualState,
                showsIndeterminate: run.executionStatus.isActive && !isOfflineCached,
                emphasis: .compact
            )
        }
    }

    private var lastConfirmed: some View {
        Label {
            HStack(spacing: 4) {
                Text("active.summary.last_confirmed")
                    .foregroundStyle(.primary)
                Text(run.updatedAt, format: .relative(presentation: .named))
                    .fontWeight(.semibold)
            }
        } icon: {
            Image(systemName: "waveform.path.ecg")
                .foregroundStyle(visualState.color)
        }
        .font(.caption)
    }
}

private struct ActiveRunsLoadingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RunSkeletonCard(lineCount: 2)
            RunSkeletonCard(lineCount: 5, isHero: true)
            RunSkeletonCard(lineCount: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("runs.loading")
        .accessibilityIdentifier("activeRuns.loading")
    }
}

private struct RunSkeletonCard: View {
    let lineCount: Int
    var isHero = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<lineCount, id: \.self) { index in
                Capsule()
                    .fill(index == 0 ? RunBuoyTheme.separator : RunBuoyTheme.inactive.opacity(0.13))
                    .frame(maxWidth: index.isMultiple(of: 3) ? 210 : .infinity)
                    .frame(height: index == lineCount - 1 && isHero ? 14 : 12)
            }
        }
        .padding(isHero ? 20 : 16)
        .background(RunBuoyTheme.surface, in: RoundedRectangle(cornerRadius: isHero ? 22 : 16))
        .overlay {
            RoundedRectangle(cornerRadius: isHero ? 22 : 16)
                .stroke(RunBuoyTheme.separator, lineWidth: 1)
        }
        .accessibilityHidden(true)
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

    private var machineOptionIDs: [String] { machineOptions.map(\.id) }

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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if case .offline(let message) = store.state {
                    OfflineBanner(message: message)
                        .padding(.horizontal)
                }

                if !machineOptions.isEmpty {
                    HistoryMachineFilterBar(
                        options: machineOptions,
                        selection: $selectedMachineID
                    )
                }

                if store.state == .loading, isEmpty {
                    HistoryLoadingSkeleton()
                        .padding(.horizontal)
                } else if isEmpty {
                    HistoryEmptyState(
                        state: store.state,
                        machineID: selectedMachineID,
                        machineName: selectedMachineName,
                        retry: refresh
                    )
                    .frame(maxWidth: .infinity, minHeight: 380)
                    .padding(.horizontal)
                } else {
                    historyContent
                }
            }
            .padding(.bottom, 24)
        }
        .background(RunBuoyTheme.canvas)
        .accessibilityIdentifier("screen.history")
        .navigationTitle("history.title")
        .refreshable { await reload() }
        .task { await loadIfNeeded() }
        .onChange(of: selectedMachineID) { _, _ in
            areRunsExpanded = false
            areMessagesExpanded = false
        }
        .onChange(of: machineOptionIDs) { _, availableIDs in
            guard let selectedMachineID, !availableIDs.contains(selectedMachineID) else { return }
            self.selectedMachineID = nil
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        if !filteredRunModels.isEmpty || store.canLoadMoreRuns(machineID: selectedMachineID) {
            HistorySectionHeader("runs.recent")
            VStack(spacing: 8) {
                ForEach(visibleRunModels) { model in
                    NavigationLink(value: AppRoute.runDetail(model.id)) {
                        HistoryRunCard(run: model.snapshot)
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
            .padding(.horizontal)
        }

        if !filteredMessages.isEmpty || store.canLoadMoreMessages(machineID: selectedMachineID) {
            HistorySectionHeader("runs.messages")
                .padding(.top, 4)
            VStack(spacing: 8) {
                ForEach(visibleMessages) { message in
                    RichMessageHistoricalCard(message: message)
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
            .padding(.horizontal)
        }
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

private struct HistorySectionHeader: View {
    let key: LocalizedStringKey

    init(_ key: LocalizedStringKey) {
        self.key = key
    }

    var body: some View {
        Text(key)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.primary)
            .textCase(.uppercase)
            .padding(.horizontal, 24)
    }
}

private struct HistoryRunCard: View {
    let run: RunSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visualState: RunStatusVisualState { run.visualState }

    var body: some View {
        SignalCardSurface(tone: visualState.tone) {
            VStack(alignment: .leading, spacing: 8) {
                header
                machineAndProgress
                if let projection = run.progress?.trustedProjection {
                    DeterminateRunProgressBar(
                        fraction: projection.fraction,
                        tone: visualState.tone,
                        height: RunBuoyMetrics.compactProgressHeight,
                        addsGlow: false
                    )
                }
                footer
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardRadius))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                RunStatusBadge(state: visualState)
                title
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                RunStatusBadge(state: visualState)
                title
            }
        }
    }

    private var title: some View {
        Text(run.title)
            .font(.headline)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var machineAndProgress: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                machine
                Spacer(minLength: 8)
                trustedProgressSummary
            }
            VStack(alignment: .leading, spacing: 6) {
                machine
                trustedProgressSummary
            }
        }
    }

    private var machine: some View {
        Label {
            Text(run.machineName)
                .lineLimit(1)
                .truncationMode(.tail)
        } icon: {
            MachineIconImage(machineID: run.machineID)
                .accessibilityHidden(true)
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var trustedProgressSummary: some View {
        if let projection = run.progress?.trustedProjection {
            Text(RunListProgressText.summary(projection))
                .font(.caption)
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                statusLabel
                Spacer(minLength: 8)
                completionLabel
            }
            VStack(alignment: .leading, spacing: 6) {
                statusLabel
                completionLabel
            }
        }
        .font(.caption)
    }

    private var statusLabel: some View {
        Label {
            Text(visualState.localizedTitle)
        } icon: {
            Image(systemName: visualState.symbol)
        }
        .foregroundStyle(visualState.color)
    }

    private var completionLabel: some View {
        HStack(spacing: 4) {
            Text("run.updated")
            Text(run.endedAt ?? run.updatedAt, format: .relative(presentation: .named))
        }
        .foregroundStyle(.primary)
    }
}

private struct HistoryMachineFilterBar: View {
    let options: [HistoryMachineOption]
    @Binding var selection: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HistoryFilterFlowLayout(spacing: 8) {
            filterButton(id: nil, name: String(localized: "history.all"), showsMachine: false)
            ForEach(options) { option in
                filterButton(id: option.id, name: option.name, showsMachine: true)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func filterButton(id: String?, name: String, showsMachine: Bool) -> some View {
        let isSelected = selection == id
        return Button {
            withAnimation(RunBuoyMotion.selection(reduceMotion: reduceMotion)) {
                selection = id
            }
        } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .accessibilityHidden(true)
                } else if showsMachine, let id {
                    MachineIconImage(machineID: id)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                }
                Text(name)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(minHeight: RunBuoyMetrics.minimumTarget)
            .background(
                isSelected
                    ? RunBuoyTheme.brandPrimary.opacity(contrast == .increased ? 0.22 : 0.14)
                    : (reduceTransparency ? RunBuoyTheme.surface : RunBuoyTheme.surface.opacity(0.92)),
                in: Capsule()
            )
            .overlay {
                Capsule().stroke(
                    isSelected ? RunBuoyTheme.brandPrimary : RunBuoyTheme.separator,
                    lineWidth: isSelected || contrast == .increased ? 1.5 : 1
                )
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(id.map { "history.filter.\($0)" } ?? "history.filter.all")
    }
}

private struct HistoryFilterFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var contentWidth: CGFloat = 0
        var contentHeight: CGFloat = 0

        for subview in subviews {
            let size = measuredSize(of: subview, maximumWidth: maxWidth)
            let proposedWidth = rowWidth == 0 ? size.width : rowWidth + spacing + size.width
            if proposedWidth > maxWidth, rowWidth > 0 {
                contentWidth = max(contentWidth, rowWidth)
                contentHeight += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth = proposedWidth
                rowHeight = max(rowHeight, size.height)
            }
        }

        contentWidth = max(contentWidth, rowWidth)
        contentHeight += rowHeight
        return CGSize(width: proposal.width ?? contentWidth, height: contentHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = measuredSize(of: subview, maximumWidth: bounds.width)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func measuredSize(of subview: LayoutSubview, maximumWidth: CGFloat) -> CGSize {
        let idealSize = subview.sizeThatFits(.unspecified)
        guard idealSize.width > maximumWidth else { return idealSize }
        return subview.sizeThatFits(ProposedViewSize(width: maximumWidth, height: nil))
    }
}

private struct RichMessageHistoricalCard: View {
    let message: RichMessage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var presentation: RichMessagePresentation {
        RichMessagePresentation(level: message.level)
    }

    var body: some View {
        SignalCardSurface(tone: presentation.tone) {
            VStack(alignment: .leading, spacing: 7) {
                header
                if let subtitle = message.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                }
                Text(message.body)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                ForEach(message.fields) { field in
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(field.name)
                            Spacer(minLength: 8)
                            Text(field.value)
                                .multilineTextAlignment(.trailing)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(field.name)
                            Text(field.value).fontWeight(.semibold)
                        }
                    }
                    .font(dynamicTypeSize.isAccessibilitySize ? .subheadline : .caption)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            HStack(alignment: .top, spacing: 8) {
                messageSymbol
                VStack(alignment: .leading, spacing: 2) {
                    messageTitle
                    relativeTime
                }
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                messageSymbol
                messageTitle
                Spacer(minLength: 8)
                relativeTime
            }
        }
    }

    private var messageSymbol: some View {
        Image(systemName: presentation.symbol)
            .foregroundStyle(presentation.tone.color)
            .accessibilityHidden(true)
    }

    private var messageTitle: some View {
        Text(message.title)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var relativeTime: some View {
        Text(message.createdAt, format: .relative(presentation: .named))
            .font(.caption)
            .foregroundStyle(.primary)
    }
}

private struct RichMessagePresentation {
    let tone: RunBuoyTone
    let symbol: String

    init(level: String) {
        switch level.lowercased() {
        case "success":
            tone = .success
            symbol = "checkmark.circle.fill"
        case "warning":
            tone = .warning
            symbol = "exclamationmark.triangle.fill"
        case "critical", "error", "failure":
            tone = .critical
            symbol = "xmark.octagon.fill"
        default:
            tone = .live
            symbol = "info.circle.fill"
        }
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
                    ProgressView().controlSize(.small)
                }
                Text(isLoading ? "history.loading_more" : "history.load_more")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: RunBuoyMetrics.minimumTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
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
                .frame(maxWidth: .infinity, minHeight: RunBuoyMetrics.minimumTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(label)
            .accessibilityIdentifier(
                isExpanded ? "history.expansion.collapse" : "history.expansion.expand"
            )
        }
    }

    private var label: String {
        if isExpanded { return String(localized: "history.show_less") }
        return String(format: String(localized: "history.show_remaining"), remainingCount)
    }

    private func toggleExpansion() {
        withAnimation(RunBuoyMotion.stateChange(reduceMotion: reduceMotion)) {
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
        return serverNamesByID.map { HistoryMachineOption(id: $0.key, name: $0.value) }
            .sorted { lhs, rhs in
                let comparison = lhs.name.localizedStandardCompare(rhs.name)
                return comparison == .orderedSame ? lhs.id < rhs.id : comparison == .orderedAscending
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
                Button("common.try_again", action: retry)
                    .runBuoyProminentButtonStyle()
            }
        }
        .padding()
        .accessibilityIdentifier(state.isFailure ? "activeRuns.state.failed" : "activeRuns.state.empty")
    }

    private var title: LocalizedStringKey {
        state.isFailure ? "runs.unavailable" : "runs.active_empty"
    }

    private var description: LocalizedStringKey {
        state.isFailure ? "runs.pull_to_refresh" : "runs.active_empty_description"
    }

    private var symbol: String {
        state.isFailure ? "exclamationmark.icloud" : "checkmark.circle"
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
                if let machineID, !state.isFailure {
                    MachineIconImage(machineID: machineID)
                } else {
                    Image(systemName: state.isFailure ? "exclamationmark.icloud" : "clock.arrow.circlepath")
                }
            }
        } description: {
            Text(description)
        } actions: {
            if state.isFailure {
                Button("common.try_again", action: retry)
                    .runBuoyProminentButtonStyle()
            }
        }
        .padding()
    }

    private var title: String {
        if state.isFailure { return String(localized: "runs.unavailable") }
        if let machineName {
            return String(format: String(localized: "history.filtered_empty"), machineName)
        }
        return String(localized: "history.empty")
    }

    private var description: String {
        if state.isFailure { return String(localized: "runs.pull_to_refresh") }
        if machineName == nil {
            return String(localized: "history.empty_description")
        }
        return String(localized: "history.filtered_empty_description")
    }
}

private struct HistoryLoadingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RunSkeletonCard(lineCount: 4)
            RunSkeletonCard(lineCount: 4)
            RunSkeletonCard(lineCount: 5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("history.loading")
    }
}

private struct SignalCardSurface<Content: View>: View {
    let tone: RunBuoyTone
    let usesLiveSurface: Bool
    let content: Content
    @Environment(\.colorSchemeContrast) private var contrast

    init(
        tone: RunBuoyTone,
        usesLiveSurface: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.usesLiveSurface = usesLiveSurface
        self.content = content()
    }

    var body: some View {
        content
            .padding(usesLiveSurface ? 20 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                usesLiveSurface ? RunBuoyTheme.liveSurface : RunBuoyTheme.surface,
                in: RoundedRectangle(cornerRadius: usesLiveSurface ? 22 : 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: usesLiveSurface ? 22 : 16)
                    .stroke(
                        usesLiveSurface
                            ? RunBuoyTheme.brandLive
                            : (contrast == .increased ? tone.color : RunBuoyTheme.separator),
                        lineWidth: contrast == .increased ? 1.5 : 1
                    )
            }
    }
}

private enum RunListProgressText {
    static func summary(_ progress: TrustedRunProgress) -> String {
        let count = "\(progress.current.formatted()) / \(progress.total.formatted())"
        let unitCount = progress.unit.map { "\(count) \($0)" } ?? count
        let percentage = progress.fraction.formatted(.percent.precision(.fractionLength(0)))
        return "\(unitCount) · \(percentage)"
    }
}

private extension RunSnapshot {
    func listVisualState(isOfflineCached: Bool) -> RunStatusVisualState {
        RunStatusVisualState.resolve(
            executionStatus: executionStatus.rawValue,
            healthStatus: healthStatus.rawValue,
            attentionStatus: attentionStatus.rawValue,
            isStale: isOfflineCached
        )
    }
}

private extension RunBuoyStore.LoadState {
    var isFailure: Bool {
        if case .failed = self { return true }
        return false
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
