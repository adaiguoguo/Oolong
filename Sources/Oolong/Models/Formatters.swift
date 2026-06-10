import Foundation

enum Fmt {
    /// 74900000 -> "74.9M", 1100000 -> "1.1M", 27700 -> "27.7K"
    static func tokens(_ n: Int) -> String {
        let d = Double(n)
        if d >= 1_000_000_000 { return trim(d / 1_000_000_000) + "B" }
        if d >= 1_000_000 { return trim(d / 1_000_000) + "M" }
        if d >= 1_000 { return trim(d / 1_000) + "K" }
        return "\(n)"
    }

    private static func trim(_ v: Double) -> String {
        String(format: "%.1f", v)
    }

    /// 69.01 -> "$69.01"
    static func cost(_ v: Double) -> String {
        String(format: "$%.2f", v)
    }

    /// 271300 -> "271.3k tok/min"
    static func burnRate(_ tokensPerMinute: Double) -> String {
        let k = tokensPerMinute / 1000
        return String(format: "%.1fk tok/min", k)
    }

    /// 开机时长: 12180s -> "3小时 23分"
    static func uptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let mins = (total % 3600) / 60
        if days > 0 { return I18n.t("\(days)d \(hours)h", "\(days)天 \(hours)小时") }
        return I18n.t("\(hours)h \(mins)m", "\(hours)小时 \(mins)分")
    }

    /// 较长时长: 84600s -> "23时30分" / "23h 30m"
    static func shortDuration(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        if h >= 24 { return I18n.t("\(h / 24)d \(h % 24)h", "\(h / 24)天\(h % 24)时") }
        if h >= 1 { return I18n.t("\(h)h \((total % 3600) / 60)m", "\(h)时\((total % 3600) / 60)分") }
        return I18n.t("\(total / 60)m", "\(total / 60)分")
    }

    /// 剩余: 11785s -> "3:16:25"
    static func countdown(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    /// 字节 -> GB 字符串: "19.5 GB"
    static func gib(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    /// "Updated 7s ago" / "更新于 7秒前"
    static func relativeAge(_ date: Date?) -> String {
        guard let date else { return I18n.t("Not refreshed", "未刷新") }
        let secs = Int(max(0, -date.timeIntervalSinceNow))
        if secs < 60 { return I18n.t("Updated \(secs)s ago", "更新于 \(secs)秒前") }
        let mins = secs / 60
        if mins < 60 { return I18n.t("Updated \(mins)m ago", "更新于 \(mins)分钟前") }
        return I18n.t("Updated \(mins / 60)h ago", "更新于 \(mins / 60)小时前")
    }
}
