import SwiftUI

struct ClaudeUsageSection: View {
    @ObservedObject var model: AppModel

    private let windowSeconds: TimeInterval = 5 * 3600

    private func pct(_ p: Int) -> String { I18n.t("\(p)% used", "已用 \(p)%") }
    private func resetsIn(_ s: String) -> String { I18n.t("resets in \(s)", "距重置 \(s)") }

    var body: some View {
        Card {
            SectionHeader(icon: "sparkles", title: "Claude Code", tint: Theme.accent)

            if let err = model.usageError {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                    Text(err).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // 今日
            HStack(alignment: .firstTextBaseline) {
                Text(I18n.t("Today", "今日")).foregroundStyle(Theme.textSecondary).font(.system(size: 12))
                Text(Fmt.tokens(model.usage.today.tokens))
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(Fmt.cost(model.usage.today.costUSD))
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary)
            }

            // 5h 窗口：优先官方限流数据(与 /usage 一致)，无则回退 ccusage 时间重建
            if let rl = model.rateLimit?.fiveHour {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "clock").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                        Text(I18n.t("5h window", "5h 窗口")).foregroundStyle(Theme.textSecondary).font(.system(size: 12))
                        Spacer()
                        Text(pct(rl.usedPercentage)).font(.system(size: 13, weight: .semibold))
                    }
                    MiniBar(value: Double(rl.usedPercentage) / 100, tint: quotaTint(rl.usedPercentage))
                    HStack {
                        if let b = model.usage.fiveHour {
                            Text("\(Fmt.tokens(b.tokens)) · \(Fmt.burnRate(b.tokensPerMinute))")
                                .font(.system(size: 10)).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text(resetsIn(Fmt.countdown(rl.remaining)))
                            .font(.system(size: 10)).foregroundStyle(Theme.textSecondary)
                    }
                }
                // 7d 窗口：与 5h 同款并排整条
                if let seven = model.rateLimit?.sevenDay {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "calendar").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                            Text(I18n.t("7d window", "7d 窗口")).foregroundStyle(Theme.textSecondary).font(.system(size: 12))
                            Spacer()
                            Text(pct(seven.usedPercentage)).font(.system(size: 13, weight: .semibold))
                        }
                        MiniBar(value: Double(seven.usedPercentage) / 100, tint: quotaTint(seven.usedPercentage))
                        HStack {
                            Spacer()
                            Text(resetsIn(Fmt.shortDuration(seven.remaining)))
                                .font(.system(size: 10)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                if model.rateLimit?.isStale == true {
                    Text(I18n.t("from last active session", "数据来自上次活跃会话"))
                        .font(.system(size: 9)).foregroundStyle(.tertiary)
                }
            } else if let b = model.usage.fiveHour {
                // 回退：无官方限流数据(未配 statusline / 无活跃会话)，显示 ccusage 重建的时间窗口
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "clock").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    Text(I18n.t("5h window", "5h 窗口")).foregroundStyle(Theme.textSecondary).font(.system(size: 12))
                    Text(Fmt.tokens(b.tokens)).font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text(Fmt.burnRate(b.tokensPerMinute))
                        .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                }
                VStack(spacing: 3) {
                    MiniBar(value: b.remaining / windowSeconds, tint: Theme.accent.opacity(0.5))
                    HStack {
                        Text(I18n.t("resets in", "距重置")).font(.system(size: 10)).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(Fmt.countdown(b.remaining))
                            .font(.system(size: 10)).foregroundStyle(Theme.textSecondary)
                    }
                }
                Text(I18n.t("Reconstructed from local logs (not official quota). Set up status line for official %.",
                            "本地日志重建(非官方配额)；配 statusline 后显示官方%"))
                    .font(.system(size: 9)).foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().opacity(0.4)

            // 本周 / 本月
            HStack(alignment: .top, spacing: 0) {
                periodColumn(title: I18n.t("Week", "本周"), tc: model.usage.week)
                periodColumn(title: I18n.t("Month", "本月"), tc: model.usage.month)
            }

            Divider().opacity(0.4)

            HStack(spacing: 5) {
                Circle()
                    .fill(model.usage.hasActiveSession ? Theme.accent : Theme.textSecondary.opacity(0.4))
                    .frame(width: 7, height: 7)
                Text(model.usage.hasActiveSession ? I18n.t("Active session", "有活跃会话") : I18n.t("No active session", "无活跃会话"))
                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                Spacer()
            }
        }
    }

    private func quotaTint(_ percent: Int) -> Color {
        percent >= 85 ? Theme.danger : Theme.accent
    }

    private func periodColumn(title: String, tc: TokenCost) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Fmt.tokens(tc.tokens)).font(.system(size: 14, weight: .semibold))
                Text(Fmt.cost(tc.costUSD)).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
