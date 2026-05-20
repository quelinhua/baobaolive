import SwiftUI
import SwiftData

struct SleepTimerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var timerManager = TimerManager.shared
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text(timerManager.isSleeping ? "宝宝正在睡觉..." : "宝宝睡眠计时")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.outline)

                        Image(systemName: timerManager.isSleeping ? "moon.zzz.fill" : "moon.stars")
                            .font(.system(size: 48))
                            .foregroundColor(Color.primaryDim)
                            .opacity(timerManager.isSleeping ? 1.0 : 0.5)

                        Text(formatTime(timerManager.sleepElapsed))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primaryDim)
                            .monospacedDigit()

                        if let start = timerManager.sleepStartTime {
                            Text("入睡时间：\(timeString(start))")
                                .font(.system(size: 14))
                                .foregroundColor(Color.outline)
                        }
                    }
                    .padding(.top, 60)

                    Button(action: { toggleSleep() }) {
                        HStack(spacing: 12) {
                            Image(systemName: timerManager.isSleeping ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 28))
                            Text(timerManager.isSleeping ? "宝宝醒了" : "开始睡觉")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(timerManager.isSleeping ? Color(hex: "FF6B6B") : Color.primaryDim)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: (timerManager.isSleeping ? Color(hex: "FF6B6B") : Color.primaryDim).opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        HStack {
                            Text("备注")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.onSurfaceVariant)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 60)
                            .padding(12)
                            .background(Color.surfaceContainerLowest)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.outlineVariant.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.primary)
                    }
                }
            }
        }
    }

    func toggleSleep() {
        if timerManager.isSleeping {
            timerManager.stopSleep()
            saveRecord()
        } else {
            timerManager.startSleep()
        }
    }

    func saveRecord() {
        guard let startTime = timerManager.sleepStartTime else { return }
        let endTime = Date()
        let durationMinutes = Int(endTime.timeIntervalSince(startTime)) / 60

        let noteText = notes.isEmpty ? "睡眠\(formatDuration(durationMinutes))" : notes
        let record = RecordModel(type: .sleep, timestamp: startTime, note: noteText)
        record.sleepEndTime = endTime
        modelContext.insert(record)
        checkAchievements()

        schedulePostRecordNotifications()
        timerManager.resetSleep()
        dismiss()
    }

    func checkAchievements() {
        let descriptor = FetchDescriptor<RecordModel>()
        if let allRecords = try? modelContext.fetch(descriptor) {
            AchievementManager.shared.checkAchievements(records: allRecords)
        }
    }

    func schedulePostRecordNotifications() {
        let defaults = UserDefaults.standard
        let feedingInterval = defaults.integer(forKey: "feedingIntervalHours")
        let sleepInterval = defaults.integer(forKey: "sleepIntervalHours")
        let diaperInterval = defaults.integer(forKey: "diaperIntervalHours")

        let descriptor = FetchDescriptor<RecordModel>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let allRecs = (try? modelContext.fetch(descriptor)) ?? []

        let lastFeeding = allRecs.first(where: { $0.recordType == .feeding })?.timestamp
        let lastSleep = allRecs.first(where: { $0.recordType == .sleep })?.timestamp
        let lastDiaper = allRecs.first(where: { $0.recordType == .diaper || $0.recordType == .poop })?.timestamp

        NotificationManager.shared.scheduleReminders(
            feedingInterval: feedingInterval > 0 ? feedingInterval : 3,
            sleepInterval: sleepInterval > 0 ? sleepInterval : 6,
            diaperInterval: diaperInterval > 0 ? diaperInterval : 3,
            lastFeeding: lastFeeding,
            lastSleep: lastSleep,
            lastDiaper: lastDiaper
        )
    }

    func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)小时\(m)分钟" }
        if h > 0 { return "\(h)小时" }
        return "\(m)分钟"
    }

    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    SleepTimerView()
}
