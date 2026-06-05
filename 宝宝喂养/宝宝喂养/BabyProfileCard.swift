import SwiftUI

struct BabyProfileCard: View {
    let profile: BabyProfile?
    let currentDate: Date
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                BabyAvatarView(
                    imageData: profile?.avatarImageData,
                    size: 88,
                    backgroundColor: Color.white.opacity(0.25),
                    foregroundColor: .white,
                    borderColor: Color.white.opacity(0.22),
                    borderWidth: 1
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(profile?.name ?? "宝宝")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text(AchievementManager.shared.currentRank.icon)
                            .font(.system(size: 14))
                    }

                    Text(profile?.ageText(on: currentDate) ?? "未设置生日")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("健康成长中")
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(8)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .padding(28)
            .background(
                LinearGradient(
                    colors: [
                        Color.primary,
                        Color.primary.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.primary.opacity(0.3), radius: 12, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("宝宝资料")
    }
}

struct BabyProfileCard_Previews: PreviewProvider {
    static var previews: some View {
        BabyProfileCard(profile: nil, currentDate: Date(), onTap: {})
            .padding()
    }
}
