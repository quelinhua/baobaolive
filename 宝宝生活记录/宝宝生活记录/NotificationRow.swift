import SwiftUI

struct NotificationRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String
    let time: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
                    .lineLimit(2)
            }

            Spacer()

            Text(time)
                .font(.system(size: 11))
                .foregroundColor(time == "紧急" ? Color.error : Color.outline)
                .fontWeight(time == "紧急" ? .bold : .regular)
        }
    }
}
