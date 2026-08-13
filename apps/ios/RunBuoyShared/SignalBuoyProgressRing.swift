import SwiftUI

struct SignalBuoyProgressRing: View {
    enum Size: Equatable {
        case minimal
        case compact

        var dimension: CGFloat {
            switch self {
            case .minimal: RunBuoyMetrics.buoyRingMinimalSize
            case .compact: RunBuoyMetrics.buoyRingCompactSize
            }
        }
    }

    let progress: Double
    let tone: RunBuoyTone
    let allowsLiveEmphasis: Bool
    var size: Size = .minimal

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    private var boundedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var visibleArc: Double {
        1 - RunBuoyMetrics.buoyRingGapDegrees / 360
    }

    private var ringGradient: AngularGradient {
        let colors: [Color]
        if tone == .live {
            colors = [RunBuoyTheme.progressLiveStart, RunBuoyTheme.progressLiveEnd]
        } else {
            let color = tone.color
            colors = [color.opacity(0.78), color]
        }
        return AngularGradient(
            colors: colors,
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(206)
        )
    }

    private var addsGlow: Bool {
        allowsLiveEmphasis
            && tone == .live
            && !reduceTransparency
            && contrast != .increased
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: visibleArc)
                .stroke(
                    RunBuoyTheme.progressTrack(
                        for: tone,
                        increasedContrast: contrast == .increased
                    ),
                    style: StrokeStyle(
                        lineWidth: RunBuoyMetrics.buoyRingLineWidth,
                        lineCap: .round
                    )
                )

            Circle()
                .trim(from: 0, to: visibleArc * boundedProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(
                        lineWidth: RunBuoyMetrics.buoyRingLineWidth,
                        lineCap: .round
                    )
                )
                .shadow(
                    color: addsGlow
                        ? RunBuoyTheme.brandLive.opacity(RunBuoyMetrics.progressGlowOpacity)
                        : .clear,
                    radius: addsGlow ? RunBuoyMetrics.progressGlowRadius : 0,
                    y: addsGlow ? 1 : 0
                )
                .animation(
                    RunBuoyMotion.progress(reduceMotion: reduceMotion),
                    value: boundedProgress
                )
        }
        .rotationEffect(.degrees(-58))
        .frame(width: size.dimension, height: size.dimension)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("widget.progress")
        .accessibilityValue(Text(boundedProgress, format: .percent))
    }
}
