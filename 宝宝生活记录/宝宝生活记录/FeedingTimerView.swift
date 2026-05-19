import SwiftUI
import SwiftData

struct FeedingTimerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var timerManager = TimerManager.shared
    @State private var notes = ""
    @State private var showManualInput = false
    @State private var manualMinutes = ""

    let breastSides = ["左侧", "右侧"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("母乳喂养计时")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.outline)

                        Text(formatTime(timerManager.feedingElapsed))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primary)
                            .monospacedDigit()

                        Text(breastSides[timerManager.feedingSelectedSide])
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.onSurface)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color.primaryContainer.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 40)

                    HStack(spacing: 20) {
                        durationCard(label: "左侧", duration: timerManager.feedingLeftDuration, recorded: timerManager.feedingHasRecordedLeft)
                        durationCard(label: "右侧", duration: timerManager.feedingRightDuration, recorded: timerManager.feedingHasRecordedRight)
                    }

                    HStack(spacing: 16) {
                        ForEach(0..<breastSides.count, id: \.self) { index in
                            Button(action: { timerManager.switchFeedingSide(index) }) {
                                Text(breastSides[index])
                                    .font(.system(size: 16, weight: timerManager.feedingSelectedSide == index ? .bold : .medium))
                                    .foregroundColor(timerManager.feedingSelectedSide == index ? Color.onPrimaryContainer : Color.onSurface)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(timerManager.feedingSelectedSide == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Button(action: { toggleTimer() }) {
                        HStack(spacing: 12) {
                            Image(systemName: timerManager.isFeedingRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 28))
                            Text(timerManager.isFeedingRunning ? "暂停" : "开始计时")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(timerManager.isFeedingRunning ? Color(hex: "FF8C00") : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: (timerManager.isFeedingRunning ? Color(hex: "FF8C00") : Color.primary).opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 20)

                    Button(action: { showManualInput = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle")
                                .font(.system(size: 18))
                            Text("手动输入时间")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(Color.outline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.surfaceContainerHighest.opacity(0.5))
                        .clipShape(Capsule())
                    }
                    .alert("手动输入喂奶时长", isPresented: $showManualInput) {
                        TextField("分钟数", text: $manualMinutes)
                            .keyboardType(.numberPad)
                        Button("取消", role: .cancel) { manualMinutes = "" }
                        Button("确认") {
                            if let mins = Int(manualMinutes), mins > 0 {
                                timerManager.saveFeedingManually(minutes: mins)
                                manualMinutes = ""
                            }
                        }
                    } message: {
                        Text("请输入本次喂奶的时长（分钟）")
                    }

                    if timerManager.feedingHasRecordedLeft || timerManager.feedingHasRecordedRight {
                        VStack(spacing: 12) {
                            sectionLabel("备注")
                            TextEditor(text: $notes)
                                .frame(minHeight: 60)
                                .padding(12)
                                .background(Color.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.outlineVariant.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    if timerManager.feedingHasRecordedLeft || timerManager.feedingHasRecordedRight {
                        Button(action: { saveAndDismiss() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 20))
                                Text("保存记录").font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(Color.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .shadow(color: Color.primary.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
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

    func durationCard(label: String, duration: TimeInterval, recorded: Bool) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.outline)
            Text(formatTime(duration))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(recorded ? Color.primary : Color.outlineVariant)
                .monospacedDigit()
            if recorded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.onSurfaceVariant)
                .textCase(.uppercase)
            Spacer()
        }
    }

    func toggleTimer() {
        if timerManager.isFeedingRunning {
            timerManager.pauseFeeding()
        } else {
            timerManager.startFeeding(side: timerManager.feedingSelectedSide)
        }
    }

    func saveAndDismiss() {
        timerManager.pauseFeeding()
        let totalMinutes = Int((timerManager.feedingLeftDuration + timerManager.feedingRightDuration) / 60)
        let side: String
        if timerManager.feedingHasRecordedLeft && timerManager.feedingHasRecordedRight {
            side = "双侧"
        } else if timerManager.feedingHasRecordedLeft {
            side = "左侧"
        } else {
            side = "右侧"
        }

        let record = RecordModel(type: .feeding, timestamp: Date(), note: notes.isEmpty ? "\(side)喂奶\(totalMinutes > 0 ? " \(totalMinutes)分钟" : "")" : notes)
        record.breastSide = side
        if totalMinutes > 0 {
            record.feedingDurationMin = totalMinutes
        }
        modelContext.insert(record)

        schedulePostRecordNotifications()
        timerManager.resetFeeding()
        dismiss()
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
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    FeedingTimerView()
}
