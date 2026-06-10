import SwiftUI

struct KeepAwakeSection: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Card {
            HStack {
                SectionHeader(icon: "cup.and.saucer.fill", title: I18n.t("Keep Awake", "保持唤醒"), tint: Theme.accent)
                Toggle("", isOn: Binding(
                    get: { model.keepAwakeOn },
                    set: { model.toggleKeepAwake($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
            }

            // 下面两排是开关的从属设置：关着时不上色(仅描边标记预选)，打开时选中项亮成实心陶土橙
            VStack(spacing: 8) {
                SegmentedPills(
                    items: KeepAwakeMode.allCases,
                    selection: model.keepAwakeMode,
                    active: model.keepAwakeOn,
                    label: { $0.label },
                    onSelect: { model.setKeepAwakeMode($0) }
                )

                SegmentedPills(
                    items: KeepAwakeDuration.all,
                    selection: model.keepAwakeDuration,
                    active: model.keepAwakeOn,
                    label: { $0.label },
                    onSelect: { model.setKeepAwakeDuration($0) }
                )
            }
            .animation(.easeInOut(duration: 0.15), value: model.keepAwakeOn)

            if model.keepAwakeOn, let r = model.keepAwakeRemaining {
                HStack {
                    Image(systemName: "timer").font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    Text(I18n.t("\(Fmt.countdown(r)) left", "剩 \(Fmt.countdown(r))"))
                        .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
            }

            if let note = model.keepAwakeNote {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "info.circle").font(.system(size: 10)).foregroundStyle(Theme.textSecondary)
                    Text(note).font(.system(size: 10)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
    }
}
