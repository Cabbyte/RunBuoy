import SwiftUI

enum RunBuoyMetrics {
    static let compactProgressHeight: CGFloat = 9
    static let prominentProgressHeight: CGFloat = 14
    static let liveActivityProgressHeight: CGFloat = 8
    static let compactProgressSpacing: CGFloat = 7
    static let prominentProgressSpacing: CGFloat = 10
    static let statusBadgeIconSize: CGFloat = 26
    static let statusBadgeHorizontalPadding: CGFloat = 9
    static let statusBadgeVerticalPadding: CGFloat = 5
    static let cardCornerRadius: CGFloat = 16
    static let compactCardCornerRadius: CGFloat = 14
    static let bannerCornerRadius: CGFloat = 12
    static let progressRingGapDegrees: Double = 64
    static let progressRingStrokeWidth: CGFloat = 3
}

enum RunBuoyMotion {
    static let progressResponse = 0.4
    static let indeterminateDuration = 1.15

    static func progressAnimation(
        reduceMotion: Bool,
        allowsLiveMotion: Bool
    ) -> Animation? {
        guard !reduceMotion, allowsLiveMotion else { return nil }
        return .spring(response: progressResponse, dampingFraction: 1)
    }

    static func indeterminateAnimation(
        reduceMotion: Bool,
        allowsLiveMotion: Bool
    ) -> Animation? {
        guard !reduceMotion, allowsLiveMotion else { return nil }
        return .linear(duration: indeterminateDuration).repeatForever(autoreverses: false)
    }
}

struct RunBuoyTheme {
    let colorScheme: ColorScheme
    let reduceTransparency: Bool
    let increasedContrast: Bool

    var canvas: Color {
        colorScheme == .dark
            ? Self.rgb(8, 10, 15)
            : Self.rgb(246, 247, 252)
    }

    var surface: Color {
        if increasedContrast {
            return colorScheme == .dark ? .black : .white
        }
        return colorScheme == .dark
            ? Self.rgb(21, 24, 31)
            : Self.rgb(255, 255, 255)
    }

    var elevatedSurface: Color {
        if reduceTransparency || increasedContrast {
            return surface
        }
        return colorScheme == .dark
            ? Self.rgb(29, 33, 43).opacity(0.96)
            : Self.rgb(255, 255, 255).opacity(0.92)
    }

    var brand: Color { Self.rgb(36, 107, 254) }
    var liveStart: Color { Self.rgb(36, 107, 254) }
    var liveEnd: Color { Self.rgb(53, 207, 246) }

    var secondaryText: Color {
        colorScheme == .dark
            ? Self.rgb(190, 190, 198)
            : Self.rgb(78, 78, 86)
    }

    func status(_ tone: RunBuoyTone) -> Color {
        switch (tone, colorScheme) {
        case (.neutral, _):
            .secondary
        case (.live, .light):
            // Primary blue is the accessible foreground for live semantics on
            // light surfaces; cyan remains the gradient/emphasis endpoint.
            Self.rgb(36, 107, 254)
        case (.live, .dark):
            Self.rgb(83, 218, 251)
        case (.success, .light):
            Self.rgb(20, 132, 91)
        case (.success, .dark):
            Self.rgb(54, 211, 153)
        case (.warning, .light):
            Self.rgb(165, 90, 0)
        case (.warning, .dark):
            Self.rgb(255, 179, 64)
        case (.critical, .light):
            Self.rgb(196, 61, 82)
        case (.critical, .dark):
            Self.rgb(255, 102, 128)
        @unknown default:
            .secondary
        }
    }

    func badgeBackground(_ tone: RunBuoyTone) -> Color {
        if reduceTransparency {
            return surface
        }
        return status(tone).opacity(increasedContrast ? 0.20 : 0.12)
    }

    func progressTrack(_ tone: RunBuoyTone) -> Color {
        status(tone).opacity(increasedContrast ? 0.28 : 0.15)
    }

    func progressGradient(_ tone: RunBuoyTone) -> LinearGradient {
        let colors: [Color]
        if tone == .live {
            colors = [liveStart, liveEnd]
        } else {
            let color = status(tone)
            colors = [color.opacity(0.78), color]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    func progressRingGradient(_ tone: RunBuoyTone) -> AngularGradient {
        if tone == .live {
            return AngularGradient(colors: [liveStart, liveEnd], center: .center)
        }
        let color = status(tone)
        return AngularGradient(colors: [color.opacity(0.78), color], center: .center)
    }

    func border(_ tone: RunBuoyTone? = nil) -> Color {
        if let tone, increasedContrast || reduceTransparency {
            return status(tone)
        }
        return Color.primary.opacity(increasedContrast ? 0.30 : 0.10)
    }

    func glow(_ tone: RunBuoyTone) -> Color {
        guard tone == .live else { return .clear }
        return liveEnd.opacity(increasedContrast ? 0.34 : 0.26)
    }

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}

extension View {
    func runBuoyCanvas() -> some View {
        modifier(RunBuoyCanvasModifier())
    }

    func runBuoySecondaryText() -> some View {
        modifier(RunBuoySecondaryTextModifier())
    }
}

private struct RunBuoySecondaryTextModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.foregroundStyle(
            RunBuoyTheme(
                colorScheme: colorScheme,
                reduceTransparency: reduceTransparency,
                increasedContrast: contrast == .increased
            ).secondaryText
        )
    }
}

private struct RunBuoyCanvasModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let theme = RunBuoyTheme(
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency,
            increasedContrast: contrast == .increased
        )
        content.background(theme.canvas)
    }
}

extension RunSnapshot {
    var statusVisualState: RunStatusVisualState {
        RunStatusVisualState.resolve(
            executionStatus: executionStatus.rawValue,
            healthStatus: healthStatus.rawValue,
            attentionStatus: attentionStatus.rawValue
        )
    }

    var progressVisualState: RunProgressVisualState {
        RunProgressVisualState.resolve(
            progressKind: progress?.kind.rawValue,
            current: progress?.current,
            total: progress?.total,
            fraction: progress?.fraction,
            status: statusVisualState
        )
    }
}
