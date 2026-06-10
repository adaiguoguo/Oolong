import SwiftUI

struct SystemStatusSection: View {
    @ObservedObject var model: AppModel

    private var memValue: Double {
        let t = model.stats.memoryTotalBytes
        return t > 0 ? Double(model.stats.memoryUsedBytes) / Double(t) : 0
    }

    var body: some View {
        Card {
            SectionHeader(icon: "desktopcomputer", title: I18n.t("System", "系统状态"))

            StatRow(icon: "power", label: I18n.t("Uptime", "开机时长"), value: Fmt.uptime(model.stats.uptime))

            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "cpu").foregroundStyle(Theme.textSecondary).frame(width: 16).font(.system(size: 12))
                    Text("CPU").foregroundStyle(Theme.textSecondary).font(.system(size: 12))
                    MiniBar(value: model.stats.cpuPercent / 100, tint: cpuTint)
                        .frame(width: 52)
                    Spacer()
                    Text(String(format: "%.0f%%", model.stats.cpuPercent))
                        .font(.system(size: 12, weight: .medium))
                }
            }

            HStack {
                Image(systemName: "memorychip").foregroundStyle(Theme.textSecondary).frame(width: 16).font(.system(size: 12))
                Text(I18n.t("Memory", "内存")).foregroundStyle(Theme.textSecondary).font(.system(size: 12))
                MiniBar(value: memValue, tint: Theme.accent)
                    .frame(width: 52)
                Spacer()
                Text("\(Fmt.gib(model.stats.memoryUsedBytes)) / \(Fmt.gib(model.stats.memoryTotalBytes))")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }

            if model.stats.hasBattery, let pct = model.stats.batteryPercent {
                StatRow(
                    icon: model.stats.isCharging ? "battery.100.bolt" : "battery.75",
                    label: I18n.t("Battery", "电池"),
                    value: "\(pct)%",
                    valueColor: pct <= 20 && !model.stats.isCharging ? Theme.danger : Theme.text
                )
            }
        }
    }

    private var cpuTint: Color {
        model.stats.cpuPercent > 85 ? Theme.danger : Theme.accent
    }
}
