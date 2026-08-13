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
        guard let cached = store.runs.first(where: { $0.id == runID }) else { return nil }
        return RunDetail(run: cached, feed: [])
    }

    private var offlineStateMessage: String? {
        if let errorMessage { return errorMessage }
        if case let .offline(message) = store.state { return message }
        return nil
    }

    var body: some View {
        Group {
            if let detail = presentedDetail ?? cachedDetail {
                RunDetailContent(
                    detail: detail,
                    isOfflineCached: offlineStateMessage != nil,
                    offlineMessage: offlineStateMessage
                )
            } else if let errorMessage {
                RunDetailUnavailableView(message: errorMessage) {
                    Task { await load() }
                }
            } else {
                RunDetailLoadingView()
            }
        }
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
            if let detail, loadedDetail.run.sequence < detail.run.sequence { return }
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
    var isOfflineCached = false
    var offlineMessage: String?
    @AppStorage("runbuoy.safe-messages-enabled") private var safeMessagesEnabled = true

    private var visualState: RunStatusVisualState {
        if isOfflineCached {
            return RunStatusVisualState.resolve(
                executionStatus: detail.run.executionStatus.rawValue,
                healthStatus: HealthStatus.offline.rawValue,
                attentionStatus: detail.run.attentionStatus.rawValue
            )
        }
        return detail.run.visualState
    }

    private var safeFeed: [RunFeedEvent] {
        detail.feed
            .filter(\.isSafeDetailEvent)
            .sorted { $0.sequence < $1.sequence }
    }

    private var latestUpdate: RunConfirmedUpdate? {
        if safeMessagesEnabled,
           let message = detail.run.safeMessage?.nilIfEmpty {
            return RunConfirmedUpdate(
                phase: detail.run.phase?.nilIfEmpty,
                message: message,
                occurredAt: detail.run.updatedAt
            )
        }
        guard safeMessagesEnabled,
              let event = safeFeed.last(where: { $0.message?.nilIfEmpty != nil }),
              let message = event.message?.nilIfEmpty
        else {
            return nil
        }
        return RunConfirmedUpdate(
            phase: event.phase?.nilIfEmpty,
            message: message,
            occurredAt: event.occurredAt
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                RunDetailHeroCard(
                    run: detail.run,
                    visualState: visualState,
                    isOfflineCached: isOfflineCached
                )

                if let banner = RunStateBannerDescriptor(
                    visualState: visualState,
                    offlineMessage: offlineMessage
                ) {
                    RunDetailStateBanner(descriptor: banner)
                }

                if let latestUpdate {
                    RunLatestConfirmedUpdateCard(update: latestUpdate)
                }

                RunDetailMetrics(run: detail.run, isOfflineCached: isOfflineCached)

                RunTechnicalDetailsCard(run: detail.run, safeFeed: safeFeed)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(RunBuoyTheme.canvas)
        .runBuoyBottomScrollEdgeStyle()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RunDetailActionBar(summary: SafeRunSummary(run: detail.run))
        }
    }
}

struct SafeRunSummary: Equatable, Sendable {
    let title: String
    let machine: String
    let executionStatus: ExecutionStatus
    let phase: String?
    let progress: TrustedRunProgress?
    let lastConfirmed: Date
    let safeMessage: String?

    init(run: RunSnapshot) {
        title = run.title
        machine = run.machineName
        executionStatus = run.executionStatus
        phase = run.phase?.nilIfEmpty
        progress = run.progress?.trustedProjection
        lastConfirmed = run.updatedAt
        safeMessage = run.safeMessage?.nilIfEmpty
    }

    func rendered(locale: Locale = .current) -> String {
        var lines = [
            formatted("run.summary.title", value: title, locale: locale),
            formatted("run.summary.machine", value: machine, locale: locale),
            formatted(
                "run.summary.status",
                value: executionStatus.localizedTitle(locale: locale),
                locale: locale
            )
        ]

        if let phase {
            lines.append(formatted("run.summary.phase", value: phase, locale: locale))
        }
        if let progress {
            let count = [
                progress.current.formatted(.number.locale(locale)),
                progress.total.formatted(.number.locale(locale))
            ].joined(separator: " / ")
            let value = [count, progress.unit].compactMap { $0?.nilIfEmpty }.joined(separator: " ")
            lines.append(formatted("run.summary.progress", value: value, locale: locale))
        }

        let timestamp = lastConfirmed.formatted(
            .dateTime.year().month().day().hour().minute().locale(locale)
        )
        lines.append(formatted("run.summary.last_confirmed", value: timestamp, locale: locale))

        if let safeMessage {
            lines.append(formatted("run.summary.message", value: safeMessage, locale: locale))
        }
        return lines.joined(separator: "\n")
    }

    private func formatted(_ key: String, value: String, locale: Locale) -> String {
        let format: String
        switch key {
        case "run.summary.title": format = String(localized: "run.summary.title", locale: locale)
        case "run.summary.machine": format = String(localized: "run.summary.machine", locale: locale)
        case "run.summary.status": format = String(localized: "run.summary.status", locale: locale)
        case "run.summary.phase": format = String(localized: "run.summary.phase", locale: locale)
        case "run.summary.progress": format = String(localized: "run.summary.progress", locale: locale)
        case "run.summary.last_confirmed": format = String(localized: "run.summary.last_confirmed", locale: locale)
        case "run.summary.message": format = String(localized: "run.summary.message", locale: locale)
        default: format = "%@"
        }
        guard format.contains("%@") else { return "\(format): \(value)" }
        return String(format: format, locale: locale, value)
    }
}

private struct RunConfirmedUpdate {
    let phase: String?
    let message: String
    let occurredAt: Date
}

private struct RunDetailHeroCard: View {
    let run: RunSnapshot
    let visualState: RunStatusVisualState
    let isOfflineCached: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RunStatusBadge(state: visualState, showsLabel: true)

            VStack(alignment: .leading, spacing: 7) {
                Text(run.title)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Label {
                    Text(run.machineName)
                } icon: {
                    MachineIconImage(machineID: run.machineID)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }

            RunProgressView(
                progress: run.progress,
                phase: run.phase,
                visualState: visualState,
                showsIndeterminate: run.executionStatus.isActive && !isOfflineCached,
                emphasis: .prominent
            )

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 20) { timingContent }
                VStack(alignment: .leading, spacing: 10) { timingContent }
            }
        }
        .padding(20)
        .runDetailCard(
            radius: RunBuoyMetrics.heroCardRadius,
            tone: visualState.tone,
            liveSurface: visualState.allowsLiveEmphasis && !isOfflineCached
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var timingContent: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text("run.execution_time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                RunElapsedValue(
                    startedAt: run.startedAt,
                    endedAt: run.endedAt,
                    frozenAt: isOfflineCached ? run.updatedAt : nil
                )
            }
        } icon: {
            Image(systemName: "timer")
        }
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text("run.last_confirmed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(run.updatedAt, format: .relative(presentation: .named))
            }
        } icon: {
            Image(systemName: "checkmark.circle")
        }
    }
}

private struct RunStateBannerDescriptor {
    let state: RunStatusVisualState
    let bodyKey: LocalizedStringKey
    let detail: String?

    init?(visualState: RunStatusVisualState, offlineMessage: String?) {
        state = visualState
        detail = offlineMessage
        switch visualState.category {
        case .offline: bodyKey = "run.state.offline_body"
        case .stale: bodyKey = "run.state.stale_body"
        case .warning: bodyKey = "run.state.warning_body"
        case .actionRequired: bodyKey = "run.state.action_required_body"
        case .failed: bodyKey = "run.state.failed_body"
        case .cancelled: bodyKey = "run.state.cancelled_body"
        case .lost: bodyKey = "run.state.lost_body"
        default: return nil
        }
    }
}

private struct RunDetailStateBanner: View {
    let descriptor: RunStateBannerDescriptor
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: descriptor.state.symbol)
                .font(.headline)
                .foregroundStyle(descriptor.state.color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(descriptor.state.localizedTitle)
                    .font(.headline)
                Text(descriptor.bodyKey)
                    .foregroundStyle(.secondary)
                if let detail = descriptor.detail?.nilIfEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RunBuoyMetrics.cardPadding)
        .background(
            reduceTransparency
                ? RunBuoyTheme.elevatedSurface
                : descriptor.state.color.opacity(contrast == .increased ? 0.15 : 0.09),
            in: RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardRadius)
                .stroke(descriptor.state.color, lineWidth: RunBuoyMetrics.semanticStrokeWidth)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct RunLatestConfirmedUpdateCard: View {
    let update: RunConfirmedUpdate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("run.latest_confirmed_update", systemImage: "checkmark.message.fill")
                .font(.headline)
                .foregroundStyle(RunBuoyTheme.brandPrimary)
            if let phase = update.phase {
                Text(phase)
                    .font(.subheadline.weight(.semibold))
            }
            Text(update.message)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text(update.occurredAt, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RunBuoyMetrics.cardPadding)
        .runDetailCard(radius: RunBuoyMetrics.compactCardRadius)
        .accessibilityElement(children: .combine)
    }
}

private struct RunDetailMetrics: View {
    let run: RunSnapshot
    let isOfflineCached: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let column = GridItem(.flexible(), spacing: 10, alignment: .topLeading)
        return dynamicTypeSize.isAccessibilitySize ? [column] : [column, column]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            RunMetricCard(title: "run.execution_time", symbol: "timer") {
                RunElapsedValue(
                    startedAt: run.startedAt,
                    endedAt: run.endedAt,
                    frozenAt: isOfflineCached ? run.updatedAt : nil
                )
            }
            RunMetricCard(title: "run.updated", symbol: "checkmark.circle") {
                Text(run.updatedAt, format: .relative(presentation: .named))
            }
            RunMetricCard(title: "run.started", symbol: "play.circle") {
                Text(run.startedAt, format: .dateTime.month().day().hour().minute())
            }
            if let endedAt = run.endedAt {
                RunMetricCard(title: "run.ended", symbol: "stop.circle") {
                    Text(endedAt, format: .dateTime.month().day().hour().minute())
                }
            } else {
                RunMetricCard(title: "run.last_confirmed", symbol: "clock.badge.checkmark") {
                    Text(run.updatedAt, format: .dateTime.hour().minute())
                }
            }
        }
    }
}

private struct RunMetricCard<Value: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    @ViewBuilder let value: () -> Value

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            value()
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
        .padding(14)
        .background(
            RunBuoyTheme.elevatedSurface,
            in: RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardRadius)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct RunElapsedValue: View {
    let startedAt: Date
    let endedAt: Date?
    let frozenAt: Date?

    var body: some View {
        if let end = endedAt ?? frozenAt {
            duration(to: end)
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                duration(to: context.date)
            }
        }
    }

    private func duration(to end: Date) -> some View {
        Text(RunDurationText.string(from: startedAt, to: end))
            .monospacedDigit()
    }
}

private struct RunTechnicalDetailsCard: View {
    let run: RunSnapshot
    let safeFeed: [RunFeedEvent]
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 14) {
                Divider()
                DetailValueRow("run.identifier") {
                    Text(run.id.uuidString.lowercased())
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
                Button(action: copyID) {
                    Label("run.copy_id", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: RunBuoyMetrics.minimumTarget)
                }
                .runBuoySecondaryButtonStyle()
                .accessibilityIdentifier("run.copyID")

                DetailValueRow("run.started") {
                    Text(run.startedAt, format: .dateTime)
                }
                DetailValueRow("run.updated") {
                    Text(run.updatedAt, format: .dateTime)
                }
                if let endedAt = run.endedAt {
                    DetailValueRow("run.ended") {
                        Text(endedAt, format: .dateTime)
                    }
                }
                if let exitCode = run.exitCode {
                    DetailValueRow("run.exit_code") {
                        Text(exitCode, format: .number)
                    }
                }

                if !safeFeed.isEmpty {
                    Divider()
                    Text("run.feed")
                        .font(.headline)
                    ForEach(safeFeed) { event in
                        RunFeedRow(event: event)
                        if event.id != safeFeed.last?.id { Divider() }
                    }
                }

                Text("run.technical_details_notice")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 10)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text("run.technical_details")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("run.safe_fields_only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
        .padding(RunBuoyMetrics.cardPadding)
        .runDetailCard(radius: RunBuoyMetrics.compactCardRadius)
        .animation(RunBuoyMotion.stateChange(reduceMotion: reduceMotion), value: isExpanded)
        .accessibilityIdentifier("run.technicalDetails")
    }

    private func copyID() {
        UIPasteboard.general.string = run.id.uuidString.lowercased()
    }
}

private struct DetailValueRow<Value: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let value: () -> Value
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(_ title: LocalizedStringKey, @ViewBuilder value: @escaping () -> Value) {
        self.title = title
        self.value = value
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) { labels }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(title)
                    Spacer(minLength: 8)
                    value()
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var labels: some View {
        Text(title)
            .foregroundStyle(.secondary)
        value()
    }
}

private struct RunDetailActionBar: View {
    let summary: SafeRunSummary
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { actions }
            VStack(spacing: 10) { actions }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            if reduceTransparency {
                RunBuoyTheme.surface
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
        .overlay(alignment: .top) {
            if contrast == .increased || reduceTransparency { Divider() }
        }
    }

    @ViewBuilder
    private var actions: some View {
        Button(action: copySummary) {
            Label("run.copy_summary", systemImage: "doc.on.doc")
                .frame(maxWidth: .infinity, minHeight: RunBuoyMetrics.minimumTarget)
        }
        .runBuoySecondaryButtonStyle()
        .accessibilityIdentifier("run.copySummary")

        ShareLink(item: summary.rendered()) {
            Label("run.share_summary", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity, minHeight: RunBuoyMetrics.minimumTarget)
        }
        .runBuoyProminentButtonStyle()
        .accessibilityIdentifier("run.shareSummary")
    }

    private func copySummary() {
        UIPasteboard.general.string = summary.rendered()
    }
}

struct RunFeedRow: View {
    let event: RunFeedEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.occurredAt, format: .dateTime.hour().minute())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Image(systemName: symbol)
                .foregroundStyle(.tint)
                .frame(width: 18)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(eventTitle)
                    .font(.subheadline.weight(.semibold))
                if let phase = event.phase?.nilIfEmpty { Text(phase) }
                if let message = event.message?.nilIfEmpty {
                    Text(message).foregroundStyle(.secondary)
                }
                if let progress = event.progress?.trustedProjection {
                    Text(progress.fraction, format: .percent.precision(.fractionLength(0)))
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

private struct RunDetailLoadingView: View {
    var body: some View {
        ProgressView("run.loading")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RunBuoyTheme.canvas)
    }
}

private struct RunDetailUnavailableView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("run.unavailable", systemImage: "exclamationmark.icloud")
        } description: {
            Text(message)
        } actions: {
            Button("common.try_again", action: retry)
                .runBuoyProminentButtonStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RunBuoyTheme.canvas)
    }
}

private struct RunDetailCardModifier: ViewModifier {
    let radius: CGFloat
    let tone: RunBuoyTone?
    let liveSurface: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .background(
                liveSurface && !reduceTransparency ? RunBuoyTheme.liveSurface : RunBuoyTheme.surface,
                in: RoundedRectangle(cornerRadius: radius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        tone.map(RunBuoyTheme.color(for:))
                            ?? RunBuoyTheme.separator.opacity(contrast == .increased ? 1 : 0.35),
                        lineWidth: RunBuoyMetrics.semanticStrokeWidth
                    )
            }
    }
}

private extension View {
    func runDetailCard(
        radius: CGFloat,
        tone: RunBuoyTone? = nil,
        liveSurface: Bool = false
    ) -> some View {
        modifier(RunDetailCardModifier(radius: radius, tone: tone, liveSurface: liveSurface))
    }
}

private extension RunFeedEvent {
    var isSafeDetailEvent: Bool {
        switch type {
        case "run.created", "run.starting", "run.started", "run.progress",
             "run.phase_changed", "run.message", "run.attention_required",
             "run.heartbeat", "run.succeeded", "run.failed", "run.cancelled", "run.lost":
            true
        default:
            false
        }
    }
}

private extension ExecutionStatus {
    func localizedTitle(locale: Locale) -> String {
        switch self {
        case .created: String(localized: "status.created", locale: locale)
        case .starting: String(localized: "status.starting", locale: locale)
        case .running: String(localized: "status.running", locale: locale)
        case .succeeded: String(localized: "status.succeeded", locale: locale)
        case .failed: String(localized: "status.failed", locale: locale)
        case .cancelled: String(localized: "status.cancelled", locale: locale)
        case .lost: String(localized: "status.lost", locale: locale)
        case .unknown: String(localized: "status.unknown", locale: locale)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview("Long English") {
    NavigationStack {
        RunDetailContent(detail: PreviewFixtures.longEnglishDetail)
    }
}

#Preview("简体中文 · 辅助功能字号") {
    NavigationStack {
        RunDetailContent(detail: PreviewFixtures.longChineseDetail, isOfflineCached: true)
    }
    .environment(\.locale, Locale(identifier: "zh-Hans"))
    .environment(\.dynamicTypeSize, .accessibility4)
}
