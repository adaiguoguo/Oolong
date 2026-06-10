import Foundation
import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var usage = ClaudeUsage()
    @Published var rateLimit: RateLimitInfo?
    @Published var stats = SystemStats()
    @Published var lastUpdated: Date?
    @Published var isRefreshing = false
    @Published var usageError: String?

    // 保持唤醒
    @Published var keepAwakeOn = false
    @Published var keepAwakeMode: KeepAwakeMode = .standard
    @Published var keepAwakeDuration: KeepAwakeDuration = .forever
    @Published var keepAwakeRemaining: TimeInterval?
    @Published var keepAwakeNote: String?

    // 开机自启
    @Published var launchAtLogin = false
    @Published var launchAtLoginError: String?

    // 语言
    @Published var language: AppLanguage = I18n.stored

    // 周期刷新间隔（秒）
    @Published var tickAge = 0

    private let usageProvider: UsageProvider
    private let rateLimitProvider = RateLimitProvider()
    private let statsService = SystemStatsService()
    private let keepAwake = KeepAwakeService()

    private var refreshTimer: Timer?
    private var uiTimer: Timer?
    private let refreshInterval: TimeInterval = 30

    init(usageProvider: UsageProvider = CCUsageProvider()) {
        self.usageProvider = usageProvider
        self.launchAtLogin = LaunchAtLogin.isEnabled
        keepAwake.onAutoStop = { [weak self] in
            self?.keepAwakeOn = false
            self?.keepAwakeRemaining = nil
        }
        keepAwake.onLidClosedAuthFailed = { [weak self] in
            // 合盖不睡授权失败/取消：回退为标准防睡眠(caffeinate 仍在挡空闲睡眠)
            self?.keepAwakeMode = .standard
            self?.keepAwakeNote = I18n.t("Lid-closed needs admin authorization; reverted to Standard.",
                                         "合盖也不睡需要管理员授权，已回退为标准防睡眠")
        }
        // 预热一次 CPU 采样（首次差值需要基线）
        _ = statsService.sample()
    }

    func start() {
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        // 每秒刷新本地状态（系统状态 + 倒计时 + “更新于N秒前”）
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickLocal() }
        }
    }

    private func tickLocal() {
        stats = statsService.sample()
        keepAwakeRemaining = keepAwake.remaining
        let rl = rateLimitProvider.read()
        if rl != rateLimit { rateLimit = rl }
        tickAge += 1
    }

    func refresh() {
        stats = statsService.sample()
        rateLimit = rateLimitProvider.read()
        guard !isRefreshing else { return }
        isRefreshing = true
        usageError = nil
        let provider = usageProvider
        Task {
            do {
                let u = try await provider.fetch()
                await MainActor.run {
                    self.usage = u
                    self.lastUpdated = Date()
                    self.isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    self.usageError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    self.isRefreshing = false
                }
            }
        }
    }

    // MARK: - 保持唤醒

    func toggleKeepAwake(_ on: Bool) {
        keepAwakeNote = nil
        keepAwakeOn = on
        if on {
            keepAwake.start(mode: keepAwakeMode, duration: keepAwakeDuration)
            keepAwakeOn = keepAwake.isActive
            keepAwakeRemaining = keepAwake.remaining
        } else {
            keepAwake.stop()
            keepAwakeRemaining = nil
        }
    }

    func setKeepAwakeMode(_ mode: KeepAwakeMode) {
        keepAwakeMode = mode
        if keepAwakeOn { toggleKeepAwake(true) }
    }

    func setKeepAwakeDuration(_ d: KeepAwakeDuration) {
        keepAwakeDuration = d
        if keepAwakeOn { toggleKeepAwake(true) }
    }

    // MARK: - 开机自启

    func toggleLaunchAtLogin(_ on: Bool) {
        launchAtLoginError = LaunchAtLogin.set(on)
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    // MARK: - 语言

    func setLanguage(_ l: AppLanguage) {
        I18n.store(l)
        language = l
    }

    func cleanup() {
        keepAwake.cleanupSync()
    }

    func quit() {
        keepAwake.cleanupSync()
        NSApplication.shared.terminate(nil)
    }
}
