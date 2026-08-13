import SwiftUI

struct MachineIconImage: View {
    @AppStorage private var iconName: String

    init(machineID: String) {
        _iconName = AppStorage(
            wrappedValue: MachineIcon.defaultValue.rawValue,
            MachineIcon.key(for: machineID)
        )
    }

    var body: some View {
        Image(systemName: resolvedIcon.rawValue)
    }

    private var resolvedIcon: MachineIcon {
        MachineIcon(rawValue: iconName) ?? .defaultValue
    }
}

struct RefreshButton: View {
    let isRefreshing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text("common.refresh")
            } icon: {
                Image(systemName: "arrow.clockwise")
                    .symbolEffect(
                        .rotate,
                        options: .repeat(.continuous),
                        isActive: isRefreshing
                    )
            }
        }
        .disabled(isRefreshing)
    }
}

struct StatusPresentation {
    let visualState: RunStatusVisualState

    var title: LocalizedStringKey { visualState.localizedTitle }
    var symbol: String { visualState.symbol }
    var tone: RunBuoyTone { visualState.tone }
    var color: Color { visualState.color }
}

extension ExecutionStatus {
    var presentation: StatusPresentation {
        StatusPresentation(visualState: .execution(rawValue))
    }

    var progressTint: Color {
        presentation.color
    }
}

extension HealthStatus {
    var presentation: StatusPresentation {
        StatusPresentation(visualState: .health(rawValue))
    }
}

extension AttentionStatus {
    var presentation: StatusPresentation {
        StatusPresentation(visualState: .attention(rawValue))
    }
}

extension RunSnapshot {
    var visualState: RunStatusVisualState {
        RunStatusVisualState.resolve(
            executionStatus: executionStatus.rawValue,
            healthStatus: healthStatus.rawValue,
            attentionStatus: attentionStatus.rawValue
        )
    }
}

extension RunProgress {
    var trustedProjection: TrustedRunProgress? {
        TrustedRunProgress(
            kind: kind.rawValue,
            current: current,
            total: total,
            fraction: fraction,
            unit: unit
        )
    }
}

struct RunStatusBadge: View {
    let state: RunStatusVisualState
    var showsLabel = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    init(state: RunStatusVisualState, showsLabel: Bool = false) {
        self.state = state
        self.showsLabel = showsLabel
    }

    init(presentation: StatusPresentation, showsLabel: Bool = false) {
        self.init(state: presentation.visualState, showsLabel: showsLabel)
    }

    var body: some View {
        Group {
            if showsLabel {
                HStack(spacing: RunBuoyMetrics.badgeSpacing) {
                    symbol
                    Text(state.localizedTitle)
                        .foregroundStyle(.primary)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, RunBuoyMetrics.badgeHorizontalPadding)
                .padding(.vertical, RunBuoyMetrics.badgeVerticalPadding)
                .background(badgeBackground, in: Capsule())
                .overlay {
                    if contrast == .increased || reduceTransparency {
                        Capsule().stroke(state.color, lineWidth: RunBuoyMetrics.semanticStrokeWidth)
                    }
                }
            } else {
                symbol
                    .font(.caption.weight(.semibold))
                    .frame(width: RunBuoyMetrics.badgeIconSize, height: RunBuoyMetrics.badgeIconSize)
                    .background(badgeBackground, in: Circle())
                    .overlay {
                        if contrast == .increased || reduceTransparency {
                            Circle().stroke(state.color, lineWidth: RunBuoyMetrics.semanticStrokeWidth)
                        }
                    }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.localizedTitle)
    }

    private var symbol: some View {
        Image(systemName: state.symbol)
            .accessibilityHidden(true)
            .foregroundStyle(state.color)
    }

    private var badgeBackground: Color {
        RunBuoyTheme.badgeBackground(
            for: state.tone,
            increasedContrast: contrast == .increased,
            reduceTransparency: reduceTransparency
        )
    }
}

typealias StatusBadge = RunStatusBadge

struct RunProgressView: View {
    enum Emphasis: Equatable {
        case compact
        case prominent

        var barHeight: CGFloat {
            switch self {
            case .compact: RunBuoyMetrics.compactProgressHeight
            case .prominent: RunBuoyMetrics.prominentProgressHeight
            }
        }

        var spacing: CGFloat {
            switch self {
            case .compact: RunBuoyMetrics.compactProgressSpacing
            case .prominent: RunBuoyMetrics.prominentProgressSpacing
            }
        }

        var phaseFont: Font {
            switch self {
            case .compact: .subheadline.weight(.medium)
            case .prominent: .headline
            }
        }

        var percentageFont: Font {
            switch self {
            case .compact: .subheadline.weight(.bold)
            case .prominent: .title.bold()
            }
        }
    }

    let progress: RunProgress?
    let phase: String?
    let showsIndeterminate: Bool
    var emphasis: Emphasis = .compact
    var tint: Color = .accentColor
    var showsPhase = true
    var visualState: RunStatusVisualState?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        progress: RunProgress?,
        phase: String?,
        showsIndeterminate: Bool,
        emphasis: Emphasis = .compact,
        tint: Color = .accentColor,
        showsPhase: Bool = true
    ) {
        self.progress = progress
        self.phase = phase
        self.showsIndeterminate = showsIndeterminate
        self.emphasis = emphasis
        self.tint = tint
        self.showsPhase = showsPhase
        visualState = nil
    }

    init(
        progress: RunProgress?,
        phase: String?,
        visualState: RunStatusVisualState,
        showsIndeterminate: Bool,
        emphasis: Emphasis = .compact,
        showsPhase: Bool = true
    ) {
        self.progress = progress
        self.phase = phase
        self.showsIndeterminate = showsIndeterminate
        self.emphasis = emphasis
        tint = visualState.color
        self.showsPhase = showsPhase
        self.visualState = visualState
    }

    var body: some View {
        VStack(alignment: .leading, spacing: emphasis.spacing) {
            if let projection = progress?.trustedProjection {
                if emphasis == .prominent {
                    prominentDeterminateContent(projection: projection)
                } else {
                    compactDeterminateContent(projection: projection)
                }
            } else if showsIndeterminate {
                indeterminateContent
            } else if showsPhase, let phase, !phase.isEmpty {
                phaseLabel(phase)
            }
        }
    }

    private func prominentDeterminateContent(projection: TrustedRunProgress) -> some View {
        VStack(alignment: .leading, spacing: emphasis.spacing) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    if showsPhase {
                        progressLabel
                    }
                    percentageLabel(projection.fraction)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    if showsPhase {
                        progressLabel
                    }
                    Spacer(minLength: 8)
                    percentageLabel(projection.fraction)
                }
            }

            DeterminateRunProgressBar(
                fraction: projection.fraction,
                tone: visualState?.tone,
                legacyTint: tint,
                height: emphasis.barHeight,
                addsGlow: emphasis == .prominent && visualState?.allowsLiveEmphasis == true
            )

            Text(progressCount(projection))
                    .font(.caption)
                    .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleProgressLabel)
        .accessibilityValue(Text(projection.fraction, format: .percent))
    }

    private func compactDeterminateContent(projection: TrustedRunProgress) -> some View {
        VStack(alignment: .leading, spacing: emphasis.spacing) {
            DeterminateRunProgressBar(
                fraction: projection.fraction,
                tone: visualState?.tone,
                legacyTint: tint,
                height: emphasis.barHeight,
                addsGlow: false
            )
            if showsPhase, let phase, !phase.isEmpty {
                phaseLabel(phase)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleProgressLabel)
        .accessibilityValue(Text(projection.fraction, format: .percent))
    }

    private var indeterminateContent: some View {
        VStack(alignment: .leading, spacing: emphasis.spacing) {
            if showsPhase {
                progressLabel
            }
            IndeterminateRunProgressBar(
                tone: visualState?.tone,
                legacyTint: tint,
                height: emphasis.barHeight
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleProgressLabel)
        .accessibilityValue("progress.indeterminate")
    }

    @ViewBuilder
    private var progressLabel: some View {
        if let phase, !phase.isEmpty {
            phaseLabel(phase)
        } else {
            Text("run.progress")
                .font(emphasis.phaseFont)
        }
    }

    @ViewBuilder
    private func phaseLabel(_ phase: String) -> some View {
        if emphasis == .prominent {
            phaseText(phase)
        } else {
            phaseText(phase)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
        }
    }

    private func phaseText(_ phase: String) -> some View {
        Text(phase)
            .font(emphasis.phaseFont)
            .accessibilityLabel(String(localized: "run.phase"))
            .accessibilityValue(phase)
    }

    private func percentageLabel(_ fraction: Double) -> some View {
        Text(
            fraction.formatted(
                .percent.precision(.fractionLength(0))
            )
        )
            .font(emphasis.percentageFont)
            .foregroundStyle(.primary)
            .accessibilityHidden(true)
    }

    private var accessibleProgressLabel: String {
        let label = String(localized: "run.progress")
        guard let phase, !phase.isEmpty else { return label }
        return "\(label): \(phase)"
    }

    private func progressCount(_ progress: TrustedRunProgress) -> String {
        let count = "\(progress.current.formatted()) / \(progress.total.formatted())"
        return progress.unit.flatMap { unit in
            unit.isEmpty ? nil : "\(count) \(unit)"
        } ?? count
    }
}

struct DeterminateRunProgressBar: View {
    let fraction: Double
    var tone: RunBuoyTone?
    var legacyTint: Color = .accentColor
    let height: CGFloat
    let addsGlow: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    private var color: Color { tone?.color ?? legacyTint }
    private var effectiveGlow: Bool {
        addsGlow && !reduceTransparency && contrast != .increased
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        tone.map {
                            RunBuoyTheme.progressTrack(
                                for: $0,
                                increasedContrast: contrast == .increased
                            )
                        } ?? color.opacity(contrast == .increased ? 0.28 : 0.15)
                    )
                Capsule()
                    .fill(
                        tone.map(RunBuoyTheme.progressGradient(for:))
                            ?? LinearGradient(
                                colors: [color.opacity(0.78), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
                    .shadow(
                        color: effectiveGlow ? RunBuoyTheme.brandLive.opacity(RunBuoyMetrics.progressGlowOpacity) : .clear,
                        radius: effectiveGlow ? RunBuoyMetrics.progressGlowRadius : 0,
                        y: effectiveGlow ? 1 : 0
                    )
            }
        }
        .frame(height: height)
        .animation(RunBuoyMotion.progress(reduceMotion: reduceMotion), value: fraction)
        .accessibilityHidden(true)
    }
}

private struct IndeterminateRunProgressBar: View {
    let tone: RunBuoyTone?
    let legacyTint: Color
    let height: CGFloat
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    private var color: Color { tone?.color ?? legacyTint }

    var body: some View {
        GeometryReader { proxy in
            let segmentWidth = proxy.size.width * 0.36
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(contrast == .increased ? 0.28 : 0.15))
                Capsule()
                    .fill(
                        tone.map(RunBuoyTheme.progressGradient(for:))
                            ?? LinearGradient(
                                colors: [color.opacity(0.62), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .frame(width: segmentWidth)
                    .offset(
                        x: reduceMotion
                            ? (proxy.size.width - segmentWidth) / 2
                            : (isAnimating ? proxy.size.width : -segmentWidth)
                    )
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
        .animation(
            reduceMotion
                ? nil
                : .linear(duration: 1.15).repeatForever(autoreverses: false),
            value: isAnimating
        )
        .onAppear {
            isAnimating = !reduceMotion
        }
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            isAnimating = !shouldReduceMotion
        }
    }
}

struct RunRow: View {
    let model: RunSummaryModel
    var showsLiveTiming = false

    var body: some View {
        RunRowContent(
            run: model.snapshot,
            showsLiveTiming: showsLiveTiming
        )
    }
}

private struct RunRowContent: View {
    let run: RunSnapshot
    let showsLiveTiming: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        statusBadge
                        runTitle
                    }
                    machineAndProgressSummary
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    statusBadge
                    runTitle
                }
                machineAndProgressSummary
            }
            RunProgressView(
                progress: run.progress,
                phase: showsLiveTiming ? run.phase : nil,
                visualState: run.visualState,
                showsIndeterminate: showsLiveTiming && run.executionStatus.isActive,
                emphasis: .compact
            )
            RunRowMetadataFooter(
                run: run,
                showsLiveTiming: showsLiveTiming
            )
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var runTitle: some View {
        Text(run.title)
            .font(.headline)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
    }

    private var statusBadge: some View {
        RunStatusBadge(state: run.visualState)
    }

    private var machineAndProgressSummary: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            machineLabel
                .layoutPriority(2)
            Spacer(minLength: 4)
            progressSummary
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
    }

    private var machineLabel: some View {
        Label {
            Text(run.machineName)
                .lineLimit(1)
                .truncationMode(.tail)
        } icon: {
            MachineIconImage(machineID: run.machineID)
                .accessibilityHidden(true)
        }
        .labelStyle(.titleAndIcon)
    }

    @ViewBuilder
    private var progressSummary: some View {
        if let progress = run.progress,
           let projection = progress.trustedProjection {
            ViewThatFits(in: .horizontal) {
                progressText(count: progressCount(projection), fraction: projection.fraction)
                progressText(count: compactProgressCount(projection), fraction: projection.fraction)
                progressText(count: nil, fraction: projection.fraction)
            }
            .monospacedDigit()
            .lineLimit(1)
            .layoutPriority(1)
            .accessibilityLabel(fullProgressAccessibilityLabel(projection))
        }
    }

    private func progressText(count: String?, fraction: Double) -> Text {
        let percentage = fraction.formatted(.percent.precision(.fractionLength(0)))
        guard let count else {
            return Text(percentage).font(.caption.bold())
        }
        return Text("\(count) · ").font(.caption)
            + Text(percentage).font(.caption.bold())
    }

    private func progressCount(
        _ progress: TrustedRunProgress
    ) -> String {
        let count = "\(progress.current.formatted()) / \(progress.total.formatted())"
        return progress.unit.flatMap { unit in
            unit.isEmpty ? nil : "\(count) \(unit)"
        } ?? count
    }

    private func compactProgressCount(
        _ progress: TrustedRunProgress
    ) -> String {
        let format = FloatingPointFormatStyle<Double>.number
            .notation(.compactName)
            .precision(.fractionLength(0...1))
        let count = "\(progress.current.formatted(format)) / \(progress.total.formatted(format))"
        return progress.unit.flatMap { unit in
            unit.isEmpty ? nil : "\(count) \(unit)"
        } ?? count
    }

    private func fullProgressAccessibilityLabel(
        _ progress: TrustedRunProgress
    ) -> String {
        let percentage = progress.fraction.formatted(.percent.precision(.fractionLength(0)))
        return "\(progressCount(progress)), \(percentage)"
    }
}

private struct RunRowMetadataFooter: View {
    let run: RunSnapshot
    let showsLiveTiming: Bool

    var body: some View {
        Group {
            if showsLiveTiming {
                activeTiming
            } else {
                historyMetadata
            }
        }
        .font(.caption)
        .foregroundStyle(.primary)
    }

    private var activeTiming: some View {
        VStack(alignment: .leading, spacing: 6) {
            if hasStatusLabels {
                statusLabels
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    executionTime
                    heartbeatTime
                }

                VStack(alignment: .leading, spacing: 6) {
                    executionTime
                    heartbeatTime
                }
            }
        }
    }

    private var historyMetadata: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                Spacer(minLength: 8)
                completionTime
            }

            VStack(alignment: .leading, spacing: 6) {
                completionTime
            }
        }
    }

    private var hasStatusLabels: Bool {
        run.healthStatus != .healthy || run.attentionStatus != .none
    }

    @ViewBuilder
    private var statusLabels: some View {
        HStack(spacing: 8) {
            if run.healthStatus != .healthy {
                HStack(spacing: 4) {
                    Image(systemName: run.healthStatus.presentation.symbol)
                        .accessibilityHidden(true)
                    Text(run.healthStatus.presentation.title)
                }
                    .fixedSize(horizontal: true, vertical: false)
            }
            if run.attentionStatus != .none {
                HStack(spacing: 4) {
                    Image(systemName: run.attentionStatus.presentation.symbol)
                        .accessibilityHidden(true)
                    Text(run.attentionStatus.presentation.title)
                }
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private var completionTime: some View {
        HStack(spacing: 4) {
            Text("history.completed")
            Text(
                run.endedAt ?? run.updatedAt,
                format: .relative(presentation: .named)
            )
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var executionTime: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("run.execution_time")
                .foregroundStyle(.secondary)
            Text(RunDurationText.string(from: run.startedAt, to: run.updatedAt))
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("run.timing.execution")
    }

    private var heartbeatTime: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg")
                .foregroundStyle(run.healthStatus.presentation.color)
                .accessibilityHidden(true)
            Text("run.heartbeat_time")
                .foregroundStyle(.secondary)
            Text(run.updatedAt, style: .relative)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("run.timing.heartbeat")
    }
}

struct OfflineBanner: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let message: String

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    offlineIcon
                    bannerText
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    offlineIcon
                    bannerText
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RunBuoyTheme.badgeBackground(
                for: .warning,
                increasedContrast: contrast == .increased,
                reduceTransparency: reduceTransparency
            ),
            in: RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardRadius)
        )
        .overlay {
            if reduceTransparency || contrast == .increased {
                RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardRadius)
                    .stroke(RunBuoyTheme.warning, lineWidth: RunBuoyMetrics.semanticStrokeWidth)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("runs.offlineBanner")
    }

    private var offlineIcon: some View {
        Image(systemName: "wifi.slash")
            .foregroundStyle(RunBuoyTheme.warning)
            .accessibilityHidden(true)
    }

    private var bannerText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("runs.cached_data")
                .fontWeight(.semibold)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Text(message)
                .font(.caption)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.primary)
        .layoutPriority(1)
    }
}
