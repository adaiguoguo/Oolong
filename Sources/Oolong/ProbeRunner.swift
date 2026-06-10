import Foundation

/// 无 GUI 的自检：采集系统状态 + 拉取 ccusage 用量，打印 JSON，供验证脚本断言。
enum ProbeRunner {
    static func run() {
        let statsService = SystemStatsService()
        _ = statsService.sample()            // CPU 基线
        Thread.sleep(forTimeInterval: 0.6)
        let stats = statsService.sample()

        let sem = DispatchSemaphore(value: 0)
        var output: [String: Any] = [:]

        if let rl = RateLimitProvider().read() {
            var d: [String: Any] = ["asOfSecondsAgo": Int(Date().timeIntervalSince(rl.asOf)), "stale": rl.isStale]
            if let f = rl.fiveHour { d["fiveHour"] = ["usedPercentage": f.usedPercentage, "resetsInSeconds": Int(f.remaining)] }
            if let s = rl.sevenDay { d["sevenDay"] = ["usedPercentage": s.usedPercentage, "resetsInSeconds": Int(s.remaining)] }
            output["rateLimit"] = d
        } else {
            output["rateLimit"] = "（无：未配 statusline 写入或文件缺失）"
        }

        output["system"] = [
            "uptimeSeconds": Int(stats.uptime),
            "cpuPercent": stats.cpuPercent,
            "memUsedBytes": stats.memoryUsedBytes,
            "memTotalBytes": stats.memoryTotalBytes,
            "batteryPercent": stats.batteryPercent as Any,
            "hasBattery": stats.hasBattery,
        ]

        Task {
            do {
                let u = try await CCUsageProvider().fetch()
                var fiveHour: [String: Any] = [:]
                if let b = u.fiveHour {
                    fiveHour = [
                        "tokens": b.tokens,
                        "costUSD": b.costUSD,
                        "tokensPerMinute": b.tokensPerMinute,
                        "remainingSeconds": Int(b.remaining),
                    ]
                }
                output["usage"] = [
                    "todayTokens": u.today.tokens,
                    "todayCost": u.today.costUSD,
                    "weekTokens": u.week.tokens,
                    "weekCost": u.week.costUSD,
                    "monthTokens": u.month.tokens,
                    "monthCost": u.month.costUSD,
                    "fiveHour": fiveHour,
                    "hasActiveSession": u.hasActiveSession,
                ]
                output["ok"] = true
            } catch {
                output["ok"] = false
                output["error"] = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            }
            sem.signal()
        }
        if sem.wait(timeout: .now() + 30) == .timedOut {
            output["ok"] = false
            output["error"] = "probe 超时(30s)：ccusage 无响应"
        }

        if let data = try? JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys]),
           let s = String(data: data, encoding: .utf8) {
            print(s)
        }
    }
}
