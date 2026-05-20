import SwiftUI
import SwiftData

enum AchievementLevel: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case diamond = "diamond"

    var displayName: String {
        switch self {
        case .bronze: return "铜牌"
        case .silver: return "银牌"
        case .gold: return "金牌"
        case .diamond: return "钻石"
        }
    }

    var color: Color {
        switch self {
        case .bronze: return Color(hex: "CD7F32")
        case .silver: return Color(hex: "C0C0C0")
        case .gold: return Color(hex: "FFD700")
        case .diamond: return Color(hex: "B9F2FF")
        }
    }

    var gradient: [Color] {
        switch self {
        case .bronze: return [Color(hex: "CD7F32"), Color(hex: "8B5E3C")]
        case .silver: return [Color(hex: "E8E8E8"), Color(hex: "A8A8A8")]
        case .gold: return [Color(hex: "FFD700"), Color(hex: "FFA500")]
        case .diamond: return [Color(hex: "B9F2FF"), Color(hex: "7DF9FF")]
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case record = "record"
    case feeding = "feeding"
    case sleep = "sleep"
    case growth = "growth"
    case special = "special"

    var displayName: String {
        switch self {
        case .record: return "记录"
        case .feeding: return "喂奶"
        case .sleep: return "睡眠"
        case .growth: return "成长"
        case .special: return "特殊"
        }
    }

    var icon: String {
        switch self {
        case .record: return "pencil.circle.fill"
        case .feeding: return "figure.child.and.lock.fill"
        case .sleep: return "bed.double.fill"
        case .growth: return "ruler.fill"
        case .special: return "star.fill"
        }
    }
}

struct AchievementDef: Identifiable {
    let id: String
    let name: String
    let desc: String
    let category: AchievementCategory
    let level: AchievementLevel
    let icon: String
    let requirement: Int
}

@Observable
class AchievementManager {
    static let shared = AchievementManager()

    @ObservationIgnored
    @AppStorage("achievementProgress") private var progressData: Data = Data()
    @ObservationIgnored
    @AppStorage("achievementUnlocked") private var unlockedData: Data = Data()

    private var progress: [String: Int] = [:]
    private var unlocked: [String: Date] = [:]

    var newlyUnlocked: AchievementDef?

    static let allAchievements: [AchievementDef] = [
        // 记录类
        AchievementDef(id: "first_record", name: "初次记录", desc: "完成第一次记录", category: .record, level: .bronze, icon: "star.fill", requirement: 1),
        AchievementDef(id: "record_3days", name: "坚持记录", desc: "连续记录3天", category: .record, level: .bronze, icon: "flame.fill", requirement: 3),
        AchievementDef(id: "record_7days", name: "记录达人", desc: "连续记录7天", category: .record, level: .silver, icon: "flame.fill", requirement: 7),
        AchievementDef(id: "record_30days", name: "记录大师", desc: "连续记录30天", category: .record, level: .gold, icon: "crown.fill", requirement: 30),
        AchievementDef(id: "record_100days", name: "记录传奇", desc: "连续记录100天", category: .record, level: .diamond, icon: "diamond.fill", requirement: 100),

        // 喂奶类
        AchievementDef(id: "first_feeding", name: "第一口奶", desc: "记录第一次喂奶", category: .feeding, level: .bronze, icon: "figure.child.and.lock.fill", requirement: 1),
        AchievementDef(id: "feeding_8times", name: "奶量充足", desc: "单日喂奶8次", category: .feeding, level: .silver, icon: "bolt.heart.fill", requirement: 8),
        AchievementDef(id: "feeding_7days", name: "坚持母乳", desc: "连续7天纯母乳喂养", category: .feeding, level: .gold, icon: "heart.fill", requirement: 7),
        AchievementDef(id: "feeding_500", name: "喂奶专家", desc: "累计记录500次喂奶", category: .feeding, level: .diamond, icon: "trophy.fill", requirement: 500),

        // 睡眠类
        AchievementDef(id: "first_sleep", name: "安睡天使", desc: "记录第一次睡眠", category: .sleep, level: .bronze, icon: "moon.stars.fill", requirement: 1),
        AchievementDef(id: "sleep_6hours", name: "整夜安睡", desc: "宝宝连续睡6小时", category: .sleep, level: .silver, icon: "moon.zzz.fill", requirement: 1),
        AchievementDef(id: "sleep_7days", name: "规律作息", desc: "连续7天睡眠时间规律", category: .sleep, level: .gold, icon: "clock.fill", requirement: 7),
        AchievementDef(id: "sleep_300", name: "睡眠专家", desc: "累计记录300次睡眠", category: .sleep, level: .diamond, icon: "bed.double.fill", requirement: 300),

        // 成长类
        AchievementDef(id: "first_growth", name: "成长记录", desc: "记录第一次身高体重", category: .growth, level: .bronze, icon: "ruler.fill", requirement: 1),
        AchievementDef(id: "growth_healthy", name: "健康发育", desc: "身高体重在正常范围", category: .growth, level: .silver, icon: "heart.text.square.fill", requirement: 1),
        AchievementDef(id: "growth_12", name: "成长轨迹", desc: "记录12次成长数据", category: .growth, level: .gold, icon: "chart.line.uptrend.xyaxis", requirement: 12),
        AchievementDef(id: "growth_24", name: "成长档案", desc: "记录24次成长数据", category: .growth, level: .diamond, icon: "folder.fill", requirement: 24),

        // 特殊类
        AchievementDef(id: "all_types", name: "全面妈妈", desc: "记录所有类型数据", category: .special, level: .gold, icon: "rainbow", requirement: 1),
        AchievementDef(id: "night_guard", name: "夜间守护", desc: "凌晨2-5点记录3次", category: .special, level: .silver, icon: "moon.fill", requirement: 3),
        AchievementDef(id: "weekend_warrior", name: "周末不休", desc: "周末也坚持记录", category: .special, level: .silver, icon: "calendar", requirement: 2),
        AchievementDef(id: "data_1000", name: "数据达人", desc: "累计记录1000条数据", category: .special, level: .diamond, icon: "chart.bar.fill", requirement: 1000),
    ]

    init() {
        loadProgress()
        loadUnlocked()
    }

    private func loadProgress() {
        if let decoded = try? JSONDecoder().decode([String: Int].self, from: progressData) {
            progress = decoded
        }
    }

    private func loadUnlocked() {
        if let decoded = try? JSONDecoder().decode([String: Date].self, from: unlockedData) {
            unlocked = decoded
        }
    }

    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            progressData = encoded
        }
    }

    private func saveUnlocked() {
        if let encoded = try? JSONEncoder().encode(unlocked) {
            unlockedData = encoded
        }
    }

    func getProgress(for id: String) -> Int {
        return progress[id] ?? 0
    }

    func isUnlocked(_ id: String) -> Bool {
        return unlocked[id] != nil
    }

    func getUnlockedDate(_ id: String) -> Date? {
        return unlocked[id]
    }

    func checkAchievements(records: [RecordModel]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let sortedRecords = records.sorted { $0.timestamp > $1.timestamp }

        let totalRecords = records.count
        setProgress("first_record", value: totalRecords)

        let feedingRecords = records.filter { $0.recordType == .feeding }
        setProgress("first_feeding", value: feedingRecords.isEmpty ? 0 : 1)

        let sleepRecords = records.filter { $0.recordType == .sleep }
        setProgress("first_sleep", value: sleepRecords.isEmpty ? 0 : 1)

        let growthRecords = records.filter { $0.recordType == .growth }
        setProgress("first_growth", value: growthRecords.isEmpty ? 0 : 1)

        let feedingToday = feedingRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }.count
        if feedingToday >= 8 { setProgress("feeding_8times", value: feedingToday) }

        setProgress("feeding_500", value: feedingRecords.count)
        setProgress("sleep_300", value: sleepRecords.count)
        setProgress("growth_12", value: growthRecords.count)
        setProgress("growth_24", value: growthRecords.count)
        setProgress("data_1000", value: totalRecords)

        let recordDays = Set(records.map { calendar.startOfDay(for: $0.timestamp) })
        var consecutiveDays = 0
        var checkDate = today
        while recordDays.contains(checkDate) {
            consecutiveDays += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        setProgress("record_3days", value: consecutiveDays)
        setProgress("record_7days", value: consecutiveDays)
        setProgress("record_30days", value: consecutiveDays)
        setProgress("record_100days", value: consecutiveDays)

        let feedingDays = Set(feedingRecords.map { calendar.startOfDay(for: $0.timestamp) })
        var feedingConsecutive = 0
        checkDate = today
        while feedingDays.contains(checkDate) {
            feedingConsecutive += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        setProgress("feeding_7days", value: feedingConsecutive)

        let sleepDays = Set(sleepRecords.map { calendar.startOfDay(for: $0.timestamp) })
        var sleepConsecutive = 0
        checkDate = today
        while sleepDays.contains(checkDate) {
            sleepConsecutive += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        setProgress("sleep_7days", value: sleepConsecutive)

        for sleepRecord in sleepRecords {
            if let duration = sleepRecord.sleepDurationMinutes, duration >= 360 {
                setProgress("sleep_6hours", value: 1)
                break
            }
        }

        let recordTypes = Set(records.map { $0.recordType })
        if recordTypes.count >= 6 {
            setProgress("all_types", value: 1)
        }

        let nightRecords = records.filter {
            let hour = calendar.component(.hour, from: $0.timestamp)
            return hour >= 2 && hour < 5
        }
        setProgress("night_guard", value: nightRecords.count)

        let weekendRecords = records.filter {
            let weekday = calendar.component(.weekday, from: $0.timestamp)
            return weekday == 1 || weekday == 7
        }
        let weekendDays = Set(weekendRecords.map { calendar.startOfDay(for: $0.timestamp) })
        setProgress("weekend_warrior", value: weekendDays.count)

        checkUnlocks()
    }

    private func setProgress(_ id: String, value: Int) {
        let currentProgress = progress[id] ?? 0
        if value > currentProgress {
            progress[id] = value
            saveProgress()
        }
    }

    private func checkUnlocks() {
        for achievement in AchievementManager.allAchievements {
            if !isUnlocked(achievement.id) {
                let currentProgress = getProgress(for: achievement.id)
                if currentProgress >= achievement.requirement {
                    unlock(achievement)
                }
            }
        }
    }

    private func unlock(_ achievement: AchievementDef) {
        unlocked[achievement.id] = Date()
        saveUnlocked()
        newlyUnlocked = achievement
    }

    func dismissNewlyUnlocked() {
        newlyUnlocked = nil
    }

    var unlockedCount: Int {
        unlocked.count
    }

    var totalCount: Int {
        AchievementManager.allAchievements.count
    }

    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }

    func achievements(for category: AchievementCategory? = nil) -> [AchievementDef] {
        if let category = category {
            return AchievementManager.allAchievements.filter { $0.category == category }
        }
        return AchievementManager.allAchievements
    }

    func recentUnlocked(count: Int = 5) -> [AchievementDef] {
        let sortedUnlocked = unlocked.sorted { $0.value > $1.value }
        return sortedUnlocked.prefix(count).compactMap { id, _ in
            AchievementManager.allAchievements.first { $0.id == id }
        }
    }
}
