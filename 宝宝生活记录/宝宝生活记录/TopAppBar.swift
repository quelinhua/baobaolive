import SwiftUI

struct TopAppBar: View {
    let babyName: String
    let gender: String
    let onNotificationTap: () -> Void
    let onBabyTap: () -> Void
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        let timeGreeting: String
        switch hour {
        case 5..<9: timeGreeting = "早上好"
        case 9..<12: timeGreeting = "上午好"
        case 12..<14: timeGreeting = "中午好"
        case 14..<18: timeGreeting = "下午好"
        default: timeGreeting = "晚上好"
        }
        let parentTitle = gender == "男" ? "爸爸" : "妈妈"
        return "\(timeGreeting)，\(babyName)的\(parentTitle)"
    }

    var body: some View {
        HStack(alignment: .top) {
            Button(action: onBabyTap) {
                HStack(alignment: .top, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.primaryContainer)
                            .frame(width: 40, height: 40)
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 20))
                            .foregroundColor(Color.primary)
                    }

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
