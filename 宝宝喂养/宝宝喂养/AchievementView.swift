import SwiftUI

struct AchievementView: View {
    @State private var achievementManager = AchievementManager.shared
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showUnlockAnimation = false
    @State private var animateContent = false
    @Environment(\.dismiss) var dismiss

    var filteredAchievements: [AchievementDef] {
        achievementManager.achievements(for: selectedCategory)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    statsHeader
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    categoryFilter
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 15)

                    achievementGrid
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(Color.background)
            .navigationTitle("成就中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(Color.primary)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateContent = true
            }
        }
    }

    var statsHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: achievementManager.completionPercentage)
                    .stroke(
                        AngularGradient(
                            colors: [Color.primary, Color(hex: "FFD700"), Color.primary],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(achievementManager.unlockedCount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.onSurface)
                    Text("/ \(achievementManager.totalCount)")
                        .font(.system(size: 14))
                        .foregroundColor(Color.outline)
                }
            }

            Text("已解锁 \(Int(achievementManager.completionPercentage * 100))%")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.outline)

            if !achievementManager.recentUnlocked().isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近解锁")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.outline)

                    HStack(spacing: 12) {
                        ForEach(achievementManager.recentUnlocked(count: 5)) { achievement in
                            recentBadge(achievement)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
    }

    func recentBadge(_ achievement: AchievementDef) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: achievement.level.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: achievement.level.color.opacity(0.3), radius: 4, y: 2)

                Image(systemName: achievement.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                categoryButton(nil, label: "全部", icon: "square.grid.2x2.fill")
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    categoryButton(category, label: category.displayName, icon: category.icon)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    func categoryButton(_ category: AchievementCategory?, label: String, icon: String) -> some View {
        let isSelected = selectedCategory == category
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .white : Color.onSurface)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primary : Color.surfaceContainerHighest)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    var achievementGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filteredAchievements) { achievement in
                AchievementCard(
                    achievement: achievement,
                    progress: achievementManager.getProgress(for: achievement.id),
                    isUnlocked: achievementManager.isUnlocked(achievement.id),
                    unlockedDate: achievementManager.getUnlockedDate(achievement.id)
                )
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: AchievementDef
    let progress: Int
    let isUnlocked: Bool
    let unlockedDate: Date?

    @State private var isPressed = false

    var progressPercent: Double {
        guard achievement.requirement > 0 else { return 0 }
        return min(Double(progress) / Double(achievement.requirement), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                        ? LinearGradient(
                            colors: achievement.level.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.surfaceContainerHighest, Color.surfaceContainerHighest],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(
                        color: isUnlocked ? achievement.level.color.opacity(0.3) : Color.clear,
                        radius: 8,
                        y: 2
                    )

                Image(systemName: achievement.icon)
                    .font(.system(size: 26))
                    .foregroundColor(isUnlocked ? .white : Color.outlineVariant)

                if !isUnlocked {
                    Circle()
                        .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 3)
                        .frame(width: 64, height: 64)

                    Circle()
                        .trim(from: 0, to: progressPercent)
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                }
            }

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(achievement.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isUnlocked ? Color.onSurface : Color.outline)
                        .lineLimit(1)

                    Text(achievement.level.displayName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(achievement.level.color)
                        .clipShape(Capsule())
                }

                Text(achievement.desc)
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
                    .lineLimit(1)
            }

            if isUnlocked {
                if let date = unlockedDate {
                    Text(formatDate(date))
                        .font(.system(size: 10))
                        .foregroundColor(Color.outlineVariant)
                }
            } else {
                HStack(spacing: 4) {
                    Text("\(progress)/\(achievement.requirement)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.primary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isUnlocked ? achievement.level.color.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(isUnlocked ? 0.05 : 0.02), radius: 6, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

struct AchievementUnlockView: View {
    let achievement: AchievementDef
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showGlow = false
    @State private var particles: [ParticleData] = []

    struct ParticleData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Text("恭喜解锁！")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.onSurface)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -20)

                    ZStack {
                        ForEach(particles) { particle in
                            Circle()
                                .fill(achievement.level.color.opacity(particle.opacity))
                                .frame(width: 6, height: 6)
                                .scaleEffect(particle.scale)
                                .offset(x: particle.x, y: particle.y)
                        }

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        achievement.level.color.opacity(showGlow ? 0.4 : 0),
                                        achievement.level.color.opacity(0)
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: achievement.level.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: achievement.level.color.opacity(0.5), radius: 20, y: 4)

                            Image(systemName: achievement.icon)
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(showContent ? 1 : 0.3)
                    }
                    .frame(height: 160)

                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Text(achievement.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color.onSurface)

                            Text(achievement.level.displayName)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(achievement.level.color)
                                .clipShape(Capsule())
                        }

                        Text(achievement.desc)
                            .font(.system(size: 15))
                            .foregroundColor(Color.outline)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    Button(action: onDismiss) {
                        Text("太棒了！")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: achievement.level.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.surfaceContainerLowest)
                        .shadow(color: Color.black.opacity(0.15), radius: 30, y: 10)
                )
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear {
            generateParticles()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) {
                showContent = true
            }

            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                showGlow = true
            }
        }
    }

    func generateParticles() {
        particles = (0..<12).map { i in
            let angle = Double(i) * .pi * 2 / 12
            let radius: CGFloat = CGFloat.random(in: 60...90)
            return ParticleData(
                x: cos(angle) * radius,
                y: sin(angle) * radius,
                scale: CGFloat.random(in: 0.5...1.2),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }
}

#Preview {
    AchievementView()
}
