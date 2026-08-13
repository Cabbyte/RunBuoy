import SwiftUI

enum RunBuoyMotion {
    static let stateChangeResponse: Double = 0.25
    static let progressResponse: Double = 0.35
    static let selectionResponse: Double = 0.20

    static func stateChange(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(
            response: stateChangeResponse,
            dampingFraction: 1,
            blendDuration: 0
        )
    }

    static func progress(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(
            response: progressResponse,
            dampingFraction: 1,
            blendDuration: 0
        )
    }

    static func selection(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(
            response: selectionResponse,
            dampingFraction: 1,
            blendDuration: 0
        )
    }
}
