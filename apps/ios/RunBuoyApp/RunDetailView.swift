import SwiftUI
import UIKit

struct RunDetailView: View {
    let runID: UUID
    @Environment(RunBuoyStore.self) private var store
    @State private var detail: RunDetail?
    @State private var errorMessage: String?

    private var presentedDetail: RunDetail? {
        guard let detail else { return nil }
        guard let latestSnapshot = store.runs.first(where: { $0.id == runID }),
              latestSnapshot.sequence >= detail.run.sequence
        else {
            return detail
        }
        return RunDetail(run: latestSnapshot, feed: detail.feed)
    }

    private var cachedDetail: RunDetail? {
        store.runs.first(where: { $0.id == runID }).map {
            RunDetail(run: $0, feed: [])
        }
    }

    private var connectivityMessage: String? {
        if let errorMessage {
            return errorMessage
        }
        if case .offline(let message) = store.state {
            return message
        }
        return nil
    }

    var body: some View {
        Group {
            if let detail = presentedDetail ?? cachedDetail {
                RunDetailContent(
                    detail: detail,
                    connectivityMessage: connectivityMessage
                )
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("run.unavailable", systemImage: "exclamationmark.icloud")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("common.try_again") {
                        Task { await load() }
                    }
                    .runBuoyProminentButtonStyle()
                }
                .accessibilityIdentifier("run.unavailable")
            } else {
                RunDetailLoadingView()
            }
        }
        .runBuoyCanvas()
        .accessibilityIdentifier("screen.runDetail")
        .navigationTitle("run.detail_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task(id: runID) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            let loadedDetail = try await store.detail(for: runID)
            guard !Task.isCancelled else { return }
            if let detail, loadedDetail.run.sequence < detail.run.sequence {
                return
            }
            detail = loadedDetail
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct RunDetailContent: View {
    let detail: RunDetail
    var connectivityMessage: String?
    private let orderedFeed: [RunFeedEvent]
    private let safeLogLines: [SafeLogLine]
    @AppStorage("runbuoy.safe-messages-enabled") private var safeMessagesEnabled = true
    @State private var technicalDetailsExpanded = false

    init(detail: RunDetail, connectivityMessage: String? = nil) {
        self.detail = detail
        self.connectivityMessage = connectivityMessage
        orderedFeed = detail.feed.sorted { $0.sequence < $1.sequence }
        safeLogLines = (detail.run.safeLogTail ?? []).enumerated().map {
            SafeLogLine(id: $0.offset, text: $0.element)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                RunDetailHero(run: detail.run)

                if let banner = stateBanner {
                    RunStateBanner(tone: banner.tone, symbol: banner.symbol) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(banner.title)
                                .font(.headline)
                            Text(banner.message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("run.stateBanner")
                }

                if let safeMessage {
                    LatestConfirmedUpdateCard(
                        phase: detail.run.phase,
                        message: safeMessage,
                        confirmedAt: detail.run.updatedAt,
                        tone: detail.run.statusVisualState.tone
                    )
                }

                RunDetailMetrics(run: detail.run)

                TechnicalDetailsCard(
                    run: detail.run,
                    feed: orderedFeed,
                    safeLogLines: safeLogLines,
                    showsSafeMessages: safeMessagesEnabled,
                    isExpanded: $technicalDetailsExpanded
                )
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .runBuoyBottomScrollEdgeStyle()
        .safeAreaInset(edge: .bottom) {
            if RunDetailSummaryActionsPolicy.isAvailable(detail: detail) {
                RunDetailActionBar(
                    run: detail.run,
                    includesSafeMessage: safeMessagesEnabled
                )
            }
        }
    }

    private var safeMessage: String? {
        guard safeMessagesEnabled else { return nil }
        return detail.run.safeMessage?.trimmedNonempty
    }

    private var stateBanner: RunDetailBanner? {
        if let connectivityMessage {
            return RunDetailBanner(
                tone: .warning,
                symbol: "wifi.slash",
                title: "runs.cached_data",
                message: connectivityMessage
            )
        }

        let state = detail.run.statusVisualState
        switch state.kind {
        case .stale:
            return RunDetailBanner(
                tone: .warning,
                symbol: state.symbolName,
                title: "health.stale",
                message: String(localized: "run.state.stale")
            )
        case .offline:
            return RunDetailBanner(
                tone: .warning,
                symbol: state.symbolName,
                title: "health.offline",
                message: String(localized: "run.state.offline")
            )
        case .cancelled:
            return RunDetailBanner(
                tone: .neutral,
                symbol: state.symbolName,
                title: "status.cancelled",
                message: String(localized: "run.state.cancelled")
            )
        case .actionRequired:
            return RunDetailBanner(
                tone: .critical,
                symbol: state.symbolName,
                title: "attention.action_required",
                message: String(localized: "run.state.action_required")
            )
        case .warning:
            return RunDetailBanner(
                tone: .warning,
                symbol: state.symbolName,
                title: "attention.warning",
                message: String(localized: "run.state.warning")
            )
        default:
            return nil
        }
    }
}

private struct RunDetailLoadingView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ProgressView("run.loading")
                    .frame(maxWidth: .infinity, minHeight: 120)
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: RunBuoyMetrics.cardCornerRadius)
                        .fill(.quaternary)
                        .frame(height: 84)
                }
            }
            .padding()
        }
        .accessibilityIdentifier("run.loading")
    }
}

private struct RunDetailHero: View {
    let run: RunSnapshot
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        RunDetailHeroSurface(status: run.statusVisualState) {
            VStack(alignment: .leading, spacing: 14) {
                header

                Label {
                    Text(run.machineName)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                } icon: {
                    MachineIconImage(machineID: run.machineID)
                        .accessibilityHidden(true)
                }
                .font(.subheadline)

                RunProgressView(
                    progress: run.progress,
                    phase: run.phase,
                    status: run.statusVisualState,
                    emphasis: .prominent
                )

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) {
                        runtime
                        lastConfirmed
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        runtime
                        lastConfirmed
                    }
                }
                .font(.caption)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                statusBadge
                title
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                statusBadge
                title
            }
        }
    }

    private var statusBadge: some View {
        StatusBadge(
            presentation: StatusPresentation(visualState: run.statusVisualState),
            showsLabel: true
        )
    }

    private var title: some View {
        Text(run.title)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var runtime: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("run.elapsed")
                .foregroundStyle(.secondary)
            ConfirmedElapsedText(run: run)
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("run.timing.execution")
    }

    private var lastConfirmed: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("run.last_confirmed")
                .foregroundStyle(.secondary)
            RelativeConfirmedText(date: run.updatedAt)
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("run.timing.heartbeat")
    }
}

private struct RunDetailHeroSurface<Content: View>: View {
    let status: RunStatusVisualState
    @ViewBuilder let content: () -> Content
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .fill(theme.surface)
                if status.kind == .running && status.allowsLiveEmphasis {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(theme.status(.live).opacity(reduceTransparency ? 0.06 : 0.10))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        status.kind == .running
                            ? theme.status(.live)
                            : theme.border(status.tone),
                        lineWidth: contrast == .increased ? 1.5 : 1
                    )
            }
            .shadow(
                color: status.kind == .running && status.allowsLiveEmphasis && !reduceTransparency
                    ? theme.glow(.live)
                    : .clear,
                radius: status.kind == .running ? 10 : 0,
                y: 1
            )
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

private struct LatestConfirmedUpdateCard: View {
    let phase: String?
    let message: String
    let confirmedAt: Date
    let tone: RunBuoyTone
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("run.latest_confirmed_update", systemImage: "waveform.path.ecg")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.status(tone))
            if let phase = phase?.trimmedNonempty {
                Text(phase)
                    .font(.subheadline.weight(.semibold))
            }
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Label {
                RelativeConfirmedText(date: confirmedAt)
            } icon: {
                Image(systemName: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: RunBuoyMetrics.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: RunBuoyMetrics.cardCornerRadius)
                .stroke(theme.border(), lineWidth: contrast == .increased ? 1.5 : 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("run.latestConfirmedUpdate")
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

private struct RunDetailMetrics: View {
    let run: RunSnapshot
    private let columns = [GridItem(.adaptive(minimum: 145), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            RunMetricCard("run.elapsed", symbol: "timer") {
                ConfirmedElapsedText(run: run)
                    .monospacedDigit()
            }
            RunMetricCard("run.last_confirmed", symbol: "waveform.path.ecg") {
                RelativeConfirmedText(date: run.updatedAt)
            }
            RunMetricCard("run.started", symbol: "clock") {
                Text(run.startedAt, format: .dateTime.hour().minute())
            }
            if let endedAt = run.endedAt {
                RunMetricCard("run.ended", symbol: "stop.circle") {
                    Text(endedAt, format: .dateTime.hour().minute())
                }
            } else {
                RunMetricCard("run.updated", symbol: "clock.arrow.circlepath") {
                    Text(run.updatedAt, format: .dateTime.hour().minute())
                }
            }
        }
        .accessibilityIdentifier("run.metrics")
    }
}

private struct TechnicalDetailsCard: View {
    let run: RunSnapshot
    let feed: [RunFeedEvent]
    let safeLogLines: [SafeLogLine]
    let showsSafeMessages: Bool
    @Binding var isExpanded: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 16) {
                Divider()
                runIdentifier
                timingDetails
                if !feed.isEmpty {
                    feedDetails
                }
                if !safeLogLines.isEmpty {
                    safeLogDetails
                }
                safetyBoundary
            }
            .padding(.top, 8)
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("run.technical_details")
                        .font(.headline)
                    Spacer(minLength: 8)
                    Text("run.safe_fields_only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("run.technical_details")
                        .font(.headline)
                    Text("run.safe_fields_only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.primary)
        .padding(16)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: RunBuoyMetrics.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: RunBuoyMetrics.cardCornerRadius)
                .stroke(theme.border(), lineWidth: contrast == .increased ? 1.5 : 1)
        }
        .accessibilityIdentifier("run.technicalDetails")
    }

    private var runIdentifier: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("run.identifier")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(run.id.uuidString.lowercased())
                .font(.caption.monospaced())
                .textSelection(.enabled)
            Button(action: copyID) {
                Label("run.copy_id", systemImage: "doc.on.doc")
            }
            .runBuoySecondaryButtonStyle()
            .accessibilityIdentifier("run.copyID")
        }
    }

    private var timingDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("run.elapsed")
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    ConfirmedElapsedText(run: run)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("run.elapsed")
                        .foregroundStyle(.secondary)
                    ConfirmedElapsedText(run: run)
                }
            }
            .font(.subheadline)
            .accessibilityElement(children: .combine)
            technicalRow("run.started", value: run.startedAt.formatted(date: .abbreviated, time: .standard))
            technicalRow("run.updated", value: run.updatedAt.formatted(date: .abbreviated, time: .standard))
            if let endedAt = run.endedAt {
                technicalRow("run.ended", value: endedAt.formatted(date: .abbreviated, time: .standard))
            }
            if let exitCode = run.exitCode {
                technicalRow("run.exit_code", value: exitCode.formatted())
            }
        }
    }

    private var feedDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("run.feed")
                .font(.headline)
            ForEach(feed) { event in
                RunFeedRow(event: event, showsMessage: showsSafeMessages)
            }
        }
    }

    private var safeLogDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("run.safe_log_tail")
                .font(.headline)
            ForEach(safeLogLines) { line in
                Text(line.text)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
            Text("run.safe_log_tail_notice")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var safetyBoundary: some View {
        Label("run.safety_boundary", systemImage: "hand.raised.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func technicalRow(_ title: LocalizedStringKey, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(value)
                    .multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .foregroundStyle(.secondary)
                Text(value)
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private func copyID() {
        UIPasteboard.general.string = run.id.uuidString.lowercased()
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

private struct ConfirmedElapsedText: View {
    let run: RunSnapshot

    var body: some View {
        if let end = RunDetailTiming.elapsedEndDate(for: run) {
            durationText(to: end)
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                durationText(to: context.date)
            }
        }
    }

    private func durationText(to end: Date) -> some View {
        Text(RunDurationText.string(from: run.startedAt, to: end))
            .monospacedDigit()
    }
}

private struct RelativeConfirmedText: View {
    let date: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
            Text(date, format: .relative(presentation: .named))
        }
    }
}

private struct RunDetailActionBar: View {
    let run: RunSnapshot
    let includesSafeMessage: Bool

    private var summary: String {
        SafeRunSummary.text(
            for: run,
            includesSafeMessage: includesSafeMessage
        )
    }

    var body: some View {
        RunSummaryActionBar {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    copySummaryButton
                    shareSummaryButton
                }
                VStack(spacing: 8) {
                    shareSummaryButton
                    copySummaryButton
                }
            }
        }
        .accessibilityIdentifier("run.summaryActions")
    }

    private var copySummaryButton: some View {
        Button(action: copySummary) {
            Label("run.copy_summary", systemImage: "doc.on.doc")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .runBuoySecondaryButtonStyle()
        .accessibilityIdentifier("run.copySummary")
    }

    private var shareSummaryButton: some View {
        ShareLink(item: summary) {
            Label("run.share_summary", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .runBuoyProminentButtonStyle()
        .accessibilityIdentifier("run.shareSummary")
    }

    private func copySummary() {
        UIPasteboard.general.string = summary
    }
}

struct RunFeedRow: View {
    let event: RunFeedEvent
    var showsMessage = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.occurredAt, format: .dateTime.hour().minute())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel(event.occurredAt.formatted(date: .omitted, time: .shortened))
            Image(systemName: symbol)
                .foregroundStyle(.tint)
                .frame(width: 18)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(eventTitle)
                    .font(.subheadline.weight(.semibold))
                if let phase = event.phase?.trimmedNonempty {
                    Text(phase)
                }
                if showsMessage, let message = event.message?.trimmedNonempty {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
                if let progress = event.progress, let fraction = progress.boundedFraction {
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.monospacedDigit())
                }
            }
            .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }

    private var eventTitle: LocalizedStringKey {
        switch event.type {
        case "run.created": "event.created"
        case "run.starting": "event.starting"
        case "run.started": "event.started"
        case "run.progress": "event.progress"
        case "run.phase_changed": "event.phase"
        case "run.message": "event.message"
        case "run.attention_required": "event.attention"
        case "run.heartbeat": "event.heartbeat"
        case "run.succeeded": "event.succeeded"
        case "run.failed": "event.failed"
        case "run.cancelled": "event.cancelled"
        case "run.lost": "event.lost"
        default: "event.updated"
        }
    }

    private var symbol: String {
        switch event.type {
        case "run.succeeded": "checkmark.circle.fill"
        case "run.failed": "xmark.octagon.fill"
        case "run.attention_required": "exclamationmark.triangle.fill"
        case "run.progress": "chart.bar.fill"
        case "run.phase_changed": "flag.fill"
        case "run.message": "text.bubble.fill"
        default: "circle.fill"
        }
    }
}

struct SafeRunSummary {
    static func text(
        for run: RunSnapshot,
        includesSafeMessage: Bool,
        locale: Locale = .current
    ) -> String {
        var lines = [
            line("run.summary.title", value: run.title, locale: locale),
            line("machine.name", value: run.machineName, locale: locale),
            line(
                "run.summary.execution",
                value: localizedExecution(run.executionStatus, locale: locale),
                locale: locale
            )
        ]

        if let phase = run.phase?.trimmedNonempty {
            lines.append(line("run.phase", value: phase, locale: locale))
        }

        let progress = run.progressVisualState
        if progress.kind == .determinate,
           let current = progress.current,
           let total = progress.total {
            var value = "\(current.formatted(.number.locale(locale))) / \(total.formatted(.number.locale(locale)))"
            if let unit = run.progress?.unit?.trimmedNonempty {
                value += " \(unit)"
            }
            lines.append(line("run.progress", value: value, locale: locale))
        }

        let confirmed = run.updatedAt.formatted(
            .dateTime
                .year()
                .month()
                .day()
                .hour()
                .minute()
                .second()
                .locale(locale)
        )
        lines.append(line("run.last_confirmed", value: confirmed, locale: locale))

        if includesSafeMessage,
           let safeMessage = run.safeMessage?.trimmedNonempty {
            lines.append(line("run.safe_message", value: safeMessage, locale: locale))
        }

        return lines.joined(separator: "\n")
    }

    private static func line(_ key: String.LocalizationValue, value: String, locale: Locale) -> String {
        "\(String(localized: key, locale: locale)): \(value)"
    }

    private static func localizedExecution(_ status: ExecutionStatus, locale: Locale) -> String {
        let key: String.LocalizationValue = switch status {
        case .created: "status.created"
        case .starting: "status.starting"
        case .running: "status.running"
        case .succeeded: "status.succeeded"
        case .failed: "status.failed"
        case .cancelled: "status.cancelled"
        case .lost: "status.lost"
        case .unknown: "status.unknown"
        }
        return String(localized: key, locale: locale)
    }
}

enum RunDetailSummaryActionsPolicy {
    static func isAvailable(detail: RunDetail?) -> Bool {
        detail != nil
    }
}

enum RunDetailTiming {
    static func elapsedEndDate(for run: RunSnapshot) -> Date? {
        if let endedAt = run.endedAt {
            return endedAt
        }
        if run.executionStatus.isTerminal
            || run.healthStatus == .stale
            || run.healthStatus == .offline
            || !run.executionStatus.isActive {
            return run.updatedAt
        }
        return nil
    }
}

private struct RunDetailBanner {
    let tone: RunBuoyTone
    let symbol: String
    let title: LocalizedStringKey
    let message: String
}

private struct SafeLogLine: Identifiable {
    let id: Int
    let text: String
}

private extension String {
    var trimmedNonempty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview("Long English") {
    NavigationStack {
        RunDetailContent(detail: PreviewFixtures.longEnglishDetail)
    }
}

#Preview("简体中文 · 辅助功能字号") {
    NavigationStack {
        RunDetailContent(detail: PreviewFixtures.longChineseDetail)
    }
    .environment(\.locale, Locale(identifier: "zh-Hans"))
    .environment(\.dynamicTypeSize, .accessibility4)
}
