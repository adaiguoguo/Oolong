import Foundation

protocol UsageProvider {
    func fetch() async throws -> ClaudeUsage
}

enum UsageError: Error, LocalizedError {
    case ccusageNotFound
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .ccusageNotFound:
            return I18n.t("ccusage not found — install it: bun add -g ccusage (or npm i -g ccusage)",
                          "找不到 ccusage，请先安装 (bun add -g ccusage 或 npm i -g ccusage)")
        case .commandFailed(let s):
            return I18n.t("ccusage failed: \(s)", "ccusage 执行失败: \(s)")
        }
    }
}

/// 通过调用 ccusage CLI 获取 Claude Code 用量。
/// 去重 / 5h block 切窗口 / 模型定价均由 ccusage 处理，避免自己解析 jsonl 出错。
final class CCUsageProvider: UsageProvider {
    private let claudeDir: URL
    private var cachedBinary: String?
    private var cachedPath: String?

    init(claudeDir: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")) {
        self.claudeDir = claudeDir
    }

    func fetch() async throws -> ClaudeUsage {
        let bin = try resolveBinary()
        _ = resolvedPATH()              // 预热 PATH 缓存，避免 4 个并发调用各开一次登录 shell
        let today = Self.yyyymmdd(Date())

        // 不加 -O：用在线定价。离线定价表缺当前 Opus/Sonnet 价，会把 $ 严重算低(差几十倍)
        async let dailyRows = runUsage(bin, ["daily", "--json", "-s", today])
        async let weeklyRows = runUsage(bin, ["weekly", "--json", "-o", "desc"])
        async let monthlyRows = runUsage(bin, ["monthly", "--json", "-o", "desc"])
        async let block = runBlocks(bin)
        async let active = detectActiveSession()

        let daily = try await dailyRows
        let weekly = try await weeklyRows
        let monthly = try await monthlyRows

        var usage = ClaudeUsage()
        usage.today = daily.first.map { TokenCost(tokens: $0.totalTokens, costUSD: $0.totalCost) } ?? .zero
        usage.week = Self.currentWeek(weekly).map { TokenCost(tokens: $0.totalTokens, costUSD: $0.totalCost) } ?? .zero
        let curMonth = Self.yyyyMM(Date())
        usage.month = (monthly.first(where: { $0.period == curMonth }) ?? monthly.first)
            .map { TokenCost(tokens: $0.totalTokens, costUSD: $0.totalCost) } ?? .zero
        usage.fiveHour = try await block
        usage.hasActiveSession = await active
        return usage
    }

    // MARK: - ccusage 调用

    private func runUsage(_ bin: String, _ args: [String]) async throws -> [UsageRow] {
        let data = try await run(bin, args)
        let decoded = try JSONDecoder().decode(UsageReport.self, from: data)
        return decoded.rows
    }

    private func runBlocks(_ bin: String) async throws -> FiveHourBlock? {
        let data = try await run(bin, ["blocks", "--active", "--json", "-O"])
        let report = try JSONDecoder().decode(BlocksReport.self, from: data)
        guard let b = report.blocks.first(where: { $0.isActive }) ?? report.blocks.first else { return nil }
        guard let end = Self.parseISO(b.endTime) else { return nil }
        return FiveHourBlock(
            tokens: b.totalTokens,
            costUSD: b.costUSD,
            tokensPerMinute: b.burnRate?.tokensPerMinute ?? 0,
            endTime: end
        )
    }

    private func run(_ bin: String, _ args: [String]) async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: bin)
                proc.arguments = args
                var env = ProcessInfo.processInfo.environment
                env["FORCE_COLOR"] = "0"
                env["NO_COLOR"] = "1"
                env["PATH"] = self.resolvedPATH()   // GUI 启动只有极简 PATH，注入登录 shell PATH 让 ccusage 能找到 node
                proc.environment = env
                let out = Pipe()
                let err = Pipe()
                proc.standardOutput = out
                proc.standardError = err
                do {
                    try proc.run()
                } catch {
                    cont.resume(throwing: error)
                    return
                }
                // stderr 并发排空、stdout 当前线程排空，任一管道都不会撑满(64KB)导致子进程写阻塞死锁
                let errHandle = err.fileHandleForReading
                let errQueue = DispatchQueue(label: "ccusage.stderr")
                var errData = Data()
                errQueue.async { errData = errHandle.readDataToEndOfFile() }

                // 看门狗：ccusage 卡死时强杀，避免永久阻塞后续刷新
                let watchdog = DispatchWorkItem { if proc.isRunning { proc.terminate() } }
                DispatchQueue.global().asyncAfter(deadline: .now() + 20, execute: watchdog)

                let data = out.fileHandleForReading.readDataToEndOfFile()
                proc.waitUntilExit()
                watchdog.cancel()
                errQueue.sync {}

                if proc.terminationStatus != 0 {
                    let e = String(data: errData, encoding: .utf8) ?? ""
                    cont.resume(throwing: UsageError.commandFailed(e.isEmpty ? "退出码 \(proc.terminationStatus)" : e))
                } else {
                    cont.resume(returning: data)
                }
            }
        }
    }

    // MARK: - 活跃会话: 最近 jsonl 写入时间在阈值内

    private func detectActiveSession(threshold: TimeInterval = 120) async -> Bool {
        scanRecentActivity(threshold: threshold)
    }

    private func scanRecentActivity(threshold: TimeInterval) -> Bool {
        let projects = claudeDir.appendingPathComponent("projects")
        let fm = FileManager.default
        guard let en = fm.enumerator(
            at: projects,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return false }
        let now = Date()
        for case let url as URL in en {
            guard url.pathExtension == "jsonl" else { continue }
            if let vals = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
               let m = vals.contentModificationDate,
               now.timeIntervalSince(m) < threshold {
                return true
            }
        }
        return false
    }

    // MARK: - 二进制定位

    private func resolveBinary() throws -> String {
        if let c = cachedBinary { return c }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/.bun/bin/ccusage",
            "/opt/homebrew/bin/ccusage",
            "/usr/local/bin/ccusage",
            "\(home)/.npm-global/bin/ccusage",
        ]
        let fm = FileManager.default
        for c in candidates where fm.isExecutableFile(atPath: c) {
            cachedBinary = c
            return c
        }
        if let viaShell = whichViaLoginShell() {
            cachedBinary = viaShell
            return viaShell
        }
        throw UsageError.ccusageNotFound
    }

    private func whichViaLoginShell() -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-lc", "command -v ccusage"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do { try proc.run() } catch { return nil }
        // 超时保护：慢 .zshrc 不至于拖死定位（输出仅一行路径，无管道撑满风险）
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async { proc.waitUntilExit(); group.leave() }
        if group.wait(timeout: .now() + 5) == .timedOut {
            proc.terminate()
            return nil
        }
        guard proc.terminationStatus == 0 else { return nil }
        let path = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let path, !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }

    // MARK: - PATH（GUI 启动缺少 node 路径）

    /// 合并 登录 shell PATH + 常见 node/bun 目录 + 现有 PATH，缓存。
    private func resolvedPATH() -> String {
        if let c = cachedPath { return c }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var dirs: [String] = []
        if let p = loginShellPATH() { dirs += p.split(separator: ":").map(String.init) }
        dirs += [
            "\(home)/.bun/bin", "/opt/homebrew/bin", "/usr/local/bin",
            "\(home)/.volta/bin", "\(home)/.npm-global/bin", "/usr/bin", "/bin",
        ]
        if let cur = ProcessInfo.processInfo.environment["PATH"] {
            dirs += cur.split(separator: ":").map(String.init)
        }
        var seen = Set<String>()
        let merged = dirs.filter { !$0.isEmpty && seen.insert($0).inserted }.joined(separator: ":")
        cachedPath = merged
        return merged
    }

    private func loginShellPATH() -> String? {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: shell)
        proc.arguments = ["-lc", "printf '%s' \"$PATH\""]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do { try proc.run() } catch { return nil }
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async { proc.waitUntilExit(); group.leave() }
        if group.wait(timeout: .now() + 5) == .timedOut { proc.terminate(); return nil }
        guard proc.terminationStatus == 0 else { return nil }
        let p = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (p?.isEmpty == false) ? p : nil
    }

    // MARK: - 工具

    private static func yyyymmdd(_ d: Date) -> String { fmt("yyyyMMdd", d) }
    private static func yyyyMM(_ d: Date) -> String { fmt("yyyy-MM", d) }

    /// weekly 按 desc 排序，取最新一周；仅当它的 7 天窗口覆盖当下才算“本周”，否则本周无用量返回 nil。
    private static func currentWeek(_ rows: [UsageRow]) -> UsageRow? {
        guard let row = rows.first, let start = parseDay(row.period) else { return nil }
        let end = start.addingTimeInterval(7 * 86400)
        let now = Date()
        return (now >= start && now < end) ? row : nil
    }

    private static func parseDay(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    private static func fmt(_ pattern: String, _ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = pattern
        return f.string(from: d)
    }

    private static func parseISO(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }
}

// MARK: - ccusage JSON 解码

/// daily/weekly/monthly 共用：报表里数组 key 不同，统一抽出周期标识 + 总量。
private struct UsageReport: Decodable {
    let rows: [UsageRow]

    private enum CodingKeys: String, CodingKey {
        case daily, weekly, monthly
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let r = try c.decodeIfPresent([UsageRow].self, forKey: .daily) { rows = r }
        else if let r = try c.decodeIfPresent([UsageRow].self, forKey: .weekly) { rows = r }
        else if let r = try c.decodeIfPresent([UsageRow].self, forKey: .monthly) { rows = r }
        else { rows = [] }
    }
}

private struct UsageRow: Decodable {
    let period: String
    let totalTokens: Int
    let totalCost: Double

    private enum CodingKeys: String, CodingKey {
        case date, week, month, totalTokens, totalCost
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        period = (try? c.decode(String.self, forKey: .date))
            ?? (try? c.decode(String.self, forKey: .week))
            ?? (try? c.decode(String.self, forKey: .month))
            ?? ""
        totalTokens = (try? c.decode(Int.self, forKey: .totalTokens)) ?? 0
        totalCost = (try? c.decode(Double.self, forKey: .totalCost)) ?? 0
    }
}

private struct BlocksReport: Decodable {
    let blocks: [Block]
}

private struct Block: Decodable {
    let endTime: String
    let isActive: Bool
    let totalTokens: Int
    let costUSD: Double
    let burnRate: BurnRate?
}

private struct BurnRate: Decodable {
    let tokensPerMinute: Double
}
