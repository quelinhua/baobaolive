import SwiftUI

struct QuickLogCard: View {
    let icon: String
    let title: String
    let detailText: String
    let statsText: String
    let iconColor: Color
    let iconBackground: Color
    var actionTitle: String = "记录"
    var actionIcon: String = "plus"
    var isActive: Bool = false
    let onTap: () -> Void
    let onCardTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onCardTap) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                        .frame(width: 44, height: 44)
                        .background(iconBackground)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.onSurface)

                        Text(detailText)
                            .font(.system(size: 12))
                            .foregroundColor(isActive ? iconColor : Color.outline)

                        Text(statsText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.outline)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("查看\(title)详情")
            .accessibilityHint(detailText)

            Button(action: onTap) {
                HStack(spacing: 6) {
                    Image(systemName: actionIcon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(Color.onPrimary)
                .frame(minWidth: 60, minHeight: 44)
                .padding(.horizontal, 12)
                .background(isActive ? iconColor : Color.primary)
                .clipShape(Capsule())
                .shadow(color: (isActive ? iconColor : Color.primary).opacity(0.24), radius: 4, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("新增\(title)记录")
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isActive ? iconColor.opacity(0.35) : Color.surfaceVariant.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture {
            onCardTap()
        }
    }
}

#Preview {
    QuickLogCard(
        icon: RecordType.feeding.iconName,
        title: "母乳喂养",
        detailText: "上次：2h 15m 前",
        statsText: "今日 1 次 · 24小时 2 次",
        iconColor: RecordType.feeding.iconColor,
        iconBackground: RecordType.feeding.iconBackgroundColor,
        onTap: {},
        onCardTap: {}
    )
}
