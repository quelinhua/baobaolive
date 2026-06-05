import SwiftUI

struct NotificationRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String
    let time: String

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(color.opacity(0.13))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Text(detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outline)
                    .lineLimit(2)
            }
            .layoutPriority(1)

            Spacer()

            if !time.isEmpty {
                Text(time)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(time == "紧急" ? Color.error : Color.outline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background((time == "紧急" ? Color.error : Color.surfaceContainerHigh).opacity(time == "紧急" ? 0.12 : 1))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.outlineVariant.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 3)
    }
}
