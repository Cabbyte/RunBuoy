import SwiftUI
import UIKit

enum RunBuoyTheme {
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .systemBackground)
    static let elevatedSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let separator = Color(uiColor: .separator)
    static let inactive = Color(uiColor: .secondaryLabel)

    static let brandPrimary = adaptiveColor(light: 0x246BFE, dark: 0x6E9BFF)
    static let brandLive = adaptiveColor(light: 0x35CFF6, dark: 0x64D8F8)
    static let success = adaptiveColor(light: 0x14845B, dark: 0x46C697)
    static let warning = adaptiveColor(light: 0xA55A00, dark: 0xF3A34C)
    static let critical = adaptiveColor(light: 0xC43D52, dark: 0xFF7187)

    static let liveSoft = brandLive.opacity(0.12)
    static let liveSurface = adaptiveColor(light: 0xEAF9FE, dark: 0x102A33)
    static let progressLiveStart = brandPrimary
    static let progressLiveEnd = brandLive
    static let progressTrack = brandLive.opacity(0.15)

    static func color(for tone: RunBuoyTone) -> Color {
        switch tone {
        case .neutral: inactive
        case .live: brandLive
        case .success: success
        case .warning: warning
        case .critical: critical
        }
    }

    static func progressGradient(for tone: RunBuoyTone) -> LinearGradient {
        let colors: [Color]
        switch tone {
        case .live:
            colors = [progressLiveStart, progressLiveEnd]
        default:
            let color = color(for: tone)
            colors = [color.opacity(0.78), color]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    static func progressTrack(for tone: RunBuoyTone, increasedContrast: Bool) -> Color {
        color(for: tone).opacity(increasedContrast ? 0.28 : 0.15)
    }

    static func badgeBackground(
        for tone: RunBuoyTone,
        increasedContrast: Bool,
        reduceTransparency: Bool
    ) -> Color {
        if reduceTransparency {
            return elevatedSurface
        }
        return color(for: tone).opacity(increasedContrast ? 0.20 : 0.12)
    }

    private static func adaptiveColor(light: UInt32, dark: UInt32) -> Color {
        Color(
            uiColor: UIColor { traits in
                UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
    }
}

extension RunBuoyTone {
    var color: Color {
        RunBuoyTheme.color(for: self)
    }
}

extension RunStatusVisualState {
    var localizedTitle: LocalizedStringKey {
        LocalizedStringKey(titleKey)
    }

    var color: Color {
        tone.color
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
