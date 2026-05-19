import SwiftUI

struct QuickLogCard: View {
    let icon: String
    let title: String
    let lastTime: String
    let iconColor: Color
    let iconBackground: Color
    let onTap: () -> Void
    let onCardTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.onSurface)

                Text("上次: \(lastTime)")
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
            }

            Spacer()

            Button(action: onTap) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.onPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.primary)
                    .clipShape(Circle())
                    .shadow(color: Color.primary.opacity(0.3), radius: 4, y: 2)
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.surfaceVariant.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        .onTapGesture {
            onCardTap()
        }
    }
}

#Preview {
    QuickLogCard(
        icon: "figure.child.and.lock.fill",
        title: "母乳喂养",
        lastTime: "2h 15m 前",
        iconColor: Color.secondary,
        iconBackground: Color.secondaryContainer.opacity(0.2),
        onTap: {},
        onCardTap: {}
    )
}
