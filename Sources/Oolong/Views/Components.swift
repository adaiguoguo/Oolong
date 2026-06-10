import SwiftUI

/// 圆角卡片容器
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

/// 区块标题: 图标 + 文字
struct SectionHeader: View {
    let icon: String
    let title: String
    var tint: Color = Theme.accent
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(tint).font(.system(size: 12, weight: .semibold))
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.text)
            Spacer()
        }
    }
}

/// 细进度条
struct MiniBar: View {
    var value: Double          // 0...1
    var tint: Color = Theme.accent
    var height: CGFloat = 6
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule().fill(tint)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

/// 左标签 + 右值 的一行（可带图标）
struct StatRow: View {
    var icon: String? = nil
    let label: String
    let value: String
    var valueColor: Color = Theme.text
    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 16)
                    .font(.system(size: 12))
            }
            Text(label).foregroundStyle(Theme.textSecondary).font(.system(size: 12))
            Spacer()
            Text(value).font(.system(size: 12, weight: .medium)).foregroundStyle(valueColor)
        }
    }
}

/// 药丸式分段选择器。active=false(开关关着)时不上色，仅给选中项加陶土橙描边标记预选；
/// active=true 时选中项填实心陶土橙(“亮起来”)。
struct SegmentedPills<T: Identifiable & Equatable>: View {
    let items: [T]
    let selection: T
    var active: Bool = true
    let label: (T) -> String
    let onSelect: (T) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items) { item in
                let isSel = item == selection
                Button {
                    onSelect(item)
                } label: {
                    Text(label(item))
                        .font(.system(size: 12, weight: isSel ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(fillColor(isSel))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isSel && !active ? Theme.accent.opacity(0.55) : .clear, lineWidth: 1)
                        )
                        .foregroundStyle(isSel && active ? Color.white : Theme.text)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func fillColor(_ isSel: Bool) -> Color {
        if isSel && active { return Theme.accent }          // 激活+选中：实心陶土橙
        if isSel { return Theme.accent.opacity(0.10) }      // 未激活+选中：极浅底 + 描边标记
        return Theme.text.opacity(0.05)                     // 其余：浅灰
    }
}
