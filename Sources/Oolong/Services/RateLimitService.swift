import Foundation

/// 读取 statusline 写入的官方限流数据 ~/.claude/ccbar-ratelimits.json。
/// 零凭据、零 API：数据由 Claude Code 在 statusline 渲染时提供，和 /usage 同源。
final class RateLimitProvider {
    private let path: URL

    init(claudeDir: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")) {
        self.path = claudeDir.appendingPathComponent("ccbar-ratelimits.json")
    }

    func read() -> RateLimitInfo? {
        guard let data = try? Data(contentsOf: path),
              let file = try? JSONDecoder().decode(RateLimitFile.self, from: data) else { return nil }
        let mtime = (try? path.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
        let five = file.five_hour.map(Self.window)
        let seven = file.seven_day.map(Self.window)
        guard five != nil || seven != nil else { return nil }
        return RateLimitInfo(fiveHour: five, sevenDay: seven, asOf: mtime)
    }

    private static func window(_ w: RateLimitFile.Window) -> RateLimitWindow {
        RateLimitWindow(usedPercentage: Int(w.used_percentage.rounded()), resetsAt: Date(timeIntervalSince1970: w.resets_at))
    }
}

private struct RateLimitFile: Decodable {
    let five_hour: Window?
    let seven_day: Window?

    struct Window: Decodable {
        let used_percentage: Double   // 源数据是浮点(如 28.000000000000004)，不能用 Int 解码
        let resets_at: Double
    }
}
