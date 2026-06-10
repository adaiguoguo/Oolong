import SwiftUI
import AppKit

struct MenuContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView(.vertical) {
            content
        }
        .frame(width: 320)
        .frame(maxHeight: Self.maxPanelHeight)   // 按当前屏可用高度封顶，小屏超出则面板内滚动
        .background(Theme.bg)
        .tint(Theme.accent)
        .foregroundStyle(Theme.text)
    }

    /// 屏幕可用高度(已扣菜单栏/Dock) 减边距，保证小屏 MacBook 也不被裁
    private static var maxPanelHeight: CGFloat {
        let h = NSScreen.main?.visibleFrame.height
            ?? NSScreen.screens.first?.visibleFrame.height
            ?? 760
        return max(360, h - 24)
    }

    private func langTitle(_ l: AppLanguage, _ name: String) -> String {
        (model.language == l ? "✓ " : "    ") + name
    }

    private var settingsMenu: some View {
        Menu {
            Section(I18n.t("Language", "语言")) {
                Button(langTitle(.system, I18n.t("System", "跟随系统"))) { model.setLanguage(.system) }
                Button(langTitle(.en, "English")) { model.setLanguage(.en) }
                Button(langTitle(.zh, "中文")) { model.setLanguage(.zh) }
            }
        } label: {
            Image(systemName: "gearshape").font(.system(size: 12))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var content: some View {
        VStack(spacing: 10) {
            KeepAwakeSection(model: model)
            SystemStatusSection(model: model)
            ClaudeUsageSection(model: model)

            // 开机自启
            VStack(spacing: 4) {
                HStack {
                    Text(I18n.t("Launch at login", "开机自启")).font(.system(size: 12))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { model.launchAtLogin },
                        set: { model.toggleLaunchAtLogin($0) }
                    ))
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
                }
                if let err = model.launchAtLoginError {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow).font(.system(size: 10))
                        Text(I18n.t("Failed: \(err) (needs signing + /Applications)",
                                    "设置失败：\(err)（需已签名且放入 /Applications）"))
                            .font(.system(size: 10)).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 4)

            Divider().opacity(0.4)

            // 底部操作栏
            HStack(spacing: 12) {
                Button {
                    model.refresh()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text(I18n.t("Refresh", "刷新"))
                    }.font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .disabled(model.isRefreshing)

                Text(model.isRefreshing ? I18n.t("Refreshing…", "刷新中…") : Fmt.relativeAge(model.lastUpdated))
                    .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)

                Spacer()

                settingsMenu

                Button {
                    model.quit()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                        Text(I18n.t("Quit", "退出"))
                    }.font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .frame(width: 320)
    }
}
