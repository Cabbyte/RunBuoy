import Foundation

enum RunStatusVisualCategory: String, Sendable {
    case neutral
    case starting
    case running
    case information
    case warning
    case actionRequired
    case stale
    case offline
    case succeeded
    case failed
    case cancelled
    case lost

    var canShowProgressRing: Bool {
        switch self {
        case .running, .information, .warning, .actionRequired:
            true
        default:
            false
        }
    }
}

struct RunStatusVisualState: Equatable, Sendable {
    enum Priority: Int, Comparable, Sendable {
        case neutral = 0
        case active = 100
        case information = 200
        case warning = 300
        case actionRequired = 400
        case staleOrOffline = 500
        case terminal = 600

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let category: RunStatusVisualCategory
    let titleKey: String
    let symbol: String
    let tone: RunBuoyTone
    let priority: Priority
    let isTerminal: Bool
    let allowsLiveEmphasis: Bool

    static func resolve(
        executionStatus: String,
        healthStatus: String,
        attentionStatus: String,
        isStale: Bool = false
    ) -> RunStatusVisualState {
        let execution = executionStatus.uppercased()
        let health = healthStatus.uppercased()
        let attention = attentionStatus.uppercased()

        if let terminal = terminalState(for: execution) {
            return terminal
        }
        if isStale || health == "STALE" {
            return stale
        }
        if health == "OFFLINE" {
            return offline
        }
        if attention == "ACTION_REQUIRED" {
            return actionRequired
        }
        if attention == "WARNING" {
            return warning
        }
        if attention == "INFORMATION" {
            return information
        }
        return executionState(for: execution)
    }

    static func execution(_ rawValue: String) -> RunStatusVisualState {
        terminalState(for: rawValue.uppercased())
            ?? executionState(for: rawValue.uppercased())
    }

    static func health(_ rawValue: String) -> RunStatusVisualState {
        switch rawValue.uppercased() {
        case "HEALTHY":
            return RunStatusVisualState(
                category: .neutral,
                titleKey: "health.healthy",
                symbol: "checkmark.shield",
                tone: .success,
                priority: .neutral,
                isTerminal: false,
                allowsLiveEmphasis: false
            )
        case "STALE":
            return stale
        case "OFFLINE":
            return offline
        default:
            return neutral
        }
    }

    static func attention(_ rawValue: String) -> RunStatusVisualState {
        switch rawValue.uppercased() {
        case "INFORMATION": information
        case "WARNING": warning
        case "ACTION_REQUIRED": actionRequired
        case "NONE":
            RunStatusVisualState(
                category: .neutral,
                titleKey: "attention.none",
                symbol: "checkmark",
                tone: .neutral,
                priority: .neutral,
                isTerminal: false,
                allowsLiveEmphasis: false
            )
        default: neutral
        }
    }

    private static func terminalState(for execution: String) -> RunStatusVisualState? {
        switch execution {
        case "SUCCEEDED":
            RunStatusVisualState(
                category: .succeeded,
                titleKey: "status.succeeded",
                symbol: "checkmark.circle.fill",
                tone: .success,
                priority: .terminal,
                isTerminal: true,
                allowsLiveEmphasis: false
            )
        case "FAILED":
            RunStatusVisualState(
                category: .failed,
                titleKey: "status.failed",
                symbol: "xmark.octagon.fill",
                tone: .critical,
                priority: .terminal,
                isTerminal: true,
                allowsLiveEmphasis: false
            )
        case "CANCELLED":
            RunStatusVisualState(
                category: .cancelled,
                titleKey: "status.cancelled",
                symbol: "minus.circle.fill",
                tone: .neutral,
                priority: .terminal,
                isTerminal: true,
                allowsLiveEmphasis: false
            )
        case "LOST":
            RunStatusVisualState(
                category: .lost,
                titleKey: "status.lost",
                symbol: "questionmark.diamond.fill",
                tone: .warning,
                priority: .terminal,
                isTerminal: true,
                allowsLiveEmphasis: false
            )
        default:
            nil
        }
    }

    private static func executionState(for execution: String) -> RunStatusVisualState {
        switch execution {
        case "STARTING":
            RunStatusVisualState(
                category: .starting,
                titleKey: "status.starting",
                symbol: "hourglass",
                tone: .live,
                priority: .active,
                isTerminal: false,
                allowsLiveEmphasis: false
            )
        case "RUNNING":
            RunStatusVisualState(
                category: .running,
                titleKey: "status.running",
                symbol: "waveform.path.ecg",
                tone: .live,
                priority: .active,
                isTerminal: false,
                allowsLiveEmphasis: true
            )
        case "CREATED":
            RunStatusVisualState(
                category: .neutral,
                titleKey: "status.created",
                symbol: "circle",
                tone: .neutral,
                priority: .neutral,
                isTerminal: false,
                allowsLiveEmphasis: false
            )
        default:
            neutral
        }
    }

    private static let stale = RunStatusVisualState(
        category: .stale,
        titleKey: "health.stale",
        symbol: "wifi.slash",
        tone: .warning,
        priority: .staleOrOffline,
        isTerminal: false,
        allowsLiveEmphasis: false
    )

    private static let offline = RunStatusVisualState(
        category: .offline,
        titleKey: "health.offline",
        symbol: "wifi.slash",
        tone: .neutral,
        priority: .staleOrOffline,
        isTerminal: false,
        allowsLiveEmphasis: false
    )

    private static let actionRequired = RunStatusVisualState(
        category: .actionRequired,
        titleKey: "attention.action_required",
        symbol: "exclamationmark.bubble.fill",
        tone: .critical,
        priority: .actionRequired,
        isTerminal: false,
        allowsLiveEmphasis: false
    )

    private static let warning = RunStatusVisualState(
        category: .warning,
        titleKey: "attention.warning",
        symbol: "exclamationmark.triangle.fill",
        tone: .warning,
        priority: .warning,
        isTerminal: false,
        allowsLiveEmphasis: false
    )

    private static let information = RunStatusVisualState(
        category: .information,
        titleKey: "attention.information",
        symbol: "info.circle.fill",
        tone: .live,
        priority: .information,
        isTerminal: false,
        allowsLiveEmphasis: false
    )

    private static let neutral = RunStatusVisualState(
        category: .neutral,
        titleKey: "status.unknown",
        symbol: "circle",
        tone: .neutral,
        priority: .neutral,
        isTerminal: false,
        allowsLiveEmphasis: false
    )
}

struct TrustedRunProgress: Equatable, Sendable {
    let current: Double
    let total: Double
    let fraction: Double
    let unit: String?

    init?(
        kind: String,
        current: Double?,
        total: Double?,
        fraction: Double?,
        unit: String? = nil
    ) {
        guard kind.lowercased() == "determinate",
              let current,
              let total,
              current.isFinite,
              total.isFinite,
              current >= 0,
              total > 0
        else {
            return nil
        }

        let reportedFraction = fraction.flatMap { $0.isFinite ? $0 : nil }
        let resolvedFraction = reportedFraction ?? current / total
        self.current = current
        self.total = total
        self.fraction = min(max(resolvedFraction, 0), 1)
        self.unit = unit.flatMap { $0.isEmpty ? nil : $0 }
    }
}

extension RunActivityAttributes.ContentState {
    func visualState(isStale: Bool = false) -> RunStatusVisualState {
        RunStatusVisualState.resolve(
            executionStatus: executionStatus,
            healthStatus: healthStatus,
            attentionStatus: attentionStatus,
            isStale: isStale
        )
    }

    var trustedProgress: TrustedRunProgress? {
        TrustedRunProgress(
            kind: progressKind,
            current: current,
            total: total,
            fraction: progress
        )
    }
}
