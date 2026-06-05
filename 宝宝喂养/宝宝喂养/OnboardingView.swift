import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var page = 0
    @State private var babyName = ""
    @State private var birthDate = Date()
    @State private var gender = 0
    @State private var avatarImageData: Data?

    let genders = ["女", "男"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $page) {
                        welcomePage.tag(0)
                        setupPage.tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: page)

                    VStack(spacing: 12) {
                        if page == 0 {
                            Button(action: { withAnimation { page = 1 } }) {
                                HStack(spacing: 8) {
                                    Text("开始设置")
                                        .font(.system(size: 18, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(Color.onPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                                .shadow(color: Color.primary.opacity(0.3), radius: 8, y: 4)
                            }
                        } else {
                            Button(action: { saveProfile() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("完成设置")
                                        .font(.system(size: 18, weight: .bold))
                                }
                                .foregroundColor(Color.onPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(babyName.isEmpty ? Color.outlineVariant : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                                .shadow(color: Color.primary.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(babyName.isEmpty)
                        }

                        Button(action: { skipOnboarding() }) {
                            Text(page == 0 ? "稍后再说" : "跳过")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.outline)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("跳过") { skipOnboarding() }
                        .foregroundColor(Color.outline)
                }
            }
        }
        .interactiveDismissDisabled()
    }

    var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primary, Color.primary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.primary.opacity(0.3), radius: 15, y: 5)

            VStack(spacing: 12) {
                Text("欢迎使用宝宝记录")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color.onSurface)

                Text("用心记录，陪伴成长")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.primary)
            }

            VStack(spacing: 20) {
                featureRow(icon: "clock.fill", text: "母乳/睡眠计时，一键记录")
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "成长趋势分析，智能提醒")
                featureRow(icon: "bell.fill", text: "定时提醒，不错过每个时刻")
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.primary)
                .frame(width: 36, height: 36)
                .background(Color.primaryContainer.opacity(0.3))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.onSurface)
            Spacer()
        }
    }

    var setupPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("设置宝宝资料")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.onSurface)
                    .padding(.top, 20)

                Text("这些信息可以随时在「我的」页面修改")
                    .font(.system(size: 14))
                    .foregroundColor(Color.outline)

                VStack(spacing: 16) {
                    EditableBabyAvatarView(imageData: $avatarImageData, size: 104)
                        .padding(.bottom, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("宝宝昵称")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.onSurfaceVariant)
                        TextField("请输入宝宝昵称", text: $babyName)
                            .font(.system(size: 16, weight: .medium))
                            .padding(16)
                            .background(Color.surfaceContainerLowest)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(babyName.isEmpty ? Color.outlineVariant.opacity(0.3) : Color.primary.opacity(0.5), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("出生日期")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.onSurfaceVariant)
                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(12)
                            .background(Color.surfaceContainerLowest)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("性别")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.onSurfaceVariant)
                        HStack(spacing: 12) {
                            ForEach(0..<genders.count, id: \.self) { index in
                                Button(action: { gender = index }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: gender == index ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(gender == index ? Color.primary : Color.outline)
                                        Text(genders[index])
                                            .font(.system(size: 15, weight: gender == index ? .semibold : .regular))
                                            .foregroundColor(gender == index ? Color.primary : Color.onSurface)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(gender == index ? Color.primaryContainer.opacity(0.3) : Color.surfaceContainerLowest)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(gender == index ? Color.primary.opacity(0.5) : Color.clear, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 100)
            }
        }
    }

    func saveProfile() {
        let profile = BabyProfile(
            name: babyName.isEmpty ? "宝宝" : babyName,
            birthDate: birthDate,
            gender: genders[gender]
        )
        profile.avatarImageData = avatarImageData
        profile.isSelected = true
        modelContext.insert(profile)
        BabyManager.shared.selectBaby(profile)
        RecordWorkflow.assignUnassignedRecords(to: profile, in: modelContext)
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }

    func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

#Preview {
    OnboardingView()
}
