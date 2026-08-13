import Foundation

public enum RunBuoyTone: String, Codable, CaseIterable, Hashable, Sendable {
    case neutral
    case live
    case success
    case warning
    case critical
}

public enum RunStatusPriority: Int, Codable, Comparable, Hashable, Sendable {
    case unknown = 0
    case execution = 10
    case information = 20
    case warning = 30
    case actionRequired = 40
    case connectivity = 50
    case terminal = 60

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct RunStatusVisualState: Equatable, Hashable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Hashable, Sendable {
        case created
        case starting
        case running
        case succeeded
        case failed
        case cancelled
        case lost
        case stale
        case offline
        case actionRequired
        case warning
        case information
        case unknown
    }

    public let kind: Kind
    public let tone: RunBuoyTone
    public let priority: RunStatusPriority
    public let symbolName: String
    public let isActive: Bool
    public let isTerminal: Bool
    public let allowsLiveEmphasis: Bool

    public static func resolve(
        executionStatus: String,
        healthStatus: String,
        attentionStatus: String,
        isStale: Bool = false
    ) -> Self {
        let execution = normalized(executionStatus)
        let health = isStale ? "STALE" : normalized(healthStatus)
        let attention = normalized(attentionStatus)
        let isActive = activeExecutionStatuses.contains(execution)

        // Terminal execution is definitive. Health and attention are snapshots of an
        // earlier point in time and must never visually override the terminal outcome.
        if let terminal = terminalState(for: execution) {
            return terminal
        }

        // Connectivity only overrides a run that is still active. Historical and
        // terminal runs retain their execution outcome instead of looking live/offline.
        if isActive, health == "STALE" {
            return state(
                .stale,
                tone: .warning,
                priority: .connectivity,
                symbol: "wifi.slash",
                isActive: true
            )
        }
        if isActive, health == "OFFLINE" {
            return state(
                .offline,
                tone: .warning,
                priority: .connectivity,
                symbol: "wifi.slash",
                isActive: true
            )
        }

        switch attention {
        case "ACTION_REQUIRED":
            return state(
                .actionRequired,
                tone: .critical,
                priority: .actionRequired,
                symbol: "exclamationmark.bubble.fill",
                isActive: isActive
            )
        case "WARNING":
            return state(
                .warning,
                tone: .warning,
                priority: .warning,
                symbol: "exclamationmark.triangle.fill",
                isActive: isActive
            )
        case "INFORMATION":
            return state(
                .information,
                tone: .neutral,
                priority: .information,
                symbol: "info.circle.fill",
                isActive: isActive
            )
        default:
            break
        }

        switch execution {
        case "CREATED":
            return state(
                .created,
                tone: .neutral,
                priority: .execution,
                symbol: "circle",
                isActive: true
            )
        case "STARTING":
            return state(
                .starting,
                tone: .live,
                priority: .execution,
                symbol: "hourglass",
                isActive: true,
                allowsLiveEmphasis: true
            )
        case "RUNNING":
            return state(
                .running,
                tone: .live,
                priority: .execution,
                symbol: "waveform.path.ecg",
                isActive: true,
                allowsLiveEmphasis: true
            )
        default:
            return state(
                .unknown,
                tone: .neutral,
                priority: .unknown,
                symbol: "questionmark.circle",
                isActive: false
            )
        }
    }

    private static let activeExecutionStatuses: Set<String> = [
        "CREATED", "STARTING", "RUNNING"
    ]

    private static func terminalState(for execution: String) -> Self? {
        switch execution {
        case "SUCCEEDED":
            state(
                .succeeded,
                tone: .success,
                priority: .terminal,
                symbol: "checkmark.circle.fill",
                isTerminal: true
            )
        case "FAILED":
            state(
                .failed,
                tone: .critical,
                priority: .terminal,
                symbol: "xmark.octagon.fill",
                isTerminal: true
            )
        case "CANCELLED":
            state(
                .cancelled,
                tone: .neutral,
                priority: .terminal,
                symbol: "minus.circle.fill",
                isTerminal: true
            )
        case "LOST":
            state(
                .lost,
                tone: .critical,
                priority: .terminal,
                symbol: "questionmark.diamond.fill",
                isTerminal: true
            )
        default:
            nil
        }
    }

    private static func state(
        _ kind: Kind,
        tone: RunBuoyTone,
        priority: RunStatusPriority,
        symbol: String,
        isActive: Bool = false,
        isTerminal: Bool = false,
        allowsLiveEmphasis: Bool = false
    ) -> Self {
        Self(
            kind: kind,
            tone: tone,
            priority: priority,
            symbolName: symbol,
            isActive: isActive,
            isTerminal: isTerminal,
            allowsLiveEmphasis: allowsLiveEmphasis && !isTerminal
        )
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}

public struct RunProgressVisualState: Equatable, Hashable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Hashable, Sendable {
        case determinate
        case indeterminate
        case unavailable
    }

    public let kind: Kind
    public let fraction: Double?
    public let current: Double?
    public let total: Double?
    public let allowsLiveMotion: Bool
    public let allowsGlow: Bool

    public static func resolve(
        progressKind: String?,
        current: Double?,
        total: Double?,
        fraction: Double?,
        status: RunStatusVisualState
    ) -> Self {
        if normalized(progressKind) == "DETERMINATE",
           let current,
           let total,
           let fraction,
           current.isFinite,
           total.isFinite,
           fraction.isFinite,
           total > 0,
           current >= 0 {
            let boundedFraction = min(max(fraction, 0), 1)
            return Self(
                kind: .determinate,
                fraction: boundedFraction,
                current: current,
                total: total,
                allowsLiveMotion: status.allowsLiveEmphasis,
                allowsGlow: status.tone == .live && status.allowsLiveEmphasis
            )
        }

        if status.isActive {
            return Self(
                kind: .indeterminate,
                fraction: nil,
                current: nil,
                total: nil,
                allowsLiveMotion: status.allowsLiveEmphasis,
                allowsGlow: false
            )
        }

        return Self(
            kind: .unavailable,
            fraction: nil,
            current: nil,
            total: nil,
            allowsLiveMotion: false,
            allowsGlow: false
        )
    }

    public static func trustedFraction(
        progressKind: String?,
        current: Double?,
        total: Double?,
        fraction: Double?
    ) -> Double? {
        let status = RunStatusVisualState.resolve(
            executionStatus: "RUNNING",
            healthStatus: "HEALTHY",
            attentionStatus: "NONE"
        )
        let state = resolve(
            progressKind: progressKind,
            current: current,
            total: total,
            fraction: fraction,
            status: status
        )
        return state.kind == .determinate ? state.fraction : nil
    }

    private static func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
    }
}

public extension RunActivityAttributes.ContentState {
    func statusVisualState(isStale: Bool = false) -> RunStatusVisualState {
        RunStatusVisualState.resolve(
            executionStatus: executionStatus,
            healthStatus: healthStatus,
            attentionStatus: attentionStatus,
            isStale: isStale
        )
    }

    func progressVisualState(isStale: Bool = false) -> RunProgressVisualState {
        RunProgressVisualState.resolve(
            progressKind: progressKind,
            current: current,
            total: total,
            fraction: progress,
            status: statusVisualState(isStale: isStale)
        )
    }
}
