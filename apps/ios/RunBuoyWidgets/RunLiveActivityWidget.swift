import ActivityKit
import SwiftUI
import WidgetKit

struct RunLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            RunLockScreenView(
                attributes: context.attributes,
                state: context.state,
                isStale: context.isStale
            )
            .widgetURL(deepLink(for: context.attributes))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    LiveActivityHeader(
                        attributes: context.attributes,
                        state: context.state,
                        isStale: context.isStale
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        LiveActivityProgressSection(
                            state: context.state,
                            isStale: context.isStale
                        )
                        LiveActivityFooter(
                            attributes: context.attributes,
                            state: context.state
                        )
                    }
                }
            } compactLeading: {
                LiveStatusSymbol(
                    state: context.state,
                    isStale: context.isStale,
                    size: .compact
                )
            } compactTrailing: {
                LiveIslandProgress(
                    state: context.state,
                    isStale: context.isStale,
                    size: .compact
                )
            } minimal: {
                LiveIslandProgress(
                    state: context.state,
                    isStale: context.isStale,
                    size: .minimal
                )
            }
            .widgetURL(deepLink(for: context.attributes))
            .keylineTint(
                RunBuoyWidgetToneColor.resolve(
                    context.state.statusVisualState(isStale: context.isStale).tone,
                    colorScheme: .dark
                )
            )
        }
    }

    private func deepLink(for attributes: RunActivityAttributes) -> URL? {
        if attributes.isDemo {
            return URL(string: "runbuoy://demo/live-activity")
        }
        return URL(string: "runbuoy://runs/\(attributes.runID)")
    }
}

struct RunLockScreenView: View {
    let attributes: RunActivityAttributes
    let state: RunActivityAttributes.ContentState
    let isStale: Bool

    init(
        attributes: RunActivityAttributes,
        state: RunActivityAttributes.ContentState,
        isStale: Bool = false
    ) {
        self.attributes = attributes
        self.state = state
        self.isStale = isStale
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LiveActivityHeader(
                attributes: attributes,
                state: state,
                isStale: isStale
            )
            LiveActivityProgressSection(state: state, isStale: isStale)
            LiveActivityFooter(attributes: attributes, state: state)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(attributes.title)
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        let status = state.statusVisualState(isStale: isStale)
        let progress = state.progressVisualState(isStale: isStale)
        var parts = [status.kind.localizedTitle]
        if let phase = state.phase, !phase.isEmpty {
            parts.append(phase)
        }
        if let fraction = progress.fraction {
            parts.append(fraction.formatted(.percent.precision(.fractionLength(0))))
        }
        parts.append(state.machineName ?? attributes.machineName)
        return parts.joined(separator: ", ")
    }
}

private struct LiveActivityHeader: View {
    let attributes: RunActivityAttributes
    let state: RunActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        let status = state.statusVisualState(isStale: isStale)
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            LiveStatusSymbol(state: state, isStale: isStale, size: .footer)
            Text(attributes.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(1)
            Spacer(minLength: 4)
            Text(status.kind.titleKey)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

private struct LiveStatusSymbol: View {
    enum Size {
        case footer
        case minimal
        case compact

        var pointSize: CGFloat {
            switch self {
            case .footer: 13
            case .minimal: 16
            case .compact: 18
            }
        }
    }

    let state: RunActivityAttributes.ContentState
    let isStale: Bool
    let size: Size
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let status = state.statusVisualState(isStale: isStale)
        Image(systemName: status.symbolName)
            .font(.system(size: size.pointSize, weight: .semibold))
            .foregroundStyle(
                RunBuoyWidgetToneColor.resolve(status.tone, colorScheme: colorScheme)
            )
            .accessibilityLabel(Text(status.kind.titleKey))
    }
}

private struct LiveIslandProgress: View {
    let state: RunActivityAttributes.ContentState
    let isStale: Bool
    let size: SignalBuoyProgressRing.Size

    var body: some View {
        let status = state.statusVisualState(isStale: isStale)
        let progress = state.progressVisualState(isStale: isStale)

        if shouldReplaceProgress(status) {
            LiveStatusSymbol(
                state: state,
                isStale: isStale,
                size: size == .compact ? .compact : .minimal
            )
        } else if progress.kind == .determinate {
            SignalBuoyProgressRing(status: status, progress: progress, size: size)
        } else {
            LivePulseSymbol(status: status, size: size)
        }
    }

    private func shouldReplaceProgress(_ status: RunStatusVisualState) -> Bool {
        status.isTerminal || status.kind == .stale || status.kind == .offline
    }
}

private struct LivePulseSymbol: View {
    let status: RunStatusVisualState
    let size: SignalBuoyProgressRing.Size
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(systemName: status.kind == .starting ? "hourglass" : "waveform.path.ecg")
            .font(.system(size: size.diameter * 0.68, weight: .semibold))
            .foregroundStyle(
                RunBuoyWidgetToneColor.resolve(status.tone, colorScheme: colorScheme)
            )
            .frame(width: size.diameter, height: size.diameter)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(status.kind.titleKey))
            .accessibilityValue("progress.indeterminate")
    }
}

private struct SignalBuoyProgressRing: View {
    enum Size {
        case minimal
        case compact

        var diameter: CGFloat { self == .minimal ? 22 : 24 }
    }

    let status: RunStatusVisualState
    let progress: RunProgressVisualState
    let size: Size

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let fraction = progress.fraction ?? 0
        let gap = 64.0 / 360.0
        let start = gap / 2
        let end = start + (1 - gap) * fraction

        ZStack {
            Circle()
                .trim(from: start, to: 1 - start)
                .stroke(
                    RunBuoyWidgetToneColor.progressTrack(
                        status.tone,
                        colorScheme: colorScheme,
                        increasedContrast: contrast == .increased
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
            Circle()
                .trim(from: start, to: end)
                .stroke(
                    RunBuoyWidgetToneColor.progressRingGradient(
                        status.tone,
                        colorScheme: colorScheme
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .shadow(
                    color: progress.allowsGlow && !reduceTransparency
                        ? RunBuoyWidgetToneColor.glow(status.tone, colorScheme: colorScheme)
                        : .clear,
                    radius: progress.allowsGlow && !reduceTransparency ? 5 : 0
                )
        }
        .rotationEffect(.degrees(90))
        .frame(width: size.diameter, height: size.diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("widget.progress")
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

private struct LiveActivityProgressSection: View {
    let state: RunActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        let status = state.statusVisualState(isStale: isStale)
        let progress = state.progressVisualState(isStale: isStale)

        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(phaseText(status))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)
                Spacer(minLength: 8)
                if let fraction = progress.fraction {
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .lineLimit(1)
                }
            }

            switch progress.kind {
            case .determinate:
                LiveDeterminateProgressTrack(status: status, progress: progress)
            case .indeterminate:
                LiveIndeterminateProgressTrack(status: status)
            case .unavailable:
                EmptyView()
            }
        }
    }

    private func phaseText(_ status: RunStatusVisualState) -> String {
        if let phase = state.phase, !phase.isEmpty {
            return phase
        }
        return status.kind.localizedTitle
    }
}

private struct LiveDeterminateProgressTrack: View {
    let status: RunStatusVisualState
    let progress: RunProgressVisualState
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        RunBuoyWidgetToneColor.progressTrack(
                            status.tone,
                            colorScheme: colorScheme,
                            increasedContrast: contrast == .increased
                        )
                    )
                Capsule()
                    .fill(
                        RunBuoyWidgetToneColor.progressGradient(
                            status.tone,
                            colorScheme: colorScheme
                        )
                    )
                    .frame(width: proxy.size.width * (progress.fraction ?? 0))
                    .shadow(
                        color: progress.allowsGlow && !reduceTransparency
                            ? RunBuoyWidgetToneColor.glow(status.tone, colorScheme: colorScheme)
                            : .clear,
                        radius: progress.allowsGlow && !reduceTransparency ? 4 : 0
                    )
            }
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("widget.progress")
        .accessibilityValue(
            Text(progress.fraction ?? 0, format: .percent.precision(.fractionLength(0)))
        )
    }
}

private struct LiveIndeterminateProgressTrack: View {
    let status: RunStatusVisualState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        RunBuoyWidgetToneColor.progressTrack(
                            status.tone,
                            colorScheme: colorScheme,
                            increasedContrast: contrast == .increased
                        )
                    )
                Capsule()
                    .fill(
                        RunBuoyWidgetToneColor.progressGradient(
                            status.tone,
                            colorScheme: colorScheme
                        )
                    )
                    .frame(width: proxy.size.width * 0.28)
                    .offset(x: proxy.size.width * 0.08)
            }
            .clipShape(Capsule())
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("progress.indeterminate")
    }
}

private struct LiveActivityFooter: View {
    let attributes: RunActivityAttributes
    let state: RunActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 8) {
            Text(state.machineName ?? attributes.machineName)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            LiveActivityTime(state: state)
                .layoutPriority(1)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private struct LiveActivityTime: View {
    let state: RunActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.statusVisualState().isTerminal {
                LiveActivityTerminalTime(endedAt: state.completionDate)
            } else {
                Text(
                    RunActivityDurationText.string(
                        createdAt: state.createdAt,
                        startedAt: state.startedAt,
                        updatedAt: state.updatedAt
                    )
                )
                .accessibilityLabel("widget.confirmed_elapsed")
            }
        }
        .monospacedDigit()
        .lineLimit(1)
    }
}

private struct LiveActivityTerminalTime: View {
    let endedAt: Date
    @Environment(\.locale) private var locale

    var body: some View {
        TimelineView(.explicit(refreshDates)) { context in
            Text(
                RunActivityTerminalTimeText.string(
                    endedAt: endedAt,
                    currentDate: context.date,
                    locale: locale
                )
            )
        }
        .accessibilityLabel("widget.terminal_time")
    }

    private var refreshDates: [Date] {
        (0...240).map { minute in
            endedAt.addingTimeInterval(TimeInterval(minute * 60))
        }
    }
}

private extension RunStatusVisualState.Kind {
    var titleKey: LocalizedStringKey {
        switch self {
        case .created: "status.created"
        case .starting: "status.starting"
        case .running: "status.running"
        case .succeeded: "status.succeeded"
        case .failed: "status.failed"
        case .cancelled: "status.cancelled"
        case .lost: "status.lost"
        case .stale: "health.stale"
        case .offline: "health.offline"
        case .actionRequired: "attention.action_required"
        case .warning: "attention.warning"
        case .information: "attention.information"
        case .unknown: "status.unknown"
        }
    }

    var localizedTitle: String {
        switch self {
        case .created: String(localized: "status.created")
        case .starting: String(localized: "status.starting")
        case .running: String(localized: "status.running")
        case .succeeded: String(localized: "status.succeeded")
        case .failed: String(localized: "status.failed")
        case .cancelled: String(localized: "status.cancelled")
        case .lost: String(localized: "status.lost")
        case .stale: String(localized: "health.stale")
        case .offline: String(localized: "health.offline")
        case .actionRequired: String(localized: "attention.action_required")
        case .warning: String(localized: "attention.warning")
        case .information: String(localized: "attention.information")
        case .unknown: String(localized: "status.unknown")
        }
    }
}

private enum WidgetPreviewFixtures {
    static let date = Date(timeIntervalSince1970: 1_785_076_800)
    static let attributes = RunActivityAttributes(
        runID: "018f0d8a-8c0a-7000-8000-000000000001",
        title: "Build and deploy",
        machineName: "Build Mac mini"
    )

    static func state(
        execution: String = "RUNNING",
        health: String = "HEALTHY",
        attention: String = "NONE",
        progress: Double? = 0.72,
        phase: String? = "Processing",
        machineName: String? = "Build Mac mini"
    ) -> RunActivityAttributes.ContentState {
        .init(
            sequence: 42,
            executionStatus: execution,
            healthStatus: health,
            attentionStatus: attention,
            progressKind: progress == nil ? "indeterminate" : "determinate",
            progress: progress,
            current: progress.map { $0 * 100 },
            total: progress == nil ? nil : 100,
            phase: phase,
            message: nil,
            createdAt: date.addingTimeInterval(-237),
            startedAt: date.addingTimeInterval(-222),
            updatedAt: date,
            machineName: machineName,
            endedAt: isTerminalExecution(execution) ? date.addingTimeInterval(-125) : nil,
            estimatedEndAt: nil,
            exitCode: execution == "FAILED" ? 1 : nil
        )
    }

    private static func isTerminalExecution(_ execution: String) -> Bool {
        ["SUCCEEDED", "FAILED", "CANCELLED", "LOST"].contains(execution)
    }
}

#Preview("Lock Screen states", as: .content, using: WidgetPreviewFixtures.attributes) {
    RunLiveActivityWidget()
} contentStates: {
    WidgetPreviewFixtures.state(execution: "STARTING", progress: nil, phase: "Starting")
    WidgetPreviewFixtures.state(progress: nil, phase: "Preparing data")
    WidgetPreviewFixtures.state()
    WidgetPreviewFixtures.state(progress: 0.92, phase: "Uploading artifacts")
    WidgetPreviewFixtures.state(attention: "WARNING", phase: "Checking result")
    WidgetPreviewFixtures.state(attention: "ACTION_REQUIRED", phase: "Action required on machine")
    WidgetPreviewFixtures.state(health: "STALE", phase: "Waiting for confirmation")
    WidgetPreviewFixtures.state(health: "OFFLINE", phase: "Waiting for the machine")
    WidgetPreviewFixtures.state(execution: "SUCCEEDED", progress: 1, phase: "Completed")
    WidgetPreviewFixtures.state(execution: "FAILED", progress: nil, phase: "Stopped with an error")
    WidgetPreviewFixtures.state(execution: "CANCELLED", progress: nil, phase: "Ended on machine")
    WidgetPreviewFixtures.state(execution: "LOST", progress: nil, phase: "Connection lost")
}

#Preview("Dynamic Island compact", as: .dynamicIsland(.compact), using: WidgetPreviewFixtures.attributes) {
    RunLiveActivityWidget()
} contentStates: {
    WidgetPreviewFixtures.state()
    WidgetPreviewFixtures.state(attention: "WARNING", phase: "Checking result")
    WidgetPreviewFixtures.state(health: "STALE", phase: "Waiting for confirmation")
    WidgetPreviewFixtures.state(execution: "SUCCEEDED", progress: 1, phase: "Completed")
}

#Preview("Dynamic Island minimal", as: .dynamicIsland(.minimal), using: WidgetPreviewFixtures.attributes) {
    RunLiveActivityWidget()
} contentStates: {
    WidgetPreviewFixtures.state(progress: nil, phase: "Preparing data")
    WidgetPreviewFixtures.state(progress: 0.92, phase: "Uploading artifacts")
    WidgetPreviewFixtures.state(attention: "ACTION_REQUIRED", phase: "Action required on machine")
    WidgetPreviewFixtures.state(execution: "FAILED", progress: nil, phase: "Stopped with an error")
    WidgetPreviewFixtures.state(execution: "LOST", progress: nil, phase: "Connection lost")
}

#Preview("Dynamic Island expanded", as: .dynamicIsland(.expanded), using: WidgetPreviewFixtures.attributes) {
    RunLiveActivityWidget()
} contentStates: {
    WidgetPreviewFixtures.state()
    WidgetPreviewFixtures.state(health: "OFFLINE", phase: "Waiting for the machine")
    WidgetPreviewFixtures.state(execution: "CANCELLED", progress: nil, phase: "Ended on machine")
}

#Preview("Offline · 简体中文 · 大字体") {
    RunLockScreenView(
        attributes: RunActivityAttributes(
            runID: WidgetPreviewFixtures.attributes.runID,
            title: "用于验证超长简体中文标题换行的优化实验",
            machineName: "上海实验室的 Mac Studio 工作站"
        ),
        state: WidgetPreviewFixtures.state(
            health: "OFFLINE",
            progress: nil,
            phase: "等待电脑恢复连接",
            machineName: "上海实验室的 Mac Studio 工作站"
        )
    )
    .padding()
    .environment(\.locale, Locale(identifier: "zh-Hans"))
    .environment(\.dynamicTypeSize, .accessibility3)
}
