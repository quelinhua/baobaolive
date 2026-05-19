import SwiftUI

struct BabyProfileCard: View {
    let profile: BabyProfile?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.primaryContainer)
                        .frame(width: 88, height: 88)

                    Image(systemName: "face.smiling.inverse")
                        .font(.system(size: 44))
                        .foregroundColor(Color.primary)
                }
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text(profile?.name ?? "宝宝")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.onPrimaryContainer)

                    Text(profile?.ageDescription ?? "未设置生日")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.onSurfaceVariant)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.tertiary)
                        Text("健康成长中")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.tertiary)
                            .textCase(.uppercase)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.tertiaryContainer.opacity(0.3))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.tertiary.opacity(0.1), lineWidth: 1))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.outline)
            }
            .padding(28)
            .background(Color.primaryContainer.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BabyProfileCard_Previews: PreviewProvider {
    static var previews: some View {
        BabyProfileCard(profile: nil, onTap: {})
            .padding()
    }
}
