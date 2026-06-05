import SwiftUI
import SwiftData

struct SleepTimerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var timerManager = TimerManager.shared
    @State private var notes = ""
    @State private var showManualInput = false
    @State private var manualStartTime = Date()
    @State private var manualEndTime = Date()
    @State private var manualErrorMessage = ""
    @State private var showManualStartTimePicker = false
    @State private var showManualEndTimePicker = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            headerSection

                            if timerManager.isSleeping {
                                activeSleepSection
                            } else {
                                sleepStartSection
                            }

                            notesSection
                        }
                        .padding(20)
                        .padding(.bottom, 96)
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
            .sheet(isPresented: $showManualInput) {
                manualSleepSheet
            }
        }
    }

    var headerSection: some View {
        VStack(spacing: 12) {
            Text(timerManager.isSleeping ? "宝宝正在睡觉" : "记录宝宝睡眠")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.outline)

            Image(systemName: timerManager.isSleeping ? "moon.zzz.fill" : "moon.stars")
                .font(.system(size: 48))
                .foregroundColor(Color.primaryDim)
                .opacity(timerManager.isSleeping ? 1.0 : 0.55)

            Text(formatTime(timerManager.sleepElapsed))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(Color.primaryDim)
                .monospacedDigit()

            if let start = timerManager.sleepStartTime {
                Text("入睡 \(timeString(start)) · 已睡 \(formatDurationText(timerManager.sleepElapsed))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.outline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    var activeSleepSection: some View {
        VStack(spacing: 14) {
            Button(action: { saveRunningSleep() }) {
                HStack(spacing: 12) {
                    Image(systemName: "sun.max.circle.fill")
                        .font(.system(size: 28))
                    Text("宝宝醒了，保存睡眠")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: Color.primary.opacity(0.24), radius: 8, y: 4)
            }

            if let start = timerManager.sleepStartTime {
                sleepInfoCard(title: "本次入睡时间", value: timeString(start), icon: "clock.fill")
            }
        }
    }

    var sleepStartSection: some View {
        VStack(spacing: 14) {
            Button(action: { startSleep() }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                    Text("现在开始睡觉")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.primaryDim)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: Color.primaryDim.opacity(0.28), radius: 8, y: 4)
            }

            HStack(spacing: 10) {
                quickStartButton(title: "15分钟前", minutesAgo: 15)
                quickStartButton(title: "30分钟前", minutesAgo: 30)
                quickStartButton(title: "1小时前", minutesAgo: 60)
            }

            Button(action: showManualSleepInput) {
                manualEntryButtonLabel(title: "手动记录睡眠", icon: "plus.circle.fill")
            }
            .buttonStyle(.plain)
        }
    }

    func quickStartButton(title: String, minutesAgo: Int) -> some View {
        Button(action: { startSleep(minutesAgo: minutesAgo) }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.primaryDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.primaryContainer.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }

    func sleepInfoCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color.primaryDim)
                .frame(width: 44, height: 44)
                .background(Color.primaryContainer.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.outline)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.onSurface)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var notesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("备注")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.onSurfaceVariant)
                    .textCase(.uppercase)
                Spacer()
            }
            TextEditor(text: $notes)
                .frame(minHeight: 72)
                .padding(12)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.outlineVariant.opacity(0.3), lineWidth: 1))
        }
    }

    var manualSleepSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Button(action: { showManualStartTimePicker = true }) {
                        timeSelectionRow(title: "入睡时间", date: manualStartTime, icon: "moon.fill")
                    }
                    .buttonStyle(.plain)

                    Button(action: { showManualEndTimePicker = true }) {
                        timeSelectionRow(title: "醒来时间", date: manualEndTime, icon: "sun.max.fill")
                    }
                    .buttonStyle(.plain)
                }

                sleepInfoCard(title: "睡眠时长", value: formatDurationText(manualEndTime.timeIntervalSince(manualStartTime)), icon: "moon.zzz.fill")

                if !manualErrorMessage.isEmpty {
                    Text(manualErrorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.error.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Spacer()

                Button(action: saveManualSleep) {
                    Text("保存睡眠记录")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSaveManualSleep ? Color.primaryDim : Color.outlineVariant)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .disabled(!canSaveManualSleep)
            }
            .padding(20)
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("手动记录睡眠")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showManualStartTimePicker) {
                timePickerSheet(date: $manualStartTime, title: "入睡时间") {
                    showManualStartTimePicker = false
                }
            }
            .sheet(isPresented: $showManualEndTimePicker) {
                timePickerSheet(date: $manualEndTime, title: "醒来时间") {
                    showManualEndTimePicker = false
                }
            }
            .onChange(of: manualStartTime) { _, _ in
                manualErrorMessage = ""
            }
            .onChange(of: manualEndTime) { _, _ in
                manualErrorMessage = ""
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showManualInput = false
                        manualErrorMessage = ""
                    }
                }
            }
        }
    }

    func manualEntryButtonLabel(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
            Text(title)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundColor(Color.primaryDim)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Color.primaryContainer.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primaryDim.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    func timeSelectionRow(title: String, date: Date, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.primaryDim)
                .frame(width: 44, height: 44)
                .background(Color.primaryContainer.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.outline)
                Text(dateTimeString(date))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.onSurface)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.outlineVariant)
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func timePickerSheet(date: Binding<Date>, title: String, onClose: @escaping () -> Void) -> some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("选择\(title)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.onSurface)
                    .padding(.top, 16)

                CalendarTimePicker(selectedDate: date, showsConfirmButton: false) {
                    onClose()
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { onClose() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") { onClose() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    var canSaveManualSleep: Bool {
        manualEndTime > manualStartTime
    }

    func startSleep(minutesAgo: Int = 0) {
        let startTime = Date().addingTimeInterval(-Double(minutesAgo * 60))
        timerManager.startSleep(at: startTime)
    }

    func saveRunningSleep() {
        guard let startTime = timerManager.sleepStartTime else { return }
        let endTime = Date()
        timerManager.stopSleep()
        saveSleepRecord(startTime: startTime, endTime: endTime)
        timerManager.resetSleep()
        dismiss()
    }

    func showManualSleepInput() {
        let now = Date()
        manualStartTime = now
        manualEndTime = now
        manualErrorMessage = ""
        showManualInput = true
    }

    func saveManualSleep() {
        guard manualEndTime > manualStartTime else {
            manualErrorMessage = "醒来时间必须晚于入睡时间"
            return
        }

        saveSleepRecord(startTime: manualStartTime, endTime: manualEndTime)
        showManualInput = false
        dismiss()
    }

    func saveSleepRecord(startTime: Date, endTime: Date) {
        let durationMinutes = max(1, Int((endTime.timeIntervalSince(startTime) / 60).rounded(.up)))
        let noteText = notes.isEmpty ? "睡眠\(formatDuration(durationMinutes))" : notes
        let record = RecordModel(type: .sleep, timestamp: startTime, note: noteText)
        RecordWorkflow.assignSelectedBaby(to: record, in: modelContext)
        record.sleepEndTime = endTime
        modelContext.insert(record)
        RecordWorkflow.checkAchievements(in: modelContext)
        RecordWorkflow.scheduleReminders(in: modelContext)
        Task {
            await FamilySharingManager.shared.upload(record: record, context: modelContext)
        }
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

    func formatDurationText(_ time: TimeInterval) -> String {
        let totalMinutes = max(0, Int((time / 60).rounded(.down)))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)小时\(m)分钟" }
        if h > 0 { return "\(h)小时" }
        return "\(m)分钟"
    }

    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func dateTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    SleepTimerView()
}
