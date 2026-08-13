import Foundation
import SwiftUI

enum RunBuoyVisualStyle: Equatable {
    case material
    case liquidGlass

    static func resolved(
        osMajorVersion: Int,
        liquidGlassAPIsAvailable: Bool
    ) -> RunBuoyVisualStyle {
        osMajorVersion >= 26 && liquidGlassAPIsAvailable ? .liquidGlass : .material
    }

    static var current: RunBuoyVisualStyle {
#if compiler(>=6.2)
        resolved(
            osMajorVersion: ProcessInfo.processInfo.operatingSystemVersion.majorVersion,
            liquidGlassAPIsAvailable: true
        )
#else
        .material
#endif
    }
}

extension View {
    @ViewBuilder
    func runBuoyProminentButtonStyle() -> some View {
        buttonStyle(.borderedProminent)
            .tint(.primary)
            .foregroundStyle(RunBuoyTheme.surface)
    }

    @ViewBuilder
    func runBuoySecondaryButtonStyle() -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *), RunBuoyVisualStyle.current == .liquidGlass {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
#else
        buttonStyle(.bordered)
#endif
    }

    @ViewBuilder
    func runBuoyBottomScrollEdgeStyle() -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *), RunBuoyVisualStyle.current == .liquidGlass {
            scrollEdgeEffectHidden(true, for: .bottom)
        } else {
            self
        }
#else
        self
#endif
    }

    @ViewBuilder
    func runBuoyReadableBottomScrollEdgeStyle() -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *), RunBuoyVisualStyle.current == .liquidGlass {
            scrollEdgeEffectStyle(.hard, for: .bottom)
        } else {
            self
        }
#else
        self
#endif
    }
}
