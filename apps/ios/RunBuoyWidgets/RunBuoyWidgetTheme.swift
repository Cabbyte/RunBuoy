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

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
