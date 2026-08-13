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
                            state: context.state,
                            isStale: context.isStale
                        )
                    }
                }
            } compactLeading: {
                LiveStatusIcon(state: context.state, isStale: context.isStale, size: 18)
            } compactTrailing: {
                LiveIslandProgress(
                    state: context.state,
                    isStale: context.isStale,
                    size: 24
                )
            } minimal: {
                LiveIslandProgress(
                    state: context.state,
                    isStale: context.isStale,
                    size: 22
                )
            }
            .widgetURL(deepLink(for: context.attributes))
            .keylineTint(context.state.visualState(isStale: context.isStale).color)
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
        VStack(alignment: .leading, spacing: 10) {
            LiveActivityHeader(attributes: attributes, state: state, isStale: isStale)
            LiveActivityProgressSection(state: state, isStale: isStale)
            LiveActivityFooter(attributes: attributes, state: state, isStale: isStale)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(state.visualState(isStale: isStale).localizedTitle)
        .accessibilityValue(
            state.visualState(isStale: isStale).accessibilityValue(state: state)
        )
    }
}

private struct LiveActivityHeader: View {
    let attributes: RunActivityAttributes
    let state: RunActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            LiveStatusIcon(state: state, isStale: isStale, size: 17)
            Text(attributes.title)
                .font(.headline)
                .lineLimit(1)
        }
    }
}

private struct LiveStatusIcon: View {
    let state: RunActivityAttributes.ContentState
    let isStale: Bool
    let size: CGFloat

    var body: some View {
        Image(systemName: state.visualState(isStale: isStale).symbol)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(state.visualState(isStale: isStale).color)
            .accessibilityLabel(state.visualState(isStale: isStale).localizedTitle)
    }
}

private struct LiveIslandProgress: View {
    let state: RunActivityAttributes.ContentState
    let isStale: Bool
    let size: CGFloat

    var body: some View {
        let visualState = state.visualState(isStale: isStale)
        if let progress = state.trustedProgress,
           visualState.category.canShowProgressRing {
            SignalBuoyProgressRing(
                progress: progress.fraction,
                tone: visualState.tone,
                allowsLiveEmphasis: visualState.allowsLiveEmphasis,
                size: size <= RunBuoyMetrics.buoyRingMinimalSize ? .minimal : .compact
            )
        } else {
            LiveStatusIcon(
                state: state,
                isStale: isStale,
                size: size * 0.68
            )
        }
    }
}

private struct LiveActivityFooter: View {
    let attributes: RunActivityAttributes
    let state: RunActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "desktopcomputer")
                .accessibilityHidden(true)
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
        // Ended Live Activities remain visible for at most four hours.
        (0...240).map { minute in
            endedAt.addingTimeInterval(TimeInterval(minute * 60))
        }
    }
}

private struct LiveActivityProgressSection: View {
    let state: RunActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        let visualState = state.visualState(isStale: isStale)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(state.phase ?? String(localized: String.LocalizationValue(visualState.titleKey)))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let progress = state.trustedProgress {
                    Text(progress.fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline.monospacedDigit().bold())
                }
            }

            if let progress = state.trustedProgress {
                ProgressView(value: progress.fraction)
                    .tint(visualState.color)
                    .accessibilityLabel("widget.progress")
                    .accessibilityValue(Text(progress.fraction, format: .percent))
            } else if !visualState.isTerminal {
                LiveIndeterminateProgressBar(
                    color: visualState.color
                )
                    .accessibilityLabel("progress.indeterminate")
            }
        }
    }
}

private struct LiveIndeterminateProgressBar: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.22))
                Capsule()
                    .fill(color)
                    .frame(width: proxy.size.width * 0.34)
                    .offset(x: proxy.size.width * 0.12)
            }
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
    }
}

private extension RunStatusVisualState {
    func accessibilityValue(state: RunActivityAttributes.ContentState) -> String {
        if let progress = state.trustedProgress {
            return progress.fraction.formatted(.percent.precision(.fractionLength(0)))
        }
        return state.phase ?? String(localized: String.LocalizationValue(titleKey))
    }
}

private enum WidgetPreviewFixtures {
    static let attributes = RunActivityAttributes(
        runID: "018f0d8a-8c0a-7000-8000-000000000001",
        title: "Gurobi experiment",
        machineName: "Mac Studio"
    )

    static func state(
        execution: String = "RUNNING",
        health: String = "HEALTHY",
        attention: String = "NONE",
        progress: Double? = 0.72,
        phase: String? = "Optimizing",
        machineName: String? = "Mac Studio"
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
            createdAt: Date().addingTimeInterval(-635),
            startedAt: Date().addingTimeInterval(-620),
            updatedAt: Date(),
            machineName: machineName,
            endedAt: isTerminalExecution(execution) ? Date().addingTimeInterval(-125) : nil,
            estimatedEndAt: progress == nil ? nil : Date().addingTimeInterval(240),
            exitCode: execution == "FAILED" ? 1 : nil
        )
    }

    private static func isTerminalExecution(_ execution: String) -> Bool {
        switch execution {
        case "SUCCEEDED", "FAILED", "CANCELLED", "LOST":
            true
        default:
            false
        }
    }
}

#Preview("Determinate") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state()
    )
    .padding()
}

#Preview("Indeterminate") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state(progress: nil, phase: "Preparing data")
    )
    .padding()
}

#Preview("Success") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state(execution: "SUCCEEDED", progress: 1, phase: "Completed")
    )
    .padding()
}

#Preview("Failure and attention") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state(
            execution: "FAILED",
            attention: "ACTION_REQUIRED",
            progress: nil,
            phase: "Build failed"
        )
    )
    .padding()
}

#Preview("Stale confirmation") {
    RunLockScreenView(
        attributes: WidgetPreviewFixtures.attributes,
        state: WidgetPreviewFixtures.state(progress: nil),
        isStale: true
    )
    .padding()
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
