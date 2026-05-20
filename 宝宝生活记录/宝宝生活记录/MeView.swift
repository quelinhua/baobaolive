import SwiftUI
import SwiftData

enum AppTheme: String, CaseIterable {
    case system = "跟随系统"
    case light = "浅色模式"
    case dark = "深色模式"

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct MeView: View {
    @Query(sort: \RecordModel.timestamp, order: .reverse) var allRecords: [RecordModel]
    @Query var babyProfiles: [BabyProfile]
    @State private var babyManager = BabyManager.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showBabyProfile = false
    @State private var showNotifications = false
    @State private var showAbout = false
    @State private var showThemePicker = false
    @State private var showEditProfile = false
    @State private var showDataExport = false
    @State private var showBabyManager = false
    @State private var showAddNewBaby = false
    @State private var showDeleteConfirm = false
    @State private var showProView = false
    @State private var showAchievement = false
    @State private var deleteIndexSet: IndexSet? = nil
    @State private var animateCards = false
    @AppStorage("appTheme") var appTheme: AppTheme = .system
    @AppStorage("feedingEnabled") var feedingEnabled = true
    @AppStorage("sleepEnabled") var sleepEnabled = true
    @AppStorage("diaperEnabled") var diaperEnabled = true
    @AppStorage("feedingIntervalHours") var feedingIntervalHours = 3
    @AppStorage("sleepIntervalHours") var sleepIntervalHours = 6
    @AppStorage("diaperIntervalHours") var diaperIntervalHours = 3

    var babyProfile: BabyProfile? { babyManager.getSelectedBaby(from: babyProfiles) }
    var babyName: String { babyProfile?.name ?? "宝宝" }

    var latestGrowthRecord: RecordModel? {
        let filtered = babyManager.filterRecords(allRecords, for: babyProfile)
        return filtered.filter { $0.recordType == .growth }.max(by: { $0.timestamp < $1.timestamp })
    }

    var todayRecords: [RecordModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let filtered = babyManager.filterRecords(allRecords, for: babyProfile)
        return filtered.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }

    var body: some View {
        VStack(spacing: 0) {
            TopAppBar(babyName: babyName, gender: babyProfile?.gender ?? "女", onNotificationTap: { showNotifications = true }, onBabyTap: { showBabyManager = true })

            ScrollView {
                VStack(spacing: 24) {
                    profileCard
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 30)
                    statsRow
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    menuSection
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showBabyProfile) { babyProfileSheet }
        .sheet(isPresented: $showEditProfile) {
            BabyProfileEditView(profile: babyProfile, isNew: false)
        }
        .sheet(isPresented: $showAddNewBaby) {
            BabyProfileEditView(profile: nil, isNew: true)
        }
        .sheet(isPresented: $showNotifications) { notificationSheet }
        .sheet(isPresented: $showThemePicker) { ThemePickerView() }
        .sheet(isPresented: $showAbout) { aboutSheet }
        .sheet(isPresented: $showDataExport) {
            DataExportView(records: allRecords, babyProfile: babyProfile)
        }
        .sheet(isPresented: $showBabyManager) {
            babyManagerSheet
        }
        .sheet(isPresented: $showProView) {
            ProView()
        }
        .sheet(isPresented: $showAchievement) {
            AchievementView()
        }
        .onAppear {
            subscriptionManager.checkSubscriptionStatus()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateCards = true
            }
        }
    }

    var profileCard: some View {
        Button(action: { showBabyProfile = true }) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 76, height: 76)
                            .shadow(color: Color.white.opacity(0.3), radius: 8, y: 2)
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 84, height: 84)
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(babyProfile?.name ?? "宝宝")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(babyProfile?.ageDescription ?? "未设置生日")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .padding(24)

                HStack(spacing: 0) {
                    profileStatItem(value: latestGrowthRecord?.weightKG.map { String(format: "%.1f", $0) } ?? "--", unit: "kg", label: "体重")
                    Divider().frame(height: 32).background(.white.opacity(0.25))
                    profileStatItem(value: latestGrowthRecord?.heightCM.map { String(format: "%.0f", $0) } ?? "--", unit: "cm", label: "身高")
                    Divider().frame(height: 32).background(.white.opacity(0.25))
                    profileStatItem(value: "\(todayRecords.count)", unit: "条", label: "今日记录")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.08))
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.primary,
                        Color.primary.opacity(0.85),
                        Color.primary.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.primary.opacity(0.4), radius: 16, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    func profileStatItem(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }

    var statsRow: some View {
        let feeding = todayRecords.filter { $0.recordType == .feeding }.count
        let sleep = todayRecords.filter { $0.recordType == .sleep }.count
        let diaper = todayRecords.filter { $0.recordType == .diaper || $0.recordType == .poop }.count

        return HStack(spacing: 12) {
            miniStatCard(icon: "figure.child.and.lock.fill", value: "\(feeding)", label: "喂奶", color: Color.primary)
            miniStatCard(icon: "bed.double.fill", value: "\(sleep)", label: "睡眠", color: Color.primary)
            miniStatCard(icon: "tshirt.fill", value: "\(diaper)", label: "尿布", color: Color.primary)
        }
    }

    func miniStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color.onSurface)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color.outline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    var menuSection: some View {
        VStack(spacing: 12) {
            if !subscriptionManager.isProUser {
                proUpgradeCard
            }
            menuCard(icon: "baby.carriage", title: "宝宝管理", subtitle: "管理宝宝资料和切换宝宝", color: Color(hex: "FF9F43"), bgColor: Color(hex: "FFF5EB"), action: { showBabyManager = true })
            menuCard(icon: "trophy.fill", title: "成就中心", subtitle: "查看已解锁成就和进度", color: Color(hex: "FFD700"), bgColor: Color(hex: "FFF8E1"), action: { showAchievement = true })
            menuCard(icon: "bell.badge.fill", title: "通知提醒", subtitle: "喂奶、睡觉、换尿布提醒", color: Color(hex: "FF6B6B"), bgColor: Color(hex: "FFE8E8"), action: { showNotifications = true })
            menuCard(icon: "paintpalette.fill", title: "主题选择", subtitle: "浅色、深色、跟随系统", color: Color(hex: "4ECDC4"), bgColor: Color(hex: "E8F8F7"), action: { showThemePicker = true })
            menuCard(icon: "doc.text.fill", title: "数据导出", subtitle: "导出CSV或JSON格式数据", color: Color(hex: "45B7D1"), bgColor: Color(hex: "E8F4F8"), isProFeature: true, action: {
                if subscriptionManager.isProUser {
                    showDataExport = true
                } else {
                    showProView = true
                }
            })
            menuCard(icon: "heart.circle.fill", title: "关于我们", subtitle: "版本信息与意见反馈", color: Color(hex: "96CEB4"), bgColor: Color(hex: "EDF7F0"), action: { showAbout = true })
        }
    }

    private var proUpgradeCard: some View {
        Button(action: { showProView = true }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(hex: "FFD700").opacity(0.3), radius: 4, y: 2)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("升级到 Pro")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.onSurface)
                    Text("解锁多宝宝、数据导出、成长图表等高级功能")
                        .font(.system(size: 12))
                        .foregroundColor(Color.outline)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "FFD700"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FFF8E1"), Color(hex: "FFFDF5")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "FFD700").opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color(hex: "FFD700").opacity(0.15), radius: 8, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    func menuCard(icon: String, title: String, subtitle: String, color: Color, bgColor: Color, darkBgColor: Color? = nil, isProFeature: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? (darkBgColor ?? color.opacity(0.15)) : bgColor)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.onSurface)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                }
                Spacer()

                if isProFeature && !subscriptionManager.isProUser {
                    Text("Pro")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "FFD700"))
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.outlineVariant)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    struct MenuItem {
        let icon: String
        let title: String
        let color: Color
        let action: () -> Void
    }

    var notificationSheet: some View {
        NavigationView {
            List {
                Section("通知开关") {
                    Toggle("喂奶提醒", isOn: $feedingEnabled)
                    Toggle("睡眠提醒", isOn: $sleepEnabled)
                    Toggle("尿布提醒", isOn: $diaperEnabled)
                }

                Section("提醒间隔") {
                    HStack {
                        Text("喂奶间隔")
                        Spacer()
                        Picker("", selection: $feedingIntervalHours) {
                            Text("2小时").tag(2)
                            Text("3小时").tag(3)
                            Text("4小时").tag(4)
                            Text("5小时").tag(5)
                        }
                        .pickerStyle(.menu)
                    }
                    HStack {
                        Text("尿布间隔")
                        Spacer()
                        Picker("", selection: $diaperIntervalHours) {
                            Text("2小时").tag(2)
                            Text("3小时").tag(3)
                            Text("4小时").tag(4)
                        }
                        .pickerStyle(.menu)
                    }
                    HStack {
                        Text("睡眠间隔")
                        Spacer()
                        Picker("", selection: $sleepIntervalHours) {
                            Text("4小时").tag(4)
                            Text("5小时").tag(5)
                            Text("6小时").tag(6)
                            Text("8小时").tag(8)
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color.outline)
                        Text("设置完成后，系统会在对应时间到达时发送本地推送通知")
                            .font(.system(size: 13))
                            .foregroundColor(Color.outline)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("通知提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showNotifications = false
                        rescheduleNotifications()
                    }
                }
            }
        }
    }

    func rescheduleNotifications() {
        let allRecs = allRecords
        let lastFeeding = allRecs.filter { $0.recordType == .feeding }.max(by: { $0.timestamp < $1.timestamp })?.timestamp
        let lastSleep = allRecs.filter { $0.recordType == .sleep }.max(by: { $0.timestamp < $1.timestamp })?.timestamp
        let lastDiaper = allRecs.filter { $0.recordType == .diaper || $0.recordType == .poop }.max(by: { $0.timestamp < $1.timestamp })?.timestamp

        NotificationManager.shared.scheduleReminders(
            feedingInterval: feedingEnabled ? feedingIntervalHours : 999,
            sleepInterval: sleepEnabled ? sleepIntervalHours : 999,
            diaperInterval: diaperEnabled ? diaperIntervalHours : 999,
            lastFeeding: lastFeeding,
            lastSleep: lastSleep,
            lastDiaper: lastDiaper
        )
    }

    var babyProfileSheet: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        let birthDateText = babyProfile.map { formatter.string(from: $0.birthDate) } ?? "未设置"

        return NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.primary, Color.primary.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.primary.opacity(0.3), radius: 10, y: 4)

                    Text(babyProfile?.name ?? "宝宝")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.onSurface)

                    VStack(spacing: 1) {
                        profileDetailRow(label: "出生日期", value: birthDateText, icon: "calendar")
                        profileDetailRow(label: "性别", value: babyProfile?.gender ?? "未设置", icon: "person")
                        profileDetailRow(label: "当前月龄", value: babyProfile?.ageDescription ?? "未设置", icon: "clock")
                        profileDetailRow(label: "最新体重", value: latestGrowthRecord?.weightKG.map { String(format: "%.1f", $0) + "kg" } ?? "暂无", icon: "scalemass")
                        profileDetailRow(label: "最新身高", value: latestGrowthRecord?.heightCM.map { String(format: "%.0f", $0) + "cm" } ?? "暂无", icon: "ruler")
                    }
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
                }
                .padding(20)
            }
            .navigationTitle("宝宝资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("编辑") {
                        showBabyProfile = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showEditProfile = true
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showBabyProfile = false }
                }
            }
        }
    }

    func profileDetailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.primary)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Color.outline)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.onSurface)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.surfaceContainerLowest)
    }

    var babyManagerSheet: some View {
        NavigationView {
            List {
                Section("当前宝宝") {
                    ForEach(babyProfiles) { baby in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(baby.persistentModelID == babyProfile?.persistentModelID ? Color.primary : Color.surfaceContainerHighest)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(baby.persistentModelID == babyProfile?.persistentModelID ? .white : Color.primary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(baby.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.onSurface)
                                Text(baby.ageDescription)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.outline)
                            }

                            Spacer()

                            if baby.persistentModelID == babyProfile?.persistentModelID {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.primary)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            babyManager.selectBaby(baby)
                        }
                    }
                    .onDelete { indexSet in
                        deleteIndexSet = indexSet
                        showDeleteConfirm = true
                    }
                }

                Section {
                    Button(action: {
                        if subscriptionManager.isProUser || babyProfiles.isEmpty {
                            showBabyManager = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showAddNewBaby = true
                            }
                        } else {
                            showBabyManager = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showProView = true
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.primary)
                            Text("添加新宝宝")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.primary)

                            if !subscriptionManager.isProUser && !babyProfiles.isEmpty {
                                Spacer()
                                Text("Pro")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "FFD700"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color.outline)
                        Text("左滑可删除宝宝，删除后该宝宝的所有记录也会被删除")
                            .font(.system(size: 13))
                            .foregroundColor(Color.outline)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("宝宝管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showBabyManager = false }
                }
            }
            .alert("确认删除", isPresented: $showDeleteConfirm) {
                Button("取消", role: .cancel) {
                    deleteIndexSet = nil
                }
                Button("删除", role: .destructive) {
                    if let indexSet = deleteIndexSet {
                        performDelete(at: indexSet)
                    }
                    deleteIndexSet = nil
                }
            } message: {
                Text("删除后该宝宝的所有记录也将被删除，此操作不可恢复。")
            }
        }
    }

    func performDelete(at offsets: IndexSet) {
        for index in offsets {
            let baby = babyProfiles[index]
            if baby.persistentModelID == babyProfile?.persistentModelID {
                let remaining = babyProfiles.filter { $0.persistentModelID != baby.persistentModelID }
                if let first = remaining.first {
                    babyManager.selectBaby(first)
                }
            }
            modelContext.delete(baby)
        }
        try? modelContext.save()
    }

    @Environment(\.modelContext) private var modelContext

    var aboutSheet: some View {
        NavigationView {
            VStack(spacing: 28) {
                Spacer().frame(height: 20)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.primary, Color.primary.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                    Image(systemName: "face.smiling.inverse")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.primary.opacity(0.3), radius: 10, y: 4)

                VStack(spacing: 6) {
                    Text("宝宝生活记录")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.onSurface)
                    Text("版本 1.0.0")
                        .font(.system(size: 14))
                        .foregroundColor(Color.outline)
                }

                VStack(spacing: 1) {
                    aboutRow(icon: "person.fill", title: "开发者", value: "宝宝生活团队")
                    aboutRow(icon: "envelope.fill", title: "联系邮箱", value: "support@baobaolive.com")
                    aboutRow(icon: "globe", title: "官方网站", value: "www.baobaolive.com")
                }
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)

                #if DEBUG
                VStack(spacing: 1) {
                    Toggle(isOn: $subscriptionManager.isProUser) {
                        HStack(spacing: 12) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                                .frame(width: 28)
                            Text("DEBUG: Pro 模式")
                                .font(.system(size: 15))
                                .foregroundColor(Color.onSurface)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.surfaceContainerLowest)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
                #endif

                Spacer()

                Text("用心记录，陪伴成长")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.primary)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .navigationTitle("关于我们")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showAbout = false }
                }
            }
        }
    }

    func aboutRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.primary)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Color.outline)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.onSurface)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.surfaceContainerLowest)
    }
}

#Preview {
    MeView()
}
