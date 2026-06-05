import SwiftUI

struct ThemePickerView: View {
    @State private var themeManager = ThemeManager.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showProView = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("外观模式")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.outline)
                            .padding(.horizontal, 4)

                        Picker("外观模式", selection: $appTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("主题色")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.outline)
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(Array(AppColorTheme.allCases.enumerated()), id: \.element) { index, theme in
                                themeRow(theme)
                                if index < AppColorTheme.allCases.count - 1 {
                                    Divider().padding(.leading, 54)
                                }
                            }
                        }
                        .background(Color.surfaceContainerLowest)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(16)
            }
            .background(Color.background)
            .navigationTitle("主题选择")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showProView) {
                ProView()
            }
            .task {
                await subscriptionManager.checkSubscriptionStatus()
            }
        }
    }

    private func themeRow(_ theme: AppColorTheme) -> some View {
        let isSelected = themeManager.selectedColorTheme == theme
        let isLocked = theme.isProOnly && !subscriptionManager.isProUser

        return Button {
            if isLocked {
                showProView = true
            } else {
                themeManager.setTheme(theme)
            }
        } label: {
            HStack(spacing: 14) {
                LinearGradient(
                    colors: theme.previewGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 32, height: 32)
                .clipShape(Circle())

                Text(theme.rawValue)
                    .font(.system(size: 16))
                    .foregroundColor(Color.onSurface)

                if isLocked {
                    Text("PRO")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "B88746"))
                        .clipShape(Capsule())
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.primary)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.outline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemePickerView()
}
