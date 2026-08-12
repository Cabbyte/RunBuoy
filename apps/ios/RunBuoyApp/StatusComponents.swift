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
    let color: Color
}

extension ExecutionStatus {
    var presentation: StatusPresentation {
        switch self {
        case .created:
            StatusPresentation(title: "status.created", symbol: "circle", color: .secondary)
        case .starting:
            StatusPresentation(title: "status.starting", symbol: "hourglass", color: .blue)
        case .running:
            StatusPresentation(
                title: "status.running",
                symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                color: .blue
            )
        case .succeeded:
            StatusPresentation(title: "status.succeeded", symbol: "checkmark", color: .green)
        case .failed:
            StatusPresentation(title: "status.failed", symbol: "xmark", color: .red)
        case .cancelled:
            StatusPresentation(title: "status.cancelled", symbol: "minus", color: .orange)
        case .lost:
            StatusPresentation(title: "status.lost", symbol: "questionmark", color: .orange)
        case .unknown:
            StatusPresentation(title: "status.unknown", symbol: "circle", color: .secondary)
        }
    }

    var progressTint: Color {
        switch self {
        case .succeeded:
            .green
        case .failed:
            .red
        case .cancelled, .lost:
            .orange
        case .created, .starting, .running, .unknown:
            .accentColor
        }
    }
}

extension HealthStatus {
    var presentation: StatusPresentation {
        switch self {
        case .healthy:
            StatusPresentation(title: "health.healthy", symbol: "checkmark.shield", color: .green)
        case .stale:
            StatusPresentation(title: "health.stale", symbol: "clock.badge.exclamationmark", color: .orange)
        case .offline:
            StatusPresentation(title: "health.offline", symbol: "wifi.slash", color: .secondary)
        case .unknown:
            StatusPresentation(title: "status.unknown", symbol: "questionmark.circle", color: .secondary)
        }
    }
}

extension AttentionStatus {
    var presentation: StatusPresentation {
        switch self {
        case .none:
            StatusPresentation(title: "attention.none", symbol: "checkmark", color: .secondary)
        case .information:
            StatusPresentation(title: "attention.information", symbol: "info.circle.fill", color: .blue)
        case .warning:
            StatusPresentation(title: "attention.warning", symbol: "exclamationmark.triangle.fill", color: .orange)
        case .actionRequired:
            StatusPresentation(title: "attention.action_required", symbol: "exclamationmark.bubble.fill", color: .red)
        case .unknown:
            StatusPresentation(title: "status.unknown", symbol: "questionmark.circle", color: .secondary)
        }
    }
}

struct StatusBadge: View {
    let presentation: StatusPresentation
    var showsLabel = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

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
                        Capsule().stroke(presentation.color, lineWidth: 1)
                    }
                }
            } else {
                symbol
                    .font(.caption.weight(.semibold))
                    .frame(width: 26, height: 26)
                    .background(badgeBackground, in: Circle())
                    .overlay {
                        if contrast == .increased || reduceTransparency {
                            Circle().stroke(presentation.color, lineWidth: 1)
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
            .foregroundStyle(presentation.color)
    }

    private var badgeBackground: Color {
        reduceTransparency
            ? Color(uiColor: .secondarySystemBackground)
            : presentation.color.opacity(contrast == .increased ? 0.2 : 0.12)
    }
}

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
    let showsIndeterminate: Bool
    var emphasis: Emphasis = .compact
    var tint: Color = .accentColor
    var showsPhase = true
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: emphasis.spacing) {
            if let fraction = progress?.boundedFraction {
                if emphasis == .prominent {
                    prominentDeterminateContent(fraction: fraction)
                } else {
                    compactDeterminateContent(fraction: fraction)
                }
            } else if showsIndeterminate {
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
                tint: tint,
                height: emphasis.barHeight,
                addsGlow: emphasis == .prominent
            )

            if let progress,
               let current = progress.current,
               let total = progress.total {
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
                tint: tint,
                height: emphasis.barHeight,
                addsGlow: false
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
                tint: tint,
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

private struct DeterminateRunProgressBar: View {
    let fraction: Double
    let tint: Color
    let height: CGFloat
    let addsGlow: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(contrast == .increased ? 0.28 : 0.15))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.78), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * fraction)
                    .shadow(
                        color: addsGlow ? tint.opacity(0.34) : .clear,
                        radius: addsGlow ? 6 : 0,
                        y: 1
                    )
            }
        }
        .frame(height: height)
        .animation(reduceMotion ? nil : .smooth(duration: 0.4), value: fraction)
        .accessibilityHidden(true)
    }
}

private struct IndeterminateRunProgressBar: View {
    let tint: Color
    let height: CGFloat
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { proxy in
            let segmentWidth = proxy.size.width * 0.36
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(tint.opacity(contrast == .increased ? 0.28 : 0.15))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.62), tint],
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
                showsIndeterminate: showsLiveTiming && run.executionStatus.isActive,
                tint: run.executionStatus.progressTint
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
        if showsLiveTiming {
            if run.attentionStatus != .none {
                return run.attentionStatus.presentation
            }
            if run.healthStatus != .healthy {
                return run.healthStatus.presentation
            }
        }
        return run.executionStatus.presentation
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
            reduceTransparency ? Color(uiColor: .secondarySystemBackground) : .orange.opacity(0.12),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            if reduceTransparency || contrast == .increased {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.orange, lineWidth: 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("runs.offlineBanner")
    }

    private var offlineIcon: some View {
        Image(systemName: "wifi.slash")
            .foregroundStyle(.orange)
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
