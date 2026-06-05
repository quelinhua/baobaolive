import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \RecordModel.timestamp, order: .reverse) var allRecords: [RecordModel]
    @Query var babyProfiles: [BabyProfile]
    @State private var babyManager = BabyManager.shared
    @State private var selectedTab = 0
    @State private var selectedRecordType: RecordType? = nil
    @State private var addRecordType: RecordType? = nil
    @State private var showNotifications = false
    @State private var showBabyProfile = false
    @State private var showEditProfile = false
    @State private var showBabySwitcher = false
    @State private var showFeedingTimer = false
    @State private var showSleepTimer = false
    @State private var showOnboarding = false
    @State private var showCategoriesManage = false
    @State private var now = Date()
    @State private var achievementManager = AchievementManager.shared
    @State private var timerManager = TimerManager.shared
    @State private var familySharingManager = FamilySharingManager.shared
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

    var latestGrowthRecord: RecordModel? {
        babyManager.filterRecords(allRecords, for: babyProfile)
            .filter { $0.recordType == .growth }
            .max(by: { $0.timestamp < $1.timestamp })
    }

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
    var todayFormulaCount: Int { todayRecords.filter { $0.recordType == .formula }.count }
    var todayDiaperCount: Int { todayRecords.filter { $0.recordType == .diaper || $0.recordType == .poop }.count }

    func lastRecordTime(for type: RecordType) -> Date? {
        let filtered = babyManager.filterRecords(allRecords, for: babyProfile)
        if type == .feeding {
            return filtered.filter { $0.recordType == .feeding || $0.recordType == .formula }.max(by: { $0.timestamp < $1.timestamp })?.timestamp
        }
        if type == .diaper {
            return filtered.filter { $0.recordType == .diaper || $0.recordType == .poop }.max(by: { $0.timestamp < $1.timestamp })?.timestamp
        }
        guard let record = filtered.filter({ $0.recordType == type }).max(by: { $0.timestamp < $1.timestamp }) else { return nil }
        if type == .sleep, let wakeTime = record.sleepEndTime {
            return wakeTime
        }
        return record.timestamp
    }

    func lastTimeText(for type: RecordType) -> String {
        guard let lastTime = lastRecordTime(for: type) else { return "暂无近期记录" }
        let interval = now.timeIntervalSince(lastTime)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return minutes > 0 ? "\(hours)h \(minutes)m 前" : "\(hours)h 前"
        }
        let days = Int(interval / 86400)
        if days > 30 { return "暂无近期记录" }
        return "\(days)天前"
    }

    func quickLogRecords(for type: RecordType) -> [RecordModel] {
        babyManager.filterRecords(allRecords, for: babyProfile).filter { $0.recordType == type }
    }

    func quickLogLastRecordTime(for type: RecordType) -> Date? {
        guard let record = quickLogRecords(for: type).max(by: { $0.timestamp < $1.timestamp }) else { return nil }
        if type == .sleep, let wakeTime = record.sleepEndTime {
            return wakeTime
        }
        return record.timestamp
    }

    func quickLogLastTimeText(for type: RecordType) -> String {
        guard let lastTime = quickLogLastRecordTime(for: type) else { return "暂无近期记录" }
        let interval = now.timeIntervalSince(lastTime)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return minutes > 0 ? "\(hours)h \(minutes)m 前" : "\(hours)h 前"
        }
        let days = Int(interval / 86400)
        if days > 30 { return "暂无近期记录" }
        return "\(days)天前"
    }

    func quickLogStatsText(for type: RecordType) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let dayAgo = now.addingTimeInterval(-24 * 3600)
        let records = quickLogRecords(for: type)
        let todayCount = records.filter { $0.timestamp >= startOfToday }.count
        let last24hCount = records.filter { $0.timestamp >= dayAgo }.count
        return "今日 \(todayCount) 次 · 24小时 \(last24hCount) 次"
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
        .sheet(item: $selectedRecordType) { type in
            RecordDetailView(recordType: type)
        }
        .sheet(isPresented: $showNotifications) {
            notificationSheet
        }
        .sheet(isPresented: $showBabyProfile) {
            babyProfileSheet
        }
        .sheet(isPresented: $showEditProfile) {
            BabyProfileEditView(profile: babyProfile, isNew: babyProfile == nil)
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
            RecordWorkflow.assignUnassignedRecordsToSelectedBaby(in: modelContext)
            scheduleNotificationsIfNeeded()
            syncFamilyRecordsIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                now = Date()
            }
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

    func syncFamilyRecordsIfNeeded() {
        let needsSync = UserDefaults.standard.bool(forKey: "familySharingNeedsSync")
        if needsSync || babyProfiles.contains(where: { $0.isFamilyShared }) {
            Task {
                await familySharingManager.syncAll(context: modelContext)
            }
        }
    }

    var homePage: some View {
        VStack(spacing: 0) {
            TopAppBar(
                babyName: babyName,
                gender: babyProfile?.gender ?? "女",
                avatarImageData: babyProfile?.avatarImageData,
                onNotificationTap: { showNotifications = true },
                onBabyTap: { showBabySwitcher = true }
            )

            ScrollView {
                VStack(spacing: 24) {
                    if !hasCompletedOnboarding && babyProfiles.isEmpty {
                        onboardingBanner
                    }

                    BabyProfileCard(
                        profile: babyProfile,
                        currentDate: now,
                        onTap: { showBabyProfile = true }
                    )

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
                    Text("欢迎使用宝宝记录")
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
                summaryItem(icon: RecordType.feeding.iconName, value: "\(todayFeedingCount)", unit: "次喂奶", color: RecordType.feeding.iconColor)
                Divider().frame(height: 40)
                summaryItem(icon: RecordType.formula.iconName, value: "\(todayFormulaCount)", unit: "次配方奶", color: RecordType.formula.iconColor)
                Divider().frame(height: 40)
                summaryItem(icon: RecordType.diaper.iconName, value: "\(todayDiaperCount)", unit: "次尿布", color: RecordType.diaper.iconColor)
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
            let filtered = babyManager.filterRecords(allRecords, for: babyProfile)
            return filtered.filter { calendar.isDate($0.timestamp, inSameDayAs: yesterday) }
        }()
        let feedingOverdue = isOverdue(for: .feeding)
        let sleepOverdue = isOverdue(for: .sleep)
        let diaperOverdue = isOverdue(for: .diaper)
        let urgentCount = [feedingOverdue, sleepOverdue, diaperOverdue].filter { $0 }.count
        let yf = yesterdayRecords.filter { $0.recordType == .feeding || $0.recordType == .formula }.count
        let ys = yesterdayRecords.filter { $0.recordType == .sleep }.count
        let yd = yesterdayRecords.filter { $0.recordType == .diaper || $0.recordType == .poop }.count

        return NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    notificationStatusHeader(urgentCount: urgentCount)

                    VStack(alignment: .leading, spacing: 10) {
                        sheetSectionTitle("今日提醒")
                        if feedingOverdue {
                            NotificationRow(icon: "clock.fill", color: Color.error, title: "喂奶提醒", detail: "距离上次喂奶已超过\(feedingIntervalHours)小时", time: "紧急")
                        }
                        if sleepOverdue {
                            NotificationRow(icon: "moon.zzz.fill", color: Color.error, title: "睡眠提醒", detail: "宝宝已清醒较久，建议准备入睡", time: "紧急")
                        }
                        if diaperOverdue {
                            NotificationRow(icon: RecordType.diaper.iconName, color: Color.error, title: "尿布提醒", detail: "距离上次更换尿布已超过\(diaperIntervalHours)小时", time: "紧急")
                        }
                        if urgentCount == 0 {
                            NotificationRow(icon: "checkmark.circle.fill", color: Color.tertiary, title: "一切正常", detail: "当前没有需要关注的提醒", time: "现在")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sheetSectionTitle("状态概览")
                        NotificationRow(icon: RecordType.feeding.iconName, color: RecordType.feeding.iconColor, title: "喂奶记录", detail: "距离上次：\(lastTimeText(for: .feeding))", time: "")
                        NotificationRow(icon: RecordType.sleep.iconName, color: RecordType.sleep.iconColor, title: "睡眠记录", detail: "距离上次：\(lastTimeText(for: .sleep))", time: "")
                        NotificationRow(icon: RecordType.diaper.iconName, color: RecordType.diaper.iconColor, title: "换尿布", detail: "距离上次：\(lastTimeText(for: .diaper))", time: "")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sheetSectionTitle("昨日总结")
                        NotificationRow(icon: "chart.bar.fill", color: Color.tertiary, title: "昨日数据", detail: "喂奶\(yf)次 · 睡眠\(ys)次 · 尿布\(yd)次", time: "昨天")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showNotifications = false }
                }
            }
        }
    }

    func notificationStatusHeader(urgentCount: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(urgentCount > 0 ? Color.error.opacity(0.13) : Color.primaryContainer.opacity(0.9))
                    .frame(width: 56, height: 56)
                Image(systemName: urgentCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(urgentCount > 0 ? Color.error : Color.primary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(urgentCount > 0 ? "\(urgentCount) 项需要关注" : "今日提醒正常")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Color.onSurface)
                Text(urgentCount > 0 ? "建议优先处理标记为紧急的事项" : "宝宝当前记录节奏看起来不错")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.outline)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(18)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke((urgentCount > 0 ? Color.error : Color.primary).opacity(0.12), lineWidth: 1)
        )
    }

    func sheetSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Color.onSurface)
            .padding(.horizontal, 2)
    }

    var babyProfileSheet: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        let birthDateText = babyProfile.map { formatter.string(from: $0.birthDate) } ?? "未设置"

        return NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let babyProfile, babyProfile.isFamilyOwner {
                        EditableBabyAvatarView(
                            imageData: avatarBinding(for: babyProfile),
                            size: 104,
                            tint: Color.primary,
                            foregroundColor: Color.primary,
                            backgroundColor: Color.primaryContainer
                        )
                    } else {
                        BabyAvatarView(
                            imageData: babyProfile?.avatarImageData,
                            size: 100,
                            backgroundColor: Color.primaryContainer,
                            foregroundColor: Color.primary,
                            borderColor: Color.primary.opacity(0.12),
                            borderWidth: 1
                        )
                    }

                    Text(babyProfile?.name ?? "宝宝")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.onSurface)

                    VStack(spacing: 16) {
                        profileRow(label: "出生日期", value: birthDateText)
                        profileRow(label: "性别", value: babyProfile?.gender ?? "未设置")
                        profileRow(label: "当前月龄", value: babyProfile?.ageText(on: now) ?? "未设置")
                        profileRow(label: "最新体重", value: latestGrowthRecord?.weightKG.map { String(format: "%.1f", $0) + "kg" } ?? "暂无")
                        profileRow(label: "最新身高", value: latestGrowthRecord?.heightCM.map { String(format: "%.0f", $0) + "cm" } ?? "暂无")
                    }
                    .padding(20)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button(action: openGrowthRecordFromProfile) {
                        HStack(spacing: 12) {
                            Image(systemName: "ruler.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.onPrimary)
                                .frame(width: 40, height: 40)
                                .background(Color.primary)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text("更新身高体重")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.onSurface)
                                Text("记录宝宝最新成长数据")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.outline)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.outlineVariant)
                        }
                        .padding(16)
                        .background(Color.primaryContainer.opacity(0.32))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.primary.opacity(0.16), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(20)
            }
            .navigationTitle("宝宝资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if babyProfile?.isFamilyOwner != false {
                        Button(babyProfile == nil ? "完善资料" : "编辑") {
                            openEditProfileFromHome()
                        }
                    }
                }
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

    func openGrowthRecordFromProfile() {
        showBabyProfile = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            addRecordType = .growth
        }
    }

    func openEditProfileFromHome() {
        showBabyProfile = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showEditProfile = true
        }
    }

    func avatarBinding(for profile: BabyProfile) -> Binding<Data?> {
        Binding(
            get: { profile.avatarImageData },
            set: { newValue in
                profile.avatarImageData = newValue
                try? modelContext.save()
                if profile.isFamilyShared {
                    Task {
                        await familySharingManager.syncAll(context: modelContext)
                    }
                }
            }
        )
    }

    var babySwitcherSheet: some View {
        NavigationView {
            List {
                Section("选择宝宝") {
                    ForEach(babyProfiles) { baby in
                        Button(action: {
                            babyManager.selectBaby(baby, from: babyProfiles)
                            showBabySwitcher = false
                        }) {
                            HStack(spacing: 12) {
                                BabyAvatarView(
                                    imageData: baby.avatarImageData,
                                    size: 44,
                                    iconSize: 22,
                                    backgroundColor: baby.persistentModelID == babyProfile?.persistentModelID ? Color.primary : Color.surfaceContainerHighest,
                                    foregroundColor: baby.persistentModelID == babyProfile?.persistentModelID ? .white : Color.primary,
                                    borderColor: baby.persistentModelID == babyProfile?.persistentModelID ? Color.primary.opacity(0.24) : Color.clear,
                                    borderWidth: 1
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(baby.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.onSurface)
                                    Text(baby.ageText(on: now))
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
            if isQuickLogActive(for: type) { return type.iconColor }
            if isOverdue(for: type) { return Color.error }
            return type.iconColor
        }()
        let bgColor: Color = {
            if isQuickLogActive(for: type) { return type.iconBackgroundColor }
            if isOverdue(for: type) { return Color.error.opacity(0.15) }
            return type.iconBackgroundColor
        }()

        QuickLogCard(
            icon: type.iconName,
            title: type.displayName,
            detailText: quickLogDetailText(for: type),
            statsText: quickLogStatsText(for: type),
            iconColor: iconColor,
            iconBackground: bgColor,
            actionTitle: quickLogActionTitle(for: type),
            actionIcon: quickLogActionIcon(for: type),
            isActive: isQuickLogActive(for: type),
            onTap: {
                switch type {
                case .feeding: showFeedingTimer = true
                case .sleep: showSleepTimer = true
                default: addRecordType = type
                }
            },
            onCardTap: {
                selectedRecordType = type
            }
        )
    }

    func quickLogDetailText(for type: RecordType) -> String {
        switch type {
        case .feeding:
            if timerManager.isFeedingRunning {
                let side = timerManager.feedingSelectedSide == 0 ? "左侧" : "右侧"
                return "\(side)喂养中 · \(formatActiveDuration(timerManager.feedingTotalDuration))"
            }
            if timerManager.hasFeedingDuration {
                return "待保存 · \(formatActiveDuration(timerManager.feedingTotalDuration))"
            }
        case .sleep:
            if timerManager.isSleeping {
                return "睡眠中 · \(formatActiveDuration(timerManager.sleepElapsed))"
            }
        default:
            break
        }

        let lastText = quickLogLastTimeText(for: type)
        if lastText == "暂无近期记录" {
            return lastText
        }
        return "上次：\(lastText)"
    }

    func quickLogActionTitle(for type: RecordType) -> String {
        switch type {
        case .feeding:
            return "记录"
        case .sleep:
            return timerManager.isSleeping ? "继续" : "记录"
        default:
            return "记录"
        }
    }

    func quickLogActionIcon(for type: RecordType) -> String {
        switch type {
        case .feeding:
            return "plus"
        case .sleep:
            return timerManager.isSleeping ? "moon.zzz.fill" : "plus"
        default:
            return "plus"
        }
    }

    func isQuickLogActive(for type: RecordType) -> Bool {
        switch type {
        case .feeding:
            return timerManager.isFeedingRunning || timerManager.hasFeedingDuration
        case .sleep:
            return timerManager.isSleeping
        default:
            return false
        }
    }

    func formatActiveDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func scheduleNotificationsIfNeeded() {
        RecordWorkflow.scheduleReminders(from: allRecords, for: babyProfile)
    }
}

#Preview {
    ContentView()
}
