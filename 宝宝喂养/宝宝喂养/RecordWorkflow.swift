import Foundation
import SwiftData

enum RecordWorkflow {
    static func selectedBaby(in context: ModelContext) -> BabyProfile? {
        let descriptor = FetchDescriptor<BabyProfile>()
        guard let babies = try? context.fetch(descriptor) else { return nil }
        return BabyManager.shared.getSelectedBaby(from: babies)
    }

    static func assignSelectedBaby(to record: RecordModel, in context: ModelContext) {
        record.babyProfile = selectedBaby(in: context)
    }

    static func assignUnassignedRecords(to baby: BabyProfile, in context: ModelContext) {
        let descriptor = FetchDescriptor<RecordModel>()
        let records = (try? context.fetch(descriptor)) ?? []
        var didUpdate = false

        for record in records where record.babyProfile == nil {
            record.babyProfile = baby
            didUpdate = true
        }

        if didUpdate {
            try? context.save()
        }
    }

    static func assignUnassignedRecordsToSelectedBaby(in context: ModelContext) {
        guard let baby = selectedBaby(in: context) else { return }
        assignUnassignedRecords(to: baby, in: context)
    }

    static func records(_ records: [RecordModel], for baby: BabyProfile?) -> [RecordModel] {
        BabyManager.shared.filterRecords(records, for: baby)
    }

    static func latestReminderDates(from records: [RecordModel], for baby: BabyProfile?) -> (feeding: Date?, sleep: Date?, diaper: Date?) {
        let filtered = Self.records(records, for: baby)
        let lastFeeding = filtered.first(where: { $0.recordType == .feeding || $0.recordType == .formula })?.timestamp
        let lastSleep = filtered.first(where: { $0.recordType == .sleep })?.timestamp
        let lastDiaper = filtered.first(where: { $0.recordType == .diaper || $0.recordType == .poop })?.timestamp
        return (lastFeeding, lastSleep, lastDiaper)
    }

    static func scheduleReminders(from records: [RecordModel], for baby: BabyProfile?) {
        let defaults = UserDefaults.standard
        let feedingEnabled = defaults.object(forKey: "feedingEnabled") as? Bool ?? true
        let sleepEnabled = defaults.object(forKey: "sleepEnabled") as? Bool ?? true
        let diaperEnabled = defaults.object(forKey: "diaperEnabled") as? Bool ?? true
        let feedingInterval = defaults.integer(forKey: "feedingIntervalHours")
        let sleepInterval = defaults.integer(forKey: "sleepIntervalHours")
        let diaperInterval = defaults.integer(forKey: "diaperIntervalHours")
        let latest = latestReminderDates(from: records, for: baby)

        NotificationManager.shared.scheduleReminders(
            feedingInterval: feedingEnabled ? (feedingInterval > 0 ? feedingInterval : 3) : 0,
            sleepInterval: sleepEnabled ? (sleepInterval > 0 ? sleepInterval : 6) : 0,
            diaperInterval: diaperEnabled ? (diaperInterval > 0 ? diaperInterval : 3) : 0,
            lastFeeding: feedingEnabled ? latest.feeding : nil,
            lastSleep: sleepEnabled ? latest.sleep : nil,
            lastDiaper: diaperEnabled ? latest.diaper : nil
        )
    }

    static func scheduleReminders(in context: ModelContext) {
        let descriptor = FetchDescriptor<RecordModel>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let records = (try? context.fetch(descriptor)) ?? []
        scheduleReminders(from: records, for: selectedBaby(in: context))
    }

    static func checkAchievements(in context: ModelContext) {
        let descriptor = FetchDescriptor<RecordModel>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let records = (try? context.fetch(descriptor)) ?? []
        AchievementManager.shared.checkAchievements(records: Self.records(records, for: selectedBaby(in: context)))
    }
}
