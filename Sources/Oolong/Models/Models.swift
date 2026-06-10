import Foundation

struct TokenCost: Equatable {
    var tokens: Int
    var costUSD: Double

    static let zero = TokenCost(tokens: 0, costUSD: 0)
}

struct FiveHourBlock: Equatable {
    var tokens: Int
    var costUSD: Double
    var tokensPerMinute: Double
    var endTime: Date

    var remaining: TimeInterval {
        max(0, endTime.timeIntervalSinceNow)
    }
}

/// 官方限流窗口（来自 statusline 的 rate_limits，与 /usage 一致）
struct RateLimitWindow: Equatable {
    var usedPercentage: Int
    var resetsAt: Date

    var remaining: TimeInterval { max(0, resetsAt.timeIntervalSinceNow) }
}

struct RateLimitInfo: Equatable {
    var fiveHour: RateLimitWindow?
    var sevenDay: RateLimitWindow?
    var asOf: Date

    var isStale: Bool { Date().timeIntervalSince(asOf) > 120 }
}

struct ClaudeUsage: Equatable {
    var today: TokenCost = .zero
    var week: TokenCost = .zero
    var month: TokenCost = .zero
    var fiveHour: FiveHourBlock? = nil
    var hasActiveSession: Bool = false
}

struct SystemStats: Equatable {
    var uptime: TimeInterval = 0
    var cpuPercent: Double = 0
    var memoryUsedBytes: UInt64 = 0
    var memoryTotalBytes: UInt64 = 0
    var batteryPercent: Int? = nil
    var isCharging: Bool = false
    var hasBattery: Bool = false
}

enum KeepAwakeMode: String, CaseIterable, Identifiable {
    case standard
    case lidClosed

    var id: String { rawValue }
    var label: String {
        switch self {
        case .standard: return I18n.t("Standard", "标准防睡眠")
        case .lidClosed: return I18n.t("Lid closed", "合盖也不睡")
        }
    }
}

enum KeepAwakeDuration: Identifiable, Equatable {
    case forever
    case hours(Int)

    var id: String {
        switch self {
        case .forever: return "forever"
        case .hours(let h): return "h\(h)"
        }
    }

    var label: String {
        switch self {
        case .forever: return I18n.t("Forever", "永久")
        case .hours(let h): return I18n.t("\(h)h", "\(h)小时")
        }
    }

    var seconds: Int? {
        switch self {
        case .forever: return nil
        case .hours(let h): return h * 3600
        }
    }

    static let all: [KeepAwakeDuration] = [.forever, .hours(1), .hours(2), .hours(4)]
}
