import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showContent = false
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var circleScale: CGFloat = 0.8

    var body: some View {
        ZStack {
            // 温馨渐变背景
            LinearGradient(
                colors: [
                    Color(hex: "FFF5F5"),
                    Color(hex: "FFE4E9"),
                    Color(hex: "FFD1DC"),
                    Color(hex: "FFC0CB")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 装饰性圆形
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .offset(x: -80, y: -120)
                    .scaleEffect(circleScale)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: 100, y: 150)
                    .scaleEffect(circleScale)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .offset(x: -120, y: 100)
                    .scaleEffect(circleScale)
            }

            // 主要内容
            VStack(spacing: 24) {
                // 图标区域
                ZStack {
                    // 光晕效果
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    // 主图标
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(
                                color: Color(hex: "FF9999").opacity(0.3),
                                radius: 20,
                                x: 0,
                                y: 10
                            )

                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF6B6B"),
                                        Color(hex: "FF8E8E")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                }

                // 文字区域
                VStack(spacing: 12) {
                    Text("宝宝生活记录")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "333333"))
                        .opacity(textOpacity)

                    Text("用心记录，陪伴成长")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "666666"))
                        .opacity(subtitleOpacity)
                }

                // 功能图标展示
                HStack(spacing: 20) {
                    featureIcon(
                        icon: "figure.child.and.lock.fill",
                        color: Color(hex: "FF6B6B"),
                        delay: 0.3
                    )
                    featureIcon(
                        icon: "bed.double.fill",
                        color: Color(hex: "7EC8E3"),
                        delay: 0.4
                    )
                    featureIcon(
                        icon: "tshirt.fill",
                        color: Color(hex: "98D8C8"),
                        delay: 0.5
                    )
                    featureIcon(
                        icon: "heart.fill",
                        color: Color(hex: "FFB6C1"),
                        delay: 0.6
                    )
                }
                .opacity(subtitleOpacity)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    func featureIcon(icon: String, color: Color, delay: Double) -> some View {
        Image(systemName: icon)
            .font(.system(size: 20))
            .foregroundColor(color)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .shadow(
                        color: color.opacity(0.2),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .scaleEffect(showContent ? 1 : 0.5)
            .opacity(showContent ? 1 : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.6)
                .delay(delay),
                value: showContent
            )
    }

    func startAnimations() {
        // 圆形背景动画
        withAnimation(.easeOut(duration: 1.0)) {
            circleScale = 1.0
        }

        // 图标动画
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // 文字动画
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            textOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.8).delay(0.7)) {
            subtitleOpacity = 1.0
        }

        // 功能图标动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9)) {
            showContent = true
        }

        // 持续动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = true
        }
    }
}

#Preview {
    LaunchScreenView()
}
