import Foundation

/// 防睡眠：
/// - 标准防睡眠: caffeinate -di（阻止显示器 + 空闲睡眠）
/// - 合盖也不睡: 在上面基础上，用管理员权限 `pmset -a disablesleep 1` 阻止合盖强制睡眠，
///   关闭/到期/退出时恢复 0。caffeinate 的 -s 在 Apple Silicon 上挡不住合盖，故改用 pmset。
final class KeepAwakeService {
    private var process: Process?
    private var sleepDisabled = false           // 是否已 pmset disablesleep 1
    private(set) var isActive = false
    private(set) var mode: KeepAwakeMode = .standard
    private(set) var expiresAt: Date?

    var onAutoStop: (() -> Void)?
    var onLidClosedAuthFailed: (() -> Void)?

    func start(mode: KeepAwakeMode, duration: KeepAwakeDuration) {
        killCaffeinate()

        // -di: 显示器+空闲睡眠；-w 自身 pid: app 被强杀时 caffeinate 跟随退出，不留孤儿
        var args = ["-di", "-w", "\(ProcessInfo.processInfo.processIdentifier)"]
        if let secs = duration.seconds {
            args += ["-t", "\(secs)"]
            expiresAt = Date().addingTimeInterval(TimeInterval(secs))
        } else {
            expiresAt = nil
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        proc.arguments = args
        proc.terminationHandler = { [weak self] terminated in
            DispatchQueue.main.async {
                // 仅当结束的正是当前进程才算自动到期；陈旧 handler 直接忽略
                guard let self, self.process === terminated else { return }
                self.process = nil
                self.isActive = false
                self.expiresAt = nil
                self.applyDisableSleep(false)    // 到期同时恢复合盖睡眠
                self.onAutoStop?()
            }
        }
        do {
            try proc.run()
            self.process = proc
            self.isActive = true
            self.mode = mode
        } catch {
            self.isActive = false
            self.expiresAt = nil
            return
        }

        // 合盖不睡：仅当需求变化时才提权，避免改时长重复弹密码
        applyDisableSleep(mode == .lidClosed)
    }

    func stop() {
        killCaffeinate()
        isActive = false
        expiresAt = nil
        applyDisableSleep(false)
    }

    /// 退出前同步清理，避免残留“系统不睡”
    func cleanupSync() {
        killCaffeinate()
        if sleepDisabled {
            _ = Self.runDisableSleep(false)
            sleepDisabled = false
        }
    }

    var remaining: TimeInterval? {
        guard let e = expiresAt else { return nil }
        return max(0, e.timeIntervalSinceNow)
    }

    // MARK: - 内部

    private func killCaffeinate() {
        if let p = process {
            process = nil
            p.terminationHandler = nil
            if p.isRunning { p.terminate() }
        }
    }

    /// 只在状态变化时提权切 pmset，异步执行避免授权弹窗阻塞主线程
    private func applyDisableSleep(_ want: Bool) {
        guard want != sleepDisabled else { return }
        DispatchQueue.global().async { [weak self] in
            let ok = Self.runDisableSleep(want)
            DispatchQueue.main.async {
                guard let self else { return }
                if ok {
                    self.sleepDisabled = want
                } else if want {
                    self.onLidClosedAuthFailed?()   // 授权失败/取消
                }
            }
        }
    }

    /// 管理员权限执行 pmset disablesleep。osascript 触发系统授权弹窗(支持 Touch ID)。
    private static func runDisableSleep(_ on: Bool) -> Bool {
        let script = "do shell script \"/usr/bin/pmset -a disablesleep \(on ? "1" : "0")\" with administrator privileges"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        proc.standardError = Pipe()
        proc.standardOutput = Pipe()
        do {
            try proc.run()
            proc.waitUntilExit()
            return proc.terminationStatus == 0
        } catch {
            return false
        }
    }
}
