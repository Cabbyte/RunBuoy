import SwiftUI

/// Widget-safe semantic colors. This deliberately depends only on the shared
/// `RunBuoyTone`, so Live Activities do not need App-only assets or theme types.
enum RunBuoyWidgetToneColor {
    static func resolve(_ tone: RunBuoyTone, colorScheme: ColorScheme) -> Color {
        switch (tone, colorScheme) {
        case (.neutral, _):
            .secondary
        case (.live, .light):
            rgb(32, 182, 226)
        case (.live, .dark):
            rgb(83, 218, 251)
        case (.success, .light):
            rgb(20, 132, 91)
        case (.success, .dark):
            rgb(54, 211, 153)
        case (.warning, .light):
            rgb(165, 90, 0)
        case (.warning, .dark):
            rgb(255, 179, 64)
        case (.critical, .light):
            rgb(196, 61, 82)
        case (.critical, .dark):
            rgb(255, 102, 128)
        @unknown default:
            .secondary
        }
    }

    static func progressTrack(
        _ tone: RunBuoyTone,
        colorScheme: ColorScheme,
        increasedContrast: Bool
    ) -> Color {
        resolve(tone, colorScheme: colorScheme)
            .opacity(increasedContrast ? 0.34 : 0.18)
    }

    static func progressGradient(
        _ tone: RunBuoyTone,
        colorScheme: ColorScheme
    ) -> LinearGradient {
        LinearGradient(
            colors: progressColors(tone, colorScheme: colorScheme),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func progressRingGradient(
        _ tone: RunBuoyTone,
        colorScheme: ColorScheme
    ) -> AngularGradient {
        AngularGradient(
            colors: progressColors(tone, colorScheme: colorScheme),
            center: .center
        )
    }

    static func glow(_ tone: RunBuoyTone, colorScheme: ColorScheme) -> Color {
        guard tone == .live else { return .clear }
        return brandLive(colorScheme: colorScheme).opacity(0.26)
    }

    private static func progressColors(
        _ tone: RunBuoyTone,
        colorScheme: ColorScheme
    ) -> [Color] {
        if tone == .live {
            return [brandPrimary, brandLive(colorScheme: colorScheme)]
        }
        let color = resolve(tone, colorScheme: colorScheme)
        return [color, color]
    }

    private static var brandPrimary: Color { rgb(36, 107, 254) }

    private static func brandLive(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? rgb(83, 218, 251) : rgb(53, 207, 246)
    }

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
