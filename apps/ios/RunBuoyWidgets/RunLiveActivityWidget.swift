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
            .activityBackgroundTint(RunBuoyTheme.surface)
            .activitySystemActionForegroundColor(.primary)
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
                    VStack(alignment: .leading, spacing: 6) {
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
                LiveStatusIcon(
                    state: context.state,
                    isStale: context.isStale,
                    size: 18
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
                context.state.liveActivityPresentation(isStale: context.isStale).tone.color
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
        VStack(alignment: .leading, spacing: 6) {
            LiveActivityHeader(attributes: attributes, state: state, isStale: isStale)
            LiveActivityProgressSection(state: state, isStale: isStale)
            LiveActivityFooter(attributes: attributes, state: state)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(attributes.title))
        .accessibilityValue(state.liveActivityAccessibilityValue(isStale: isStale))
    }
}

private struct LiveActivityHeader: View {
    let attributes: RunActivityAttributes
    let state: RunActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            LiveStatusIcon(state: state, isStale: isStale, size: 13)
            Text(attributes.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

private struct LiveStatusIcon: View {
    let state: RunActivityAttributes.ContentState
    let isStale: Bool
    let size: CGFloat

    private var presentation: LiveActivitySemanticPresentation {
        state.liveActivityPresentation(isStale: isStale)
    }

    var body: some View {
        Image(systemName: presentation.symbol)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(presentation.tone.color)
            .accessibilityLabel(presentation.visualState.localizedTitle)
    }
}

private struct LiveIslandProgress: View {
    let state: RunActivityAttributes.ContentState
    let isStale: Bool
    let size: SignalBuoyProgressRing.Size

    private var presentation: LiveActivitySemanticPresentation {
        state.liveActivityPresentation(isStale: isStale)
    }

    var body: some View {
        Group {
            if let progress = state.trustedProgress,
               presentation.canShowProgressRing {
                SignalBuoyProgressRing(
                    progress: progress.fraction,
                    tone: presentation.tone,
                    allowsLiveEmphasis: presentation.allowsLiveEmphasis,
                    size: size
                )
            } else {
                LiveStatusIcon(
                    state: state,
                    isStale: isStale,
                    size: size == .minimal ? 16 : 18
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.visualState.localizedTitle)
        .accessibilityValue(islandAccessibilityValue)
    }

    private var islandAccessibilityValue: Text {
        if let progress = state.trustedProgress,
           presentation.canShowProgressRing {
            return Text(progress.fraction, format: .percent.precision(.fractionLength(0)))
        }
        return Text(
            String(localized: String.LocalizationValue(presentation.visualState.titleKey))
        )
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
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

private struct LiveActivityTime: View {
    let state: RunActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.visualState().isTerminal {
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

private struct LiveActivityProgressSection: View {
    let state: RunActivityAttributes.ContentState
    let isStale: Bool

    private var presentation: LiveActivitySemanticPresentation {
        state.liveActivityPresentation(isStale: isStale)
    }

    private var progress: TrustedRunProgress? {
        state.trustedProgress
    }

    private var showsDeterminateBar: Bool {
        guard progress != nil else { return false }
        return !presentation.visualState.isTerminal
            || presentation.visualState.category == .succeeded
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(phaseOrStatus)
                    .font(.footnote)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 8)
                if showsDeterminateBar, let progress {
                    Text(progress.fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote.monospacedDigit().bold())
                }
            }

            if showsDeterminateBar, let progress {
                LiveDeterminateProgressBar(
                    progress: progress.fraction,
                    tone: presentation.tone,
                    allowsLiveEmphasis: presentation.allowsLiveEmphasis
                )
                .accessibilityLabel("widget.progress")
                .accessibilityValue(Text(progress.fraction, format: .percent))
            } else if !presentation.visualState.isTerminal {
                LiveIndeterminateProgressBar(tone: presentation.tone)
                    .accessibilityLabel("progress.indeterminate")
            }
        }
    }

    private var phaseOrStatus: String {
        guard let phase = state.phase, !phase.isEmpty else {
            return String(
                localized: String.LocalizationValue(presentation.visualState.titleKey)
            )
        }
        return phase
    }
}

private struct LiveDeterminateProgressBar: View {
    let progress: Double
    let tone: RunBuoyTone
    let allowsLiveEmphasis: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    private var boundedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var addsGlow: Bool {
        allowsLiveEmphasis
            && tone == .live
            && !reduceTransparency
            && contrast != .increased
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        RunBuoyTheme.progressTrack(
                            for: tone,
                            increasedContrast: contrast == .increased
                        )
                    )
                Capsule()
                    .fill(RunBuoyTheme.progressGradient(for: tone))
                    .frame(width: proxy.size.width * boundedProgress)
                    .shadow(
                        color: addsGlow
                            ? RunBuoyTheme.brandLive.opacity(RunBuoyMetrics.progressGlowOpacity)
                            : .clear,
                        radius: addsGlow ? RunBuoyMetrics.progressGlowRadius : 0,
                        y: addsGlow ? 1 : 0
                    )
            }
        }
        .frame(height: RunBuoyMetrics.liveActivityProgressHeight)
        .animation(
            RunBuoyMotion.progress(reduceMotion: reduceMotion),
            value: boundedProgress
        )
        .accessibilityElement(children: .ignore)
    }
}

private struct LiveIndeterminateProgressBar: View {
    let tone: RunBuoyTone

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var pulseAtTrailingEdge = false

    var body: some View {
        GeometryReader { proxy in
            let segmentWidth = proxy.size.width * 0.34
            let centeredOffset = (proxy.size.width - segmentWidth) / 2
            let animatedOffset = proxy.size.width * (pulseAtTrailingEdge ? 0.58 : 0.08)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        RunBuoyTheme.progressTrack(
                            for: tone,
                            increasedContrast: contrast == .increased
                        )
                    )
                Capsule()
                    .fill(RunBuoyTheme.progressGradient(for: tone))
                    .frame(width: segmentWidth)
                    .offset(x: reduceMotion ? centeredOffset : animatedOffset)
                    .opacity(reduceMotion ? 1 : (pulseAtTrailingEdge ? 1 : 0.62))
            }
        }
        .frame(height: RunBuoyMetrics.liveActivityProgressHeight)
        .animation(
            reduceMotion
                ? nil
                : .easeInOut(duration: 0.85).repeatForever(autoreverses: true),
            value: pulseAtTrailingEdge
        )
        .onAppear { pulseAtTrailingEdge = !reduceMotion }
        .onChange(of: reduceMotion) { _, isReduced in
            pulseAtTrailingEdge = !isReduced
        }
        .accessibilityElement(children: .ignore)
    }
}

private struct LiveActivitySemanticPresentation {
    let visualState: RunStatusVisualState
    let isExplicitlyHealthyRunning: Bool

    var symbol: String {
        guard visualState.category == .running, !isExplicitlyHealthyRunning else {
            return visualState.symbol
        }
        return "circle"
    }

    var tone: RunBuoyTone {
        guard visualState.category == .running, !isExplicitlyHealthyRunning else {
            return visualState.tone
        }
        return .neutral
    }

    var allowsLiveEmphasis: Bool {
        isExplicitlyHealthyRunning && visualState.allowsLiveEmphasis
    }

    var canShowProgressRing: Bool {
        guard visualState.category.canShowProgressRing else { return false }
        return visualState.category != .running || isExplicitlyHealthyRunning
    }
}

private extension RunActivityAttributes.ContentState {
    func liveActivityPresentation(isStale: Bool) -> LiveActivitySemanticPresentation {
        let visualState = visualState(isStale: isStale)
        let isExplicitlyHealthyRunning = !isStale
            && executionStatus.uppercased() == "RUNNING"
            && healthStatus.uppercased() == "HEALTHY"
            && attentionStatus.uppercased() == "NONE"
            && visualState.category == .running
        return LiveActivitySemanticPresentation(
            visualState: visualState,
            isExplicitlyHealthyRunning: isExplicitlyHealthyRunning
        )
    }

    func liveActivityAccessibilityValue(isStale: Bool) -> String {
        let visualState = visualState(isStale: isStale)
        var components = [
            String(localized: String.LocalizationValue(visualState.titleKey))
        ]
        if let phase, !phase.isEmpty {
            components.append(phase)
        }
        if let progress = trustedProgress,
           !visualState.isTerminal || visualState.category == .succeeded {
            components.append(
                progress.fraction.formatted(.percent.precision(.fractionLength(0)))
            )
        }
        return components.joined(separator: ", ")
    }
}

private enum WidgetPreviewFixtures {
    static let attributes = RunActivityAttributes(
        runID: "018f0d8a-8c0a-7000-8000-000000000001",
        title: "Build and deploy",
        machineName: "Build Mac mini"
    )

    static func state(
        execution: String = "RUNNING",
        health: String = "HEALTHY",
        attention: String = "NONE",
        progress: Double,
        phase: String? = nil
    ) -> RunActivityAttributes.ContentState {
        .init(
            sequence: 42,
            executionStatus: execution,
            healthStatus: health,
            attentionStatus: attention,
            progressKind: "determinate",
            progress: progress,
            current: progress * 100,
            total: 100,
            phase: phase,
            message: nil,
            createdAt: Date().addingTimeInterval(-635),
            startedAt: Date().addingTimeInterval(-620),
            updatedAt: Date(),
            machineName: "Build Mac mini",
            endedAt: execution == "SUCCEEDED" ? Date().addingTimeInterval(-125) : nil,
            estimatedEndAt: nil,
            exitCode: nil
        )
    }
}

#Preview("Running · 35%") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state(progress: 0.35)
    )
}

#Preview("Running · 72% · Phase") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state(progress: 0.72, phase: "Processing")
    )
}

#Preview("Warning") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state(
            attention: "WARNING",
            progress: 0.72,
            phase: "Checking result"
        )
    )
}

#Preview("Stale") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state(
            health: "STALE",
            progress: 0.72,
            phase: "Waiting for confirmation"
        ),
        isStale: true
    )
}

#Preview("Succeeded") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state(
            execution: "SUCCEEDED",
            progress: 1,
            phase: "Completed"
        )
    )
}
