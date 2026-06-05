import SwiftUI

struct TopAppBar: View {
    let babyName: String
    let gender: String
    let avatarImageData: Data?
    let onNotificationTap: () -> Void
    let onBabyTap: () -> Void
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<9: return "早上好，开启宝宝元气满满的一天"
        case 9..<12: return "上午好，看看宝宝今天的状态"
        case 12..<14: return "中午好，记录宝宝的每个小变化"
        case 14..<18: return "下午好，继续守护宝宝成长"
        default: return "晚上好，回顾宝宝今天的日常"
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            Button(action: onBabyTap) {
                HStack(alignment: .top, spacing: 8) {
                    BabyAvatarView(
                        imageData: avatarImageData,
                        size: 40,
                        iconSize: 20,
                        backgroundColor: Color.primaryContainer,
                        foregroundColor: Color.primary,
                        borderColor: Color.primary.opacity(0.08),
                        borderWidth: 1
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(babyName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color.primary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.primary.opacity(0.6))
                        }

                        Text(greeting)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.outline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .allowsTightening(true)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: onNotificationTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.onSurfaceVariant)
                        .frame(width: 40, height: 40)
                        .background(Color.clear)
                        .clipShape(Circle())

                    Circle()
                        .fill(Color.error)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.surface.opacity(0.8))
        .background(.ultraThinMaterial)
        .onReceive(timer) { time in
            currentTime = time
        }
    }
}
