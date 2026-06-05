import SwiftUI
import SwiftData
import UserNotifications

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
    @Environment(\.scenePhase) private var scenePhase
    @State private var showBabyProfile = false
    @State private var showNotifications = false
    @State private var showAbout = false
    @State private var showThemePicker = false
    @State private var showEditProfile = false
    @State private var showDataExport = false
    @State private var showBabyManager = false
    @State private var showFamilySharing = false
    @State private var showAddNewBaby = false
    @State private var showDeleteConfirm = false
    @State private var showProView = false
    @State private var showGrowthReport = false
    @State private var showAchievement = false
    @State private var addRecordType: RecordType? = nil
    @State private var deleteIndexSet: IndexSet? = nil
    @State private var animateCards = false
    @State private var now = Date()
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @AppStorage("appTheme") var appTheme: AppTheme = .system
    @AppStorage("feedingEnabled") var feedingEnabled = true
    @AppStorage("sleepEnabled") var sleepEnabled = true
    @AppStorage("diaperEnabled") var diaperEnabled = true
    @AppStorage("feedingIntervalHours") var feedingIntervalHours = 3
    @AppStorage("sleepIntervalHours") var sleepIntervalHours = 6
    @AppStorage("diaperIntervalHours") var diaperIntervalHours = 3

    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var babyProfile: BabyProfile? { babyManager.getSelectedBaby(from: babyProfiles) }
    var babyName: String { babyProfile?.name ?? "宝宝" }

    var babyRecords: [RecordModel] {
        babyManager.filterRecords(allRecords, for: babyProfile)
    }

    var latestGrowthRecord: RecordModel? {
        babyRecords.filter { $0.recordType == .growth }.max(by: { $0.timestamp < $1.timestamp })
    }

    var todayRecords: [RecordModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return babyRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    }

    var latestReminderDates: (feeding: Date?, sleep: Date?, diaper: Date?) {
        RecordWorkflow.latestReminderDates(from: allRecords, for: babyProfile)
    }

    var babyBirthDateText: String {
        guard let birthDate = babyProfile?.birthDate else { return "未设置" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: birthDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            TopAppBar(babyName: babyName, gender: babyProfile?.gender ?? "女", avatarImageData: babyProfile?.avatarImageData, onNotificationTap: { showNotifications = true }, onBabyTap: { showBabyManager = true })

            ScrollView {
                VStack(spacing: 18) {
                    profileCard
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 30)
                    todayOverviewSection
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    if !subscriptionManager.isProUser {
                        proUpgradeCard
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 16)
                    }
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
            BabyProfileEditView(profile: babyProfile, isNew: babyProfile == nil)
        }
        .sheet(isPresented: $showAddNewBaby) {
            BabyProfileEditView(profile: nil, isNew: true)
        }
        .sheet(isPresented: $showNotifications) { notificationSheet }
        .sheet(isPresented: $showThemePicker) { ThemePickerView() }
        .sheet(isPresented: $showAbout) { aboutSheet }
        .sheet(isPresented: $showDataExport) {
            DataExportView(records: babyRecords, babyProfile: babyProfile)
        }
        .sheet(isPresented: $showFamilySharing) {
            FamilySharingView(baby: babyProfile, records: babyRecords)
        }
        .sheet(isPresented: $showGrowthReport) {
            GrowthReportView(records: babyRecords, babyProfile: babyProfile)
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
        .sheet(item: $addRecordType) { type in
            AddRecordView(recordType: type)
        }
        .onReceive(refreshTimer) { time in
            now = time
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                now = Date()
                refreshNotificationAuthorizationStatus()
            }
        }
        .onAppear {
            now = Date()
            refreshNotificationAuthorizationStatus()
            Task {
                await subscriptionManager.checkSubscriptionStatus()
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateCards = true
            }
        }
    }

    var profileCard: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                BabyAvatarView(
                    imageData: babyProfile?.avatarImageData,
                    size: 72,
                    backgroundColor: Color.white.opacity(0.18),
                    foregroundColor: .white,
                    borderColor: Color.white.opacity(0.24),
                    borderWidth: 1
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(babyProfile?.name ?? "宝宝")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .truncationMode(.tail)
                            .layoutPriority(1)
                        rankBadge
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                        Text(babyProfile?.ageText(on: now) ?? "未设置生日")
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.86))
                }

                Spacer(minLength: 8)

                Button(action: { showBabyProfile = true }) {
                    HStack(spacing: 4) {
                        Text("资料")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.16))
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("查看宝宝资料")
            }

            HStack(spacing: 10) {
                profileInfoItem(
                    icon: "scalemass",
                    title: "体重",
                    value: latestGrowthRecord?.weightKG.map { String(format: "%.1f kg", $0) } ?? "--"
                )
                profileInfoItem(
                    icon: "ruler",
                    title: "身高",
                    value: latestGrowthRecord?.heightCM.map { String(format: "%.0f cm", $0) } ?? "--"
                )
                profileInfoItem(
                    icon: "calendar",
                    title: "生日",
                    value: babyBirthDateText
                )
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color.primary,
                    Color.primary.opacity(0.82),
                    Color.primary.opacity(0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.primary.opacity(0.22), radius: 12, y: 5)
    }

    var rankBadge: some View {
        let rank = AchievementManager.shared.currentRank
        return Button(action: { showAchievement = true }) {
            HStack(spacing: 4) {
                Image(systemName: rankIconName(for: rank))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                Text(rank.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: rank.gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: rank.shadowColor, radius: 4, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("查看成就中心，当前等级\(rank.displayName)")
    }

    func rankIconName(for rank: AchievementManager.AchievementRank) -> String {
        switch rank {
        case .newbie: return "medal.fill"
        case .skilled: return "medal.fill"
        case .expert: return "crown.fill"
        case .master: return "diamond.fill"
        case .legend: return "sparkles"
        }
    }

    func profileInfoItem(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.68))

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    var todayOverviewSection: some View {
        let feeding = todayRecords.filter { $0.recordType == .feeding }.count
        let formula = todayRecords.filter { $0.recordType == .formula }.count
        let diaper = todayRecords.filter { $0.recordType == .diaper || $0.recordType == .poop }.count
        let sleep = todayRecords.filter { $0.recordType == .sleep }.count
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("今日概览")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Spacer()
                Text("\(todayRecords.count) 条记录")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outline)
                    .contentTransition(.numericText())
            }

            LazyVGrid(columns: columns, spacing: 8) {
                dailyMetricTile(icon: RecordType.feeding.iconName, value: "\(feeding)", label: "母乳喂养", tint: RecordType.feeding.iconColor)
                dailyMetricTile(icon: RecordType.formula.iconName, value: "\(formula)", label: "配方奶", tint: RecordType.formula.iconColor)
                dailyMetricTile(icon: RecordType.diaper.iconName, value: "\(diaper)", label: "换尿布", tint: RecordType.diaper.iconColor)
                dailyMetricTile(icon: RecordType.sleep.iconName, value: "\(sleep)", label: "睡眠", tint: RecordType.sleep.iconColor)
            }
        }
        .padding(14)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
    }

    func dailyMetricTile(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(tint.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
            }

            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.onSurface)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.outline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(Color.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var menuSection: some View {
        VStack(spacing: 12) {
            menuCard(icon: "person.2.fill", title: "宝宝管理", subtitle: "资料、切换与添加宝宝", color: Color.primary, bgColor: Color.primaryContainer, action: { showBabyManager = true })
            menuCard(icon: "person.2.badge.plus.fill", title: "家庭共享", subtitle: "邀请家人查看和新增记录", color: Color(hex: "8B5CF6"), bgColor: Color(hex: "EEE7FF"), darkBgColor: Color(hex: "3E2A64").opacity(0.32), action: { showFamilySharing = true })
            menuCard(icon: "doc.text.magnifyingglass", title: "成长报告", subtitle: "周报月报与护理趋势", color: Color(hex: "C98924"), bgColor: Color(hex: "FFF2CC"), darkBgColor: Color(hex: "6F4A13").opacity(0.25), isProFeature: true, action: {
                if subscriptionManager.isProUser {
                    showGrowthReport = true
                } else {
                    showProView = true
                }
            })
            menuCard(icon: "doc.text.fill", title: "数据导出", subtitle: "导出 CSV 或 JSON 数据", color: Color.secondary, bgColor: Color.secondaryContainer, isProFeature: true, action: {
                if subscriptionManager.isProUser {
                    showDataExport = true
                } else {
                    showProView = true
                }
            })
            menuCard(icon: "bell.badge.fill", title: "通知提醒", subtitle: "喂奶、睡觉、换尿布提醒", color: Color.primary, bgColor: Color.primaryContainer, action: { showNotifications = true })
            menuCard(icon: "paintpalette.fill", title: "主题选择", subtitle: "浅色、深色、跟随系统", color: Color.tertiary, bgColor: Color.tertiaryContainer, action: { showThemePicker = true })
            menuCard(icon: "trophy.fill", title: "成就中心", subtitle: "徽章、等级与记录进度", color: Color.secondary, bgColor: Color.secondaryContainer, action: { showAchievement = true })
            menuCard(icon: "info.circle.fill", title: "关于我们", subtitle: "版本信息与意见反馈", color: Color.onSurfaceVariant, bgColor: Color.surfaceContainerHigh, action: { showAbout = true })
        }
    }

    private var proUpgradeCard: some View {
        Button(action: { showProView = true }) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFE8A3"), Color(hex: "D99A2B")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(hex: "5B3B08"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("升级PRO版本")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "FFF6D8") : Color(hex: "6B4208"))
                    Text("解锁成长报告、数据导出和更多能力")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "F6D28A") : Color(hex: "8A6A2A"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 8)

                Text("立即开通")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "5B3B08") : Color(hex: "FFF6D8"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(colorScheme == .dark ? Color(hex: "FFE8A3") : Color(hex: "6B4208"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: colorScheme == .dark ? [
                        Color(hex: "2B2418"),
                        Color(hex: "6F4A13"),
                        Color(hex: "C98924")
                    ] : [
                        Color(hex: "FFF9EA"),
                        Color(hex: "FFECC4"),
                        Color(hex: "F8D68B")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: "FFE8A3").opacity(colorScheme == .dark ? 0.35 : 0.85), lineWidth: 1)
            )
            .shadow(color: Color(hex: "C98924").opacity(colorScheme == .dark ? 0.28 : 0.16), radius: 12, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("升级PRO版本，解锁成长报告、数据导出和更多能力")
    }

    func menuCard(icon: String, title: String, subtitle: String, color: Color, bgColor: Color, darkBgColor: Color? = nil, isProFeature: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? (darkBgColor ?? color.opacity(0.15)) : bgColor)
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.onSurface)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                if isProFeature && !subscriptionManager.isProUser {
                    Text("Pro")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.onPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary)
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
            .shadow(color: Color.black.opacity(0.025), radius: 5, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
    }

    struct MenuItem {
        let icon: String
        let title: String
        let color: Color
        let action: () -> Void
    }

    var notificationSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    reminderHeaderCard
                    notificationPermissionCard

                    VStack(alignment: .leading, spacing: 10) {
                        sheetSectionTitle("通知开关")
                        reminderToggleRow(
                            icon: RecordType.feeding.iconName,
                            title: "喂奶提醒",
                            subtitle: "超过设定间隔后提醒喂奶",
                            color: RecordType.feeding.iconColor,
                            isOn: $feedingEnabled
                        )
                        reminderToggleRow(
                            icon: RecordType.sleep.iconName,
                            title: "睡眠提醒",
                            subtitle: "宝宝清醒较久时提醒准备入睡",
                            color: RecordType.sleep.iconColor,
                            isOn: $sleepEnabled
                        )
                        reminderToggleRow(
                            icon: RecordType.diaper.iconName,
                            title: "尿布提醒",
                            subtitle: "超过设定间隔后提醒检查尿布",
                            color: RecordType.diaper.iconColor,
                            isOn: $diaperEnabled
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sheetSectionTitle("提醒间隔")
                        reminderIntervalRow(
                            icon: RecordType.feeding.iconName,
                            title: "喂奶间隔",
                            subtitle: nextReminderText(enabled: feedingEnabled, lastDate: latestReminderDates.feeding, intervalHours: feedingIntervalHours),
                            color: RecordType.feeding.iconColor,
                            selection: $feedingIntervalHours,
                            options: [2, 3, 4, 5]
                        )
                        reminderIntervalRow(
                            icon: RecordType.diaper.iconName,
                            title: "尿布间隔",
                            subtitle: nextReminderText(enabled: diaperEnabled, lastDate: latestReminderDates.diaper, intervalHours: diaperIntervalHours),
                            color: RecordType.diaper.iconColor,
                            selection: $diaperIntervalHours,
                            options: [2, 3, 4]
                        )
                        reminderIntervalRow(
                            icon: RecordType.sleep.iconName,
                            title: "睡眠间隔",
                            subtitle: nextReminderText(enabled: sleepEnabled, lastDate: latestReminderDates.sleep, intervalHours: sleepIntervalHours),
                            color: RecordType.sleep.iconColor,
                            selection: $sleepIntervalHours,
                            options: [4, 5, 6, 8]
                        )
                    }

                    reminderInfoCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("通知提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveReminderSettingsAndDismiss()
                    }
                }
            }
        }
    }

    var reminderHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.primaryContainer.opacity(0.9))
                    .frame(width: 56, height: 56)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundColor(Color.primary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("照顾节奏提醒")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Color.onSurface)
                Text("根据最近一次记录自动安排本地通知")
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
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }

    func sheetSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Color.onSurface)
            .padding(.horizontal, 2)
    }

    var notificationPermissionCard: some View {
        let isEnabled = notificationAuthorizationStatus == .authorized || notificationAuthorizationStatus == .provisional || notificationAuthorizationStatus == .ephemeral
        let isDenied = notificationAuthorizationStatus == .denied
        let title = isEnabled ? "系统通知已开启" : (isDenied ? "系统通知未开启" : "开启提醒时申请权限")
        let subtitle = isEnabled ? "App 可以按设置时间发送本地提醒" : (isDenied ? "请到系统设置中允许通知，否则提醒不会弹出" : "点击完成保存提醒时，会弹出系统通知授权")
        let tint = isEnabled ? Color.tertiary : (isDenied ? Color.error : Color.primary)
        let statusText = isEnabled ? "可用" : (isDenied ? "未开启" : "待开启")

        return HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(tint.opacity(0.13))
                    .frame(width: 42, height: 42)
                Image(systemName: isEnabled ? "checkmark.bell.fill" : (isDenied ? "bell.slash.fill" : "bell.badge.fill"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outline)
                    .lineLimit(2)
            }
            .layoutPriority(1)

            Text(statusText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(tint.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 3)
    }

    func reminderToggleRow(icon: String, title: String, subtitle: String, color: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(color.opacity(0.13))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outline)
                    .lineLimit(2)
            }
            .layoutPriority(1)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.primary)
        }
        .padding(14)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.outlineVariant.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 3)
    }

    func reminderIntervalRow(icon: String, title: String, subtitle: String, color: Color, selection: Binding<Int>, options: [Int]) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(color.opacity(0.13))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outline)
                    .lineLimit(2)
            }
            .layoutPriority(1)

            Spacer()

            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { hour in
                    Text("\(hour)小时").tag(hour)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.primary)
        }
        .padding(14)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.outlineVariant.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 3)
    }

    func nextReminderText(enabled: Bool, lastDate: Date?, intervalHours: Int) -> String {
        guard enabled else { return "已关闭提醒" }
        guard let lastDate else { return "暂无记录，记录后自动安排提醒" }

        let nextDate = lastDate.addingTimeInterval(Double(intervalHours) * 3600)
        if nextDate <= now {
            return "已超过设定间隔，建议关注"
        }

        return "下次提醒 \(nextReminderDateText(nextDate))"
    }

    func nextReminderDateText(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.timeZone = .current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "今天 \(formatter.string(from: date))"
        }
        if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "HH:mm"
            return "明天 \(formatter.string(from: date))"
        }

        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }

    func refreshNotificationAuthorizationStatus() {
        Task {
            let status = await NotificationManager.shared.authorizationStatus()
            await MainActor.run {
                notificationAuthorizationStatus = status
            }
        }
    }

    var reminderInfoCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.primary)
                .padding(.top, 1)
            Text("设置完成后，系统会在对应时间到达时发送本地推送通知。关闭某项提醒后，不会再为该类型安排新的通知。")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.outline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.primaryContainer.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }

    func rescheduleNotifications() {
        let latest = RecordWorkflow.latestReminderDates(from: allRecords, for: babyProfile)

        NotificationManager.shared.scheduleReminders(
            feedingInterval: feedingEnabled ? feedingIntervalHours : 0,
            sleepInterval: sleepEnabled ? sleepIntervalHours : 0,
            diaperInterval: diaperEnabled ? diaperIntervalHours : 0,
            lastFeeding: feedingEnabled ? latest.feeding : nil,
            lastSleep: sleepEnabled ? latest.sleep : nil,
            lastDiaper: diaperEnabled ? latest.diaper : nil
        )
    }

    func saveReminderSettingsAndDismiss() {
        let hasEnabledReminder = feedingEnabled || sleepEnabled || diaperEnabled

        Task {
            if hasEnabledReminder {
                let granted = await NotificationManager.shared.ensurePermissionIfNeeded()
                let status = await NotificationManager.shared.authorizationStatus()

                await MainActor.run {
                    notificationAuthorizationStatus = status
                    if granted {
                        rescheduleNotifications()
                    } else {
                        NotificationManager.shared.cancelAll()
                    }
                    showNotifications = false
                }
            } else {
                await MainActor.run {
                    NotificationManager.shared.cancelAll()
                    showNotifications = false
                }
            }
        }
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
                            foregroundColor: .white,
                            backgroundColor: Color.primary
                        )
                    } else {
                        BabyAvatarView(
                            imageData: babyProfile?.avatarImageData,
                            size: 100,
                            backgroundColor: Color.primary,
                            foregroundColor: .white,
                            borderColor: Color.primary.opacity(0.16),
                            borderWidth: 1
                        )
                        .shadow(color: Color.primary.opacity(0.3), radius: 10, y: 4)
                    }

                    Text(babyProfile?.name ?? "宝宝")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.onSurface)

                    VStack(spacing: 1) {
                        profileDetailRow(label: "出生日期", value: birthDateText, icon: "calendar")
                        profileDetailRow(label: "性别", value: babyProfile?.gender ?? "未设置", icon: "person")
                        profileDetailRow(label: "当前月龄", value: babyProfile?.ageText(on: now) ?? "未设置", icon: "clock")
                        profileDetailRow(label: "最新体重", value: latestGrowthRecord?.weightKG.map { String(format: "%.1f", $0) + "kg" } ?? "暂无", icon: "scalemass")
                        profileDetailRow(label: "最新身高", value: latestGrowthRecord?.heightCM.map { String(format: "%.0f", $0) + "cm" } ?? "暂无", icon: "ruler")
                    }
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)

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
                            showBabyProfile = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showEditProfile = true
                            }
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

    func openGrowthRecordFromProfile() {
        showBabyProfile = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            addRecordType = .growth
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
                        await FamilySharingManager.shared.syncAll(context: modelContext)
                    }
                }
            }
        )
    }

    var babyManagerSheet: some View {
        NavigationView {
            List {
                Section("当前宝宝") {
                    ForEach(babyProfiles) { baby in
                        HStack(spacing: 12) {
                            BabyAvatarView(
                                imageData: baby.avatarImageData,
                                size: 44,
                                iconSize: 20,
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

                            if baby.isFamilyShared && !baby.isFamilyOwner {
                                Text("共享")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: "8B5CF6"))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "EEE7FF"))
                                    .clipShape(Capsule())
                            }

                            if baby.persistentModelID == babyProfile?.persistentModelID {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.primary)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            babyManager.selectBaby(baby, from: babyProfiles)
                        }
                    }
                    .onDelete { indexSet in
                        let deletableIndexes = IndexSet(indexSet.filter { babyProfiles[$0].isFamilyOwner })
                        guard !deletableIndexes.isEmpty else { return }
                        deleteIndexSet = deletableIndexes
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
                        Text("创建者可删除宝宝；共享宝宝仅支持查看和新增记录")
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
            guard baby.isFamilyOwner else { continue }
            if baby.persistentModelID == babyProfile?.persistentModelID {
                let remaining = babyProfiles.filter { $0.persistentModelID != baby.persistentModelID }
                if let first = remaining.first {
                    babyManager.selectBaby(first, from: remaining)
                } else {
                    babyManager.selectedBaby = nil
                }
            }
            for record in allRecords where record.babyProfile?.persistentModelID == baby.persistentModelID {
                modelContext.delete(record)
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
                    Text("宝宝记录")
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
