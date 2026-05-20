import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \RecordModel.timestamp, order: .reverse) var allRecords: [RecordModel]
    @Query var babyProfiles: [BabyProfile]
    @State private var babyManager = BabyManager.shared
    @State private var selectedTab = 0
    @State private var showRecordDetail = false
    @State private var selectedRecordType: RecordType = .feeding
    @State private var addRecordType: RecordType? = nil
    @State private var showNotifications = false
    @State private var showBabyProfile = false
    @State private var showBabySwitcher = false
    @State private var showFeedingTimer = false
    @State private var showSleepTimer = false
    @State private var showOnboarding = false
    @State private var showCategoriesManage = false
    @State private var showLaunchScreen = true
    @State private var now = Date()
    @State private var achievementManager = AchievementManager.shared
    @AppStorage("homePageCategories") var homePageCategoriesData: Data = {
        try! JSONEncoder().encode(RecordType.defaultHomePage)
    }()
    @AppStorage("feedingIntervalHours") var feedingIntervalHours = 3
    @AppStorage("sleepIntervalHours") var sleepIntervalHours = 6
    @AppStorage("diaperIntervalHours") var diaperIntervalHours = 3
    @AppStorage("appTheme") var appTheme: AppTheme = .system
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var babyProfile: BabyProfile? { babyManager.getSelectedBaby(from: babyProfiles) }
    var babyName: String { babyProfile?.name ?? "宝宝" }

    var homePageCategories: [String] {
        (try? JSONDecoder().decode([String].self, from: homePageCategoriesData)) ?? RecordType.defaultHomePage
    }

    func setHomePageCategories(_ categories: [String]) {
        homePageCategoriesData = (try? JSONEncoder().encode(categories)) ?? Data()
    }

    var todayRecords: [RecordModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let filtered = babyManager.filterRecords(allRecords, for: babyProfile)
        return filtered.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }

    var todayFeedingCount: Int { todayRecords.filter { $0.recordType == .feeding }.count }
    var todaySleepCount: Int { todayRecords.filter { $0.recordType == .sleep }.count }
    var todayDiaperCount: Int { todayRecords.filter { $0.recordType == .diaper || $0.recordType == .poop }.count }

    func lastRecordTime(for type: RecordType) -> Date? {
        let filtered = babyManager.filterRecords(allRecords, for: babyProfile)
        return filtered.filter { $0.recordType == type }.max(by: { $0.timestamp < $1.timestamp })?.timestamp
    }

    func lastTimeText(for type: RecordType) -> String {
        guard let lastTime = lastRecordTime(for: type) else { return "暂无记录" }
        let interval = now.timeIntervalSince(lastTime)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return minutes > 0 ? "\(hours)h \(minutes)m 前" : "\(hours)h 前"
        }
        let days = Int(interval / 86400)
        return "\(days)天前"
    }

    func isOverdue(for type: RecordType) -> Bool {
        guard let lastTime = lastRecordTime(for: type) else { return false }
        let interval = now.timeIntervalSince(lastTime)
        switch type {
        case .feeding: return interval > Double(feedingIntervalHours) * 3600
        case .diaper: return interval > Double(diaperIntervalHours) * 3600
        case .sleep: return interval > Double(sleepIntervalHours) * 3600
        default: return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if selectedTab == 0 {
                homePage
            } else if selectedTab == 1 {
                RecordListView()
            } else {
                MeView()
            }

            BottomNavBar(selectedTab: $selectedTab)
        }
        .background(Color.background)
        .sheet(item: $addRecordType) { type in
            AddRecordView(recordType: type)
        }
        .sheet(isPresented: $showRecordDetail) {
            RecordDetailView(recordType: selectedRecordType)
        }
        .sheet(isPresented: $showNotifications) {
            notificationSheet
        }
        .sheet(isPresented: $showBabyProfile) {
            babyProfileSheet
        }
        .sheet(isPresented: $showBabySwitcher) {
            babySwitcherSheet
        }
        .sheet(isPresented: $showFeedingTimer) {
            FeedingTimerView()
        }
        .sheet(isPresented: $showSleepTimer) {
            SleepTimerView()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showCategoriesManage) {
            CategoriesManageView(homePageCategories: Binding(
                get: { homePageCategories },
                set: { setHomePageCategories($0) }
            ))
        }
        .sheet(isPresented: $showAddBaby) {
            BabyProfileEditView(profile: nil, isNew: true)
        }
        .preferredColorScheme(appTheme == .system ? nil : (appTheme == .light ? .light : .dark))
        .onReceive(refreshTimer) { time in
            now = time
        }
        .onAppear {
            if !hasCompletedOnboarding && babyProfiles.isEmpty {
                showOnboarding = true
            }
            scheduleNotificationsIfNeeded()
        }
        .overlay {
            if let achievement = achievementManager.newlyUnlocked {
                AchievementUnlockView(achievement: achievement) {
                    achievementManager.dismissNewlyUnlocked()
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }

    var homePage: some View {
        VStack(spacing: 0) {
            TopAppBar(
                babyName: babyName,
                gender: babyProfile?.gender ?? "女",
                onNotificationTap: { showNotifications = true },
                onBabyTap: { showBabySwitcher = true }
            )

            ScrollView {
                VStack(spacing: 24) {
                    if !hasCompletedOnboarding && babyProfiles.isEmpty {
                        onboardingBanner
                    }

                    BabyProfileCard(profile: babyProfile, onTap: { showBabyProfile = true })

                    todaySummaryCard

                    VStack(spacing: 16) {
                        HStack {
                            Text("快捷记录")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color.onSurface)

                            Spacer()

                            Button("查看全部") {
                                showCategoriesManage = true
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.primary)
                        }

                        VStack(spacing: 8) {
                            ForEach(homePageCategories.compactMap { RecordType(rawValue: $0) }) { type in
                                quickLogCard(for: type)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }

            Spacer()
        }
    }

    var onboardingBanner: some View {
        Button(action: { showOnboarding = true }) {
            HStack(spacing: 12) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("欢迎使用宝宝生活记录")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.onSurface)
                    Text("点击这里先设置宝宝资料")
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.outlineVariant)
            }
            .padding(16)
            .background(Color.primaryContainer.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    var todaySummaryCard: some View {
        Button(action: { selectedTab = 1 }) {
            HStack(spacing: 0) {
                summaryItem(icon: "figure.child.and.lock.fill", value: "\(todayFeedingCount)", unit: "次喂奶", color: Color.secondary)
                Divider().frame(height: 40)
                summaryItem(icon: "bed.double.fill", value: "\(todaySleepCount)", unit: "次睡眠", color: Color.primaryDim)
                Divider().frame(height: 40)
                summaryItem(icon: "tshirt.fill", value: "\(todayDiaperCount)", unit: "次尿布", color: Color.onSurfaceVariant)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.outlineVariant.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    func summaryItem(icon: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.onSurface)
            Text(unit)
                .font(.system(size: 11))
                .foregroundColor(Color.outline)
        }
        .frame(maxWidth: .infinity)
    }

    var notificationSheet: some View {
        let yesterdayRecords: [RecordModel] = {
            let calendar = Calendar.current
            let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
            return allRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: yesterday) }
        }()

        return NavigationView {
            VStack(spacing: 0) {
                List {
                    Section("今日提醒") {
                        if isOverdue(for: .feeding) {
                            NotificationRow(icon: "clock.fill", color: Color.error, title: "喂奶提醒", detail: "距离上次喂奶已超过\(feedingIntervalHours)小时", time: "紧急")
                        }
                        if isOverdue(for: .sleep) {
                            NotificationRow(icon: "moon.zzz.fill", color: Color.error, title: "睡眠提醒", detail: "宝宝已清醒较久，建议准备入睡", time: "紧急")
                        }
                        if isOverdue(for: .diaper) {
                            NotificationRow(icon: "tshirt.fill", color: Color.error, title: "尿布提醒", detail: "距离上次更换尿布已超过\(diaperIntervalHours)小时", time: "紧急")
                        }
                        if !isOverdue(for: .feeding) && !isOverdue(for: .sleep) && !isOverdue(for: .diaper) {
                            NotificationRow(icon: "checkmark.circle.fill", color: Color.tertiary, title: "一切正常", detail: "当前没有需要关注的提醒", time: "现在")
                        }
                    }

                    Section("状态概览") {
                        NotificationRow(icon: "clock.fill", color: Color.primary, title: "喂奶", detail: "距离上次：\(lastTimeText(for: .feeding))", time: "")
                        NotificationRow(icon: "moon.zzz.fill", color: Color.primaryDim, title: "睡眠", detail: "距离上次：\(lastTimeText(for: .sleep))", time: "")
                        NotificationRow(icon: "tshirt.fill", color: Color.onSurfaceVariant, title: "尿布", detail: "距离上次：\(lastTimeText(for: .diaper))", time: "")
                    }

                    Section("昨日总结") {
                        let yf = yesterdayRecords.filter { $0.recordType == .feeding }.count
                        let ys = yesterdayRecords.filter { $0.recordType == .sleep }.count
                        let yd = yesterdayRecords.filter { $0.recordType == .diaper }.count
                        NotificationRow(icon: "chart.bar.fill", color: Color.tertiary, title: "昨日数据", detail: "喂奶\(yf)次 睡眠\(ys)次 尿布\(yd)次", time: "昨天")
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showNotifications = false }
                }
            }
        }
    }

    var babyProfileSheet: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        let birthDateText = babyProfile.map { formatter.string(from: $0.birthDate) } ?? "未设置"

        var latestGrowthRecord: RecordModel? {
            allRecords.filter { $0.recordType == .growth }.max(by: { $0.timestamp < $1.timestamp })
        }

        return NavigationView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.primaryContainer)
                        .frame(width: 100, height: 100)
                    Image(systemName: "face.smiling.inverse")
                        .font(.system(size: 50))
                        .foregroundColor(Color.primary)
                }

                Text(babyProfile?.name ?? "宝宝")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.onSurface)

                VStack(spacing: 16) {
                    profileRow(label: "出生日期", value: birthDateText)
                    profileRow(label: "性别", value: babyProfile?.gender ?? "未设置")
                    profileRow(label: "当前月龄", value: babyProfile?.ageDescription ?? "未设置")
                    profileRow(label: "最新体重", value: latestGrowthRecord?.weightKG.map { String(format: "%.1f", $0) + "kg" } ?? "暂无")
                    profileRow(label: "最新身高", value: latestGrowthRecord?.heightCM.map { String(format: "%.1f", $0) + "cm" } ?? "暂无")
                }
                .padding(20)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()
            }
            .padding(20)
            .navigationTitle("宝宝资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showBabyProfile = false }
                }
            }
        }
    }

    func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Color.outline)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.onSurface)
        }
    }

    var babySwitcherSheet: some View {
        NavigationView {
            List {
                Section("选择宝宝") {
                    ForEach(babyProfiles) { baby in
                        Button(action: {
                            babyManager.selectBaby(baby)
                            showBabySwitcher = false
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(baby.persistentModelID == babyProfile?.persistentModelID ? Color.primary : Color.surfaceContainerHighest)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "face.smiling.inverse")
                                        .font(.system(size: 22))
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
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Section {
                    Button(action: {
                        showBabySwitcher = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAddBaby = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.primary)
                            Text("添加新宝宝")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.primary)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("切换宝宝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showBabySwitcher = false }
                }
            }
        }
    }

    @State private var showAddBaby = false

    @ViewBuilder
    func quickLogCard(for type: RecordType) -> some View {
        let iconColor: Color = {
            if isOverdue(for: type) { return Color.error }
            return type.iconColor
        }()
        let bgColor: Color = {
            if isOverdue(for: type) { return Color.error.opacity(0.15) }
            return type.iconBackgroundColor
        }()

        QuickLogCard(
            icon: type.iconName,
            title: type.displayName,
            lastTime: lastTimeText(for: type),
            iconColor: iconColor,
            iconBackground: bgColor,
            onTap: {
                switch type {
                case .feeding: showFeedingTimer = true
                case .sleep: showSleepTimer = true
                default: addRecordType = type
                }
            },
            onCardTap: {
                selectedRecordType = type
                showRecordDetail = true
            }
        )
    }

    func scheduleNotificationsIfNeeded() {
        let lastFeeding = lastRecordTime(for: .feeding)
        let lastSleep = lastRecordTime(for: .sleep)
        let lastDiaper = lastRecordTime(for: .diaper)

        NotificationManager.shared.scheduleReminders(
            feedingInterval: feedingIntervalHours,
            sleepInterval: sleepIntervalHours,
            diaperInterval: diaperIntervalHours,
            lastFeeding: lastFeeding,
            lastSleep: lastSleep,
            lastDiaper: lastDiaper
        )
    }
}

#Preview {
    ContentView()
}
