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
    let title: LocalizedStringKey
    let symbol: String
    let tone: RunBuoyTone
    let priority: RunStatusPriority
    let allowsLiveEmphasis: Bool

    init(title: LocalizedStringKey, visualState: RunStatusVisualState) {
        self.title = title
        symbol = visualState.symbolName
        tone = visualState.tone
        priority = visualState.priority
        allowsLiveEmphasis = visualState.allowsLiveEmphasis
    }

    init(visualState: RunStatusVisualState) {
        self.init(title: visualState.kind.localizedTitle, visualState: visualState)
    }

    init(
        title: LocalizedStringKey,
        symbol: String,
        tone: RunBuoyTone,
        priority: RunStatusPriority,
        allowsLiveEmphasis: Bool = false
    ) {
        self.title = title
        self.symbol = symbol
        self.tone = tone
        self.priority = priority
        self.allowsLiveEmphasis = allowsLiveEmphasis
    }
}

private extension RunStatusVisualState.Kind {
    var localizedTitle: LocalizedStringKey {
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
}

extension ExecutionStatus {
    var presentation: StatusPresentation {
        StatusPresentation(
            title: statusTitle,
            visualState: RunStatusVisualState.resolve(
                executionStatus: rawValue,
                healthStatus: HealthStatus.healthy.rawValue,
                attentionStatus: AttentionStatus.none.rawValue
            )
        )
    }

    private var statusTitle: LocalizedStringKey {
        switch self {
        case .created: "status.created"
        case .starting: "status.starting"
        case .running: "status.running"
        case .succeeded: "status.succeeded"
        case .failed: "status.failed"
        case .cancelled: "status.cancelled"
        case .lost: "status.lost"
        case .unknown: "status.unknown"
        }
    }
}

extension HealthStatus {
    var presentation: StatusPresentation {
        switch self {
        case .healthy:
            StatusPresentation(
                title: "health.healthy",
                symbol: "checkmark.shield",
                tone: .success,
                priority: .execution
            )
        case .stale:
            StatusPresentation(
                title: "health.stale",
                symbol: "wifi.slash",
                tone: .warning,
                priority: .connectivity
            )
        case .offline:
            StatusPresentation(
                title: "health.offline",
                symbol: "wifi.slash",
                tone: .warning,
                priority: .connectivity
            )
        case .unknown:
            StatusPresentation(
                title: "status.unknown",
                symbol: "questionmark.circle",
                tone: .neutral,
                priority: .unknown
            )
        }
    }
}

extension AttentionStatus {
    var presentation: StatusPresentation {
        switch self {
        case .none:
            StatusPresentation(
                title: "attention.none",
                symbol: "checkmark",
                tone: .neutral,
                priority: .execution
            )
        case .information:
            StatusPresentation(
                title: "attention.information",
                symbol: "info.circle.fill",
                tone: .neutral,
                priority: .information
            )
        case .warning:
            StatusPresentation(
                title: "attention.warning",
                symbol: "exclamationmark.triangle.fill",
                tone: .warning,
                priority: .warning
            )
        case .actionRequired:
            StatusPresentation(
                title: "attention.action_required",
                symbol: "exclamationmark.bubble.fill",
                tone: .critical,
                priority: .actionRequired
            )
        case .unknown:
            StatusPresentation(
                title: "status.unknown",
                symbol: "questionmark.circle",
                tone: .neutral,
                priority: .unknown
            )
        }
    }
}

struct RunStatusBadge: View {
    let presentation: StatusPresentation
    var showsLabel = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if showsLabel {
                HStack(spacing: 6) {
                    symbol
                    Text(presentation.title)
                        .foregroundStyle(.primary)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(badgeBackground, in: Capsule())
                .overlay {
                    if contrast == .increased || reduceTransparency {
                        Capsule().stroke(theme.status(presentation.tone), lineWidth: 1)
                    }
                }
            } else {
                symbol
                    .font(.caption.weight(.semibold))
                    .frame(width: 26, height: 26)
                    .background(badgeBackground, in: Circle())
                    .overlay {
                        if contrast == .increased || reduceTransparency {
                            Circle().stroke(theme.status(presentation.tone), lineWidth: 1)
                        }
                    }
            }
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.title)
    }

    private var symbol: some View {
        Image(systemName: presentation.symbol)
            .accessibilityHidden(true)
            .foregroundStyle(theme.status(presentation.tone))
    }

    private var badgeBackground: Color {
        theme.badgeBackground(presentation.tone)
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
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
            case .compact: 9
            case .prominent: 14
            }
        }

        var spacing: CGFloat {
            switch self {
            case .compact: 7
            case .prominent: 10
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
    let status: RunStatusVisualState
    var emphasis: Emphasis = .compact
    var showsPhase = true
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visualState: RunProgressVisualState {
        RunProgressVisualState.resolve(
            progressKind: progress?.kind.rawValue,
            current: progress?.current,
            total: progress?.total,
            fraction: progress?.fraction,
            status: status
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: emphasis.spacing) {
            if visualState.kind == .determinate, let fraction = visualState.fraction {
                if emphasis == .prominent {
                    prominentDeterminateContent(fraction: fraction)
                } else {
                    compactDeterminateContent(fraction: fraction)
                }
            } else if visualState.kind == .indeterminate {
                indeterminateContent
            } else if showsPhase, let phase, !phase.isEmpty {
                phaseLabel(phase)
            }
        }
    }

    private func prominentDeterminateContent(fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: emphasis.spacing) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    if showsPhase {
                        progressLabel
                    }
                    percentageLabel(fraction)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    if showsPhase {
                        progressLabel
                    }
                    Spacer(minLength: 8)
                    percentageLabel(fraction)
                }
            }

            DeterminateRunProgressBar(
                fraction: fraction,
                tone: status.tone,
                height: emphasis.barHeight,
                addsGlow: emphasis == .prominent && visualState.allowsGlow,
                allowsLiveMotion: visualState.allowsLiveMotion
            )

            if let progress,
               let current = visualState.current,
               let total = visualState.total {
                Text(progressCount(progress, current: current, total: total))
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleProgressLabel)
        .accessibilityValue(Text(fraction, format: .percent))
    }

    private func compactDeterminateContent(fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: emphasis.spacing) {
            DeterminateRunProgressBar(
                fraction: fraction,
                tone: status.tone,
                height: emphasis.barHeight,
                addsGlow: false,
                allowsLiveMotion: visualState.allowsLiveMotion
            )
            if showsPhase, let phase, !phase.isEmpty {
                phaseLabel(phase)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleProgressLabel)
        .accessibilityValue(Text(fraction, format: .percent))
    }

    private var indeterminateContent: some View {
        VStack(alignment: .leading, spacing: emphasis.spacing) {
            if showsPhase {
                progressLabel
            }
            IndeterminateRunProgressBar(
                tone: status.tone,
                height: emphasis.barHeight,
                allowsLiveMotion: visualState.allowsLiveMotion
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

    private func phaseLabel(_ phase: String) -> some View {
        Text(phase)
            .font(emphasis.phaseFont)
            .lineLimit(emphasis == .prominent ? 3 : 2)
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

    private func progressCount(
        _ progress: RunProgress,
        current: Double,
        total: Double
    ) -> String {
        let count = "\(current.formatted()) / \(total.formatted())"
        return progress.unit.flatMap { unit in
            unit.isEmpty ? nil : "\(count) \(unit)"
        } ?? count
    }
}

struct DeterminateRunProgressBar: View {
    let fraction: Double
    let tone: RunBuoyTone
    let height: CGFloat
    let addsGlow: Bool
    let allowsLiveMotion: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    private var boundedFraction: Double {
        min(max(fraction, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.progressTrack(tone))
                Capsule()
                    .fill(theme.progressGradient(tone))
                    .frame(width: proxy.size.width * boundedFraction)
                    .shadow(
                        color: addsGlow ? theme.glow(tone) : .clear,
                        radius: addsGlow ? 6 : 0,
                        y: 1
                    )
            }
        }
        .frame(height: height)
        .animation(
            RunBuoyMotion.progressAnimation(
                reduceMotion: reduceMotion,
                allowsLiveMotion: allowsLiveMotion
            ),
            value: boundedFraction
        )
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

struct IndeterminateRunProgressBar: View {
    let tone: RunBuoyTone
    let height: CGFloat
    let allowsLiveMotion: Bool
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let segmentWidth = proxy.size.width * 0.36
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(theme.progressTrack(tone))
                Capsule()
                    .fill(theme.progressGradient(tone))
                    .frame(width: segmentWidth)
                    .offset(
                        x: reduceMotion || !allowsLiveMotion
                            ? (proxy.size.width - segmentWidth) / 2
                            : (isAnimating ? proxy.size.width : -segmentWidth)
                    )
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
        .animation(
            RunBuoyMotion.indeterminateAnimation(
                reduceMotion: reduceMotion,
                allowsLiveMotion: allowsLiveMotion
            ),
            value: isAnimating
        )
        .onAppear {
            isAnimating = !reduceMotion && allowsLiveMotion
        }
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            isAnimating = !shouldReduceMotion && allowsLiveMotion
        }
        .onChange(of: allowsLiveMotion) { _, canAnimate in
            isAnimating = canAnimate && !reduceMotion
        }
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

struct SignalBuoyProgressRing: View {
    enum Size {
        case minimal
        case compact

        var diameter: CGFloat {
            switch self {
            case .minimal: 22
            case .compact: 24
            }
        }
    }

    let status: RunStatusVisualState
    let progress: RunProgressVisualState
    var size: Size = .minimal

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if shouldShowStatusSymbol {
                Image(systemName: status.symbolName)
                    .font(.system(size: size.diameter * 0.68, weight: .semibold))
                    .foregroundStyle(theme.status(status.tone))
            } else if progress.kind == .determinate, let fraction = progress.fraction {
                determinateRing(fraction: fraction)
            } else if progress.kind == .indeterminate, progress.allowsLiveMotion, !reduceMotion {
                ProgressView()
                    .controlSize(.small)
                    .tint(theme.status(status.tone))
            } else {
                staticIndeterminateRing
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(status.kind.localizedTitle))
        .accessibilityValue(accessibilityValue)
    }

    private var shouldShowStatusSymbol: Bool {
        status.isTerminal || status.kind == .stale || status.kind == .offline
    }

    private func determinateRing(fraction: Double) -> some View {
        let gap = RunBuoyMetrics.progressRingGapDegrees / 360
        let start = gap / 2
        let available = 1 - gap
        let end = start + available * min(max(fraction, 0), 1)

        return ZStack {
            Circle()
                .trim(from: start, to: 1 - start)
                .stroke(
                    theme.progressTrack(status.tone),
                    style: StrokeStyle(
                        lineWidth: RunBuoyMetrics.progressRingStrokeWidth,
                        lineCap: .round
                    )
                )
            Circle()
                .trim(from: start, to: end)
                .stroke(
                    theme.progressRingGradient(status.tone),
                    style: StrokeStyle(
                        lineWidth: RunBuoyMetrics.progressRingStrokeWidth,
                        lineCap: .round
                    )
                )
                .shadow(
                    color: progress.allowsGlow && !reduceTransparency
                        ? theme.glow(status.tone)
                        : .clear,
                    radius: progress.allowsGlow && !reduceTransparency ? 5 : 0
                )
        }
        .rotationEffect(.degrees(90))
        .animation(
            RunBuoyMotion.progressAnimation(
                reduceMotion: reduceMotion,
                allowsLiveMotion: progress.allowsLiveMotion
            ),
            value: fraction
        )
    }

    private var staticIndeterminateRing: some View {
        ZStack {
            Circle()
                .stroke(
                    theme.progressTrack(status.tone),
                    lineWidth: RunBuoyMetrics.progressRingStrokeWidth
                )
            Circle()
                .trim(from: 0.12, to: 0.38)
                .stroke(
                    theme.status(status.tone),
                    style: StrokeStyle(
                        lineWidth: RunBuoyMetrics.progressRingStrokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
    }

    private var accessibilityValue: Text {
        if let fraction = progress.fraction {
            return Text(fraction, format: .percent.precision(.fractionLength(0)))
        } else if progress.kind == .indeterminate {
            return Text("progress.indeterminate")
        }
        return Text(status.kind.localizedTitle)
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

struct RunHeroCard<Content: View>: View {
    let tone: RunBuoyTone
    let allowsLiveEmphasis: Bool
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    init(
        tone: RunBuoyTone,
        allowsLiveEmphasis: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tone = tone
        self.allowsLiveEmphasis = allowsLiveEmphasis
        self.content = content
    }

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.elevatedSurface, in: RoundedRectangle(cornerRadius: RunBuoyMetrics.cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: RunBuoyMetrics.cardCornerRadius)
                    .stroke(theme.border(tone), lineWidth: contrast == .increased ? 1.5 : 1)
            }
            .shadow(
                color: allowsLiveEmphasis && tone == .live && !reduceTransparency
                    ? theme.glow(tone)
                    : .clear,
                radius: allowsLiveEmphasis && tone == .live ? 10 : 0,
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

struct RunCompactCard<Content: View>: View {
    let tone: RunBuoyTone
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    init(
        tone: RunBuoyTone,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tone = tone
        self.content = content
    }

    var body: some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: RunBuoyMetrics.compactCardCornerRadius)
                    .stroke(theme.border(tone), lineWidth: contrast == .increased ? 1.5 : 1)
            }
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

struct RunStateBanner<Content: View>: View {
    let tone: RunBuoyTone
    let symbol: String
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        tone: RunBuoyTone,
        symbol: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tone = tone
        self.symbol = symbol
        self.content = content
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    icon
                    content()
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    icon
                    content()
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.badgeBackground(tone), in: RoundedRectangle(cornerRadius: RunBuoyMetrics.bannerCornerRadius))
        .overlay {
            if reduceTransparency || contrast == .increased {
                RoundedRectangle(cornerRadius: RunBuoyMetrics.bannerCornerRadius)
                    .stroke(theme.status(tone), lineWidth: 1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var icon: some View {
        Image(systemName: symbol)
            .foregroundStyle(theme.status(tone))
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

struct RunMetricCard<Value: View>: View {
    let title: LocalizedStringKey
    let symbol: String?
    @ViewBuilder let value: () -> Value

    init(
        _ title: LocalizedStringKey,
        symbol: String? = nil,
        @ViewBuilder value: @escaping () -> Value
    ) {
        self.title = title
        self.symbol = symbol
        self.value = value
    }

    var body: some View {
        RunCompactCard(tone: .neutral) {
            VStack(alignment: .leading, spacing: 8) {
                if let symbol {
                    Label(title, systemImage: symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                value()
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct RunSummaryActionBar<Actions: View>: View {
    @ViewBuilder let actions: () -> Actions

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder actions: @escaping () -> Actions) {
        self.actions = actions
    }

    var body: some View {
        actions()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(theme.elevatedSurface)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(theme.border())
                    .frame(height: contrast == .increased ? 1 : 0.5)
            }
    }

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
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
                status: run.statusVisualState
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
        StatusBadge(presentation: rowStatusPresentation)
    }

    private var rowStatusPresentation: StatusPresentation {
        let visualState = showsLiveTiming
            ? run.statusVisualState
            : RunStatusVisualState.resolve(
                executionStatus: run.executionStatus.rawValue,
                healthStatus: HealthStatus.healthy.rawValue,
                attentionStatus: AttentionStatus.none.rawValue
            )
        return StatusPresentation(visualState: visualState)
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
           let fraction = progress.boundedFraction {
            ViewThatFits(in: .horizontal) {
                if let current = progress.current, let total = progress.total {
                    progressText(
                        count: progressCount(progress, current: current, total: total),
                        fraction: fraction
                    )
                    progressText(
                        count: compactProgressCount(
                            progress,
                            current: current,
                            total: total
                        ),
                        fraction: fraction
                    )
                }
                progressText(count: nil, fraction: fraction)
            }
            .monospacedDigit()
            .lineLimit(1)
            .layoutPriority(1)
            .accessibilityLabel(fullProgressAccessibilityLabel(progress, fraction: fraction))
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
        _ progress: RunProgress,
        current: Double,
        total: Double
    ) -> String {
        let count = "\(current.formatted()) / \(total.formatted())"
        return progress.unit.flatMap { unit in
            unit.isEmpty ? nil : "\(count) \(unit)"
        } ?? count
    }

    private func compactProgressCount(
        _ progress: RunProgress,
        current: Double,
        total: Double
    ) -> String {
        let format = FloatingPointFormatStyle<Double>.number
            .notation(.compactName)
            .precision(.fractionLength(0...1))
        let count = "\(current.formatted(format)) / \(total.formatted(format))"
        return progress.unit.flatMap { unit in
            unit.isEmpty ? nil : "\(count) \(unit)"
        } ?? count
    }

    private func fullProgressAccessibilityLabel(
        _ progress: RunProgress,
        fraction: Double
    ) -> String {
        let percentage = fraction.formatted(.percent.precision(.fractionLength(0)))
        guard let current = progress.current, let total = progress.total else {
            return percentage
        }
        return "\(progressCount(progress, current: current, total: total)), \(percentage)"
    }
}

private struct RunRowMetadataFooter: View {
    let run: RunSnapshot
    let showsLiveTiming: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

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
                .foregroundStyle(theme.status(run.healthStatus.presentation.tone))
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

    private var theme: RunBuoyTheme {
        RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
    }
}

struct OfflineBanner: View {
    let message: String

    var body: some View {
        RunStateBanner(tone: .warning, symbol: "wifi.slash") {
            bannerText
        }
        .accessibilityIdentifier("runs.offlineBanner")
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
