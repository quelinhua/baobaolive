import SwiftUI
import SwiftData

struct FeedingTimerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var timerManager = TimerManager.shared
    @State private var notes = ""
    @State private var showManualInput = false
    @State private var showBottleInput = false
    @State private var manualSide = 0
    @State private var manualStartTime = Date()
    @State private var manualEndTime = Date()
    @State private var bottleTime = Date()
    @State private var bottleAmount = ""
    @State private var manualErrorMessage = ""
    @State private var bottleErrorMessage = ""
    @State private var showManualStartTimePicker = false
    @State private var showManualEndTimePicker = false
    @State private var showBottleTimePicker = false
    @State private var feedingRecordTime = Date()

    let breastSides = ["左侧", "右侧"]

    private var selectedSideText: String {
        breastSides[timerManager.feedingSelectedSide]
    }

    private var primaryActionTitle: String {
        if timerManager.isFeedingRunning { return "暂停计时" }
        if timerManager.hasFeedingDuration { return "继续\(selectedSideText)" }
        return "开始\(selectedSideText)"
    }

    private var primaryActionIcon: String {
        timerManager.isFeedingRunning ? "pause.circle.fill" : "play.circle.fill"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(timerManager.isFeedingRunning ? "正在\(selectedSideText)喂养" : "母乳喂养")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.outline)

                        Text(formatTime(timerManager.feedingElapsed))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(Color.primary)
                            .monospacedDigit()

                        Text("本次累计 \(formatDurationText(timerManager.feedingTotalDuration))")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.onSurface)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color.primaryContainer.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 40)

                    HStack(spacing: 20) {
                        durationCard(
                            label: "左侧",
                            duration: sideDuration(0),
                            recorded: timerManager.feedingHasRecordedLeft || (timerManager.feedingSelectedSide == 0 && timerManager.feedingCurrentSideDuration > 0),
                            isActive: timerManager.feedingSelectedSide == 0
                        )
                        durationCard(
                            label: "右侧",
                            duration: sideDuration(1),
                            recorded: timerManager.feedingHasRecordedRight || (timerManager.feedingSelectedSide == 1 && timerManager.feedingCurrentSideDuration > 0),
                            isActive: timerManager.feedingSelectedSide == 1
                        )
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 16) {
                        ForEach(0..<breastSides.count, id: \.self) { index in
                            Button(action: { timerManager.switchFeedingSide(index) }) {
                                VStack(spacing: 6) {
                                    Text(breastSides[index])
                                        .font(.system(size: 16, weight: timerManager.feedingSelectedSide == index ? .bold : .medium))
                                    Text(formatDurationText(sideDuration(index)))
                                        .font(.system(size: 12, weight: .medium))
                                        .monospacedDigit()
                                }
                                .foregroundColor(timerManager.feedingSelectedSide == index ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(timerManager.feedingSelectedSide == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Button(action: { toggleTimer() }) {
                        HStack(spacing: 12) {
                            Image(systemName: primaryActionIcon)
                                .font(.system(size: 28))
                            Text(primaryActionTitle)
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

                    HStack(spacing: 12) {
                        Button(action: showManualFeedingInput) {
                            manualEntryButtonLabel(title: "手动添加", icon: "plus.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("手动添加喂养记录")

                        Button(action: showBottleFeedingInput) {
                            manualEntryButtonLabel(title: "母乳瓶喂", icon: "waterbottle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    if timerManager.hasFeedingDuration {
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

                    if timerManager.hasFeedingDuration {
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
            .sheet(isPresented: $showManualInput) {
                manualFeedingSheet
            }
            .sheet(isPresented: $showBottleInput) {
                bottleFeedingSheet
            }
        }
    }

    func durationCard(label: String, duration: TimeInterval, recorded: Bool, isActive: Bool) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.outline)
            Text(formatTime(duration))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(recorded ? Color.primary : Color.outlineVariant)
                .monospacedDigit()
            if recorded {
                Image(systemName: isActive && timerManager.isFeedingRunning ? "timer.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Color.primary.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    var manualFeedingSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        manualBreastFeedingContent

                        if !manualErrorMessage.isEmpty {
                            Text(manualErrorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.error.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                }

                Button(action: saveManualFeedingInput) {
                    Text("保存喂养记录")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSaveManualFeeding ? Color.primary : Color.outlineVariant)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .disabled(!canSaveManualFeeding)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("手动添加喂养记录")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showManualStartTimePicker) {
                timePickerSheet(date: $manualStartTime, title: "开始时间") {
                    showManualStartTimePicker = false
                }
            }
            .sheet(isPresented: $showManualEndTimePicker) {
                timePickerSheet(date: $manualEndTime, title: "结束时间") {
                    showManualEndTimePicker = false
                }
            }
            .onChange(of: manualStartTime) { _, _ in manualErrorMessage = "" }
            .onChange(of: manualEndTime) { _, _ in manualErrorMessage = "" }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        resetManualInput()
                        showManualInput = false
                    }
                }
            }
            .onAppear {
                manualSide = timerManager.feedingSelectedSide
            }
        }
    }

    var bottleFeedingSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            sectionLabel("瓶喂时间")
                            Button(action: { showBottleTimePicker = true }) {
                                timeSelectionRow(title: "发生时间", date: bottleTime, icon: "calendar")
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(spacing: 12) {
                            sectionLabel("奶量")
                            HStack {
                                Image(systemName: "waterbottle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.secondary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.secondaryContainer.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                TextField("输入奶量", text: $bottleAmount)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 18, weight: .semibold))

                                Text("ml")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.outline)
                            }
                            .padding(16)
                            .background(Color.surfaceContainerLowest)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        if !bottleErrorMessage.isEmpty {
                            Text(bottleErrorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.error.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                }

                Button(action: saveBottleFeedingInput) {
                    Text("保存瓶喂记录")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSaveBottleFeeding ? Color.primary : Color.outlineVariant)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .disabled(!canSaveBottleFeeding)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("母乳瓶喂")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showBottleTimePicker) {
                timePickerSheet(date: $bottleTime, title: "瓶喂时间") {
                    showBottleTimePicker = false
                }
            }
            .onChange(of: bottleTime) { _, _ in bottleErrorMessage = "" }
            .onChange(of: bottleAmount) { _, _ in bottleErrorMessage = "" }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        resetBottleInput()
                        showBottleInput = false
                    }
                }
            }
        }
    }

    var manualBreastFeedingContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("喂奶部位")
                HStack(spacing: 12) {
                    ForEach(0..<breastSides.count, id: \.self) { index in
                        Button(action: { manualSide = index }) {
                            Text(breastSides[index])
                                .font(.system(size: 16, weight: manualSide == index ? .bold : .medium))
                                .foregroundColor(manualSide == index ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(manualSide == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(spacing: 12) {
                sectionLabel("喂奶时间")
                Button(action: { showManualStartTimePicker = true }) {
                    timeSelectionRow(title: "开始时间", date: manualStartTime, icon: "play.circle.fill")
                }
                .buttonStyle(.plain)

                Button(action: { showManualEndTimePicker = true }) {
                    timeSelectionRow(title: "结束时间", date: manualEndTime, icon: "stop.circle.fill")
                }
                .buttonStyle(.plain)
            }

            manualInfoCard(title: "喂奶时长", value: manualBreastDurationText, icon: "timer")
        }
    }

    func manualEntryButtonLabel(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.86)
        }
        .foregroundColor(Color.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Color.primaryContainer.opacity(0.32))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    func timeSelectionRow(title: String, date: Date, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.primary)
                .frame(width: 44, height: 44)
                .background(Color.primaryContainer.opacity(0.32))
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

    func manualInfoCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.primary)
                .frame(width: 44, height: 44)
                .background(Color.primaryContainer.opacity(0.32))
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
            if !timerManager.hasFeedingDuration {
                feedingRecordTime = Date()
            }
            timerManager.startFeeding(side: timerManager.feedingSelectedSide)
        }
    }

    func showManualFeedingInput() {
        let now = Date()
        manualSide = timerManager.feedingSelectedSide
        manualStartTime = now
        manualEndTime = now
        manualErrorMessage = ""
        showManualInput = true
    }

    func showBottleFeedingInput() {
        bottleTime = Date()
        bottleAmount = ""
        bottleErrorMessage = ""
        showBottleInput = true
    }

    func saveAndDismiss() {
        timerManager.finishFeeding()
        let totalDuration = timerManager.feedingLeftDuration + timerManager.feedingRightDuration
        guard totalDuration > 0 else { return }
        let totalMinutes = max(1, Int((totalDuration / 60).rounded(.up)))

        let side: String
        if timerManager.feedingHasRecordedLeft && timerManager.feedingHasRecordedRight {
            side = "双侧"
        } else if timerManager.feedingHasRecordedLeft {
            side = "左侧"
        } else {
            side = "右侧"
        }

        let record = RecordModel(type: .feeding, timestamp: feedingRecordTime, note: notes.isEmpty ? "\(side)喂奶\(totalMinutes > 0 ? " \(totalMinutes)分钟" : "")" : notes)
        RecordWorkflow.assignSelectedBaby(to: record, in: modelContext)
        record.breastSide = side
        if totalMinutes > 0 {
            record.feedingDurationMin = totalMinutes
        }
        modelContext.insert(record)
        RecordWorkflow.checkAchievements(in: modelContext)

        RecordWorkflow.scheduleReminders(in: modelContext)
        Task {
            await FamilySharingManager.shared.upload(record: record, context: modelContext)
        }
        timerManager.resetFeeding()
        feedingRecordTime = Date()
        dismiss()
    }

    var canSaveManualFeeding: Bool {
        manualEndTime > manualStartTime
    }

    var canSaveBottleFeeding: Bool {
        guard let amount = Int(bottleAmount) else { return false }
        return amount > 0 && bottleTime <= Date()
    }

    func saveManualFeedingInput() {
        manualErrorMessage = ""
        guard let minutes = manualBreastDurationMinutes else {
            manualErrorMessage = "结束时间必须晚于开始时间"
            return
        }

        let side = breastSides[manualSide]
        saveManualFeedingRecord(
            timestamp: manualStartTime,
            side: side,
            durationMinutes: minutes,
            amountML: nil,
            defaultNote: "\(side)亲喂 \(minutes)分钟"
        )
        let shouldDismissView = !timerManager.hasFeedingDuration && !timerManager.isFeedingRunning
        resetManualInput()
        showManualInput = false
        if shouldDismissView {
            dismiss()
        }
    }

    func saveBottleFeedingInput() {
        bottleErrorMessage = ""
        guard let amount = Int(bottleAmount), amount > 0 else {
            bottleErrorMessage = "请输入有效奶量"
            return
        }

        saveManualFeedingRecord(
            timestamp: bottleTime,
            side: "瓶喂",
            durationMinutes: nil,
            amountML: amount,
            defaultNote: "瓶喂母乳 \(amount)ml"
        )
        let shouldDismissView = !timerManager.hasFeedingDuration && !timerManager.isFeedingRunning
        resetBottleInput()
        showBottleInput = false
        if shouldDismissView {
            dismiss()
        }
    }

    func saveManualFeedingRecord(timestamp: Date, side: String, durationMinutes: Int?, amountML: Int?, defaultNote: String) {
        let record = RecordModel(type: .feeding, timestamp: timestamp, note: notes.isEmpty ? defaultNote : notes)
        RecordWorkflow.assignSelectedBaby(to: record, in: modelContext)
        record.breastSide = side
        record.feedingDurationMin = durationMinutes
        record.feedingAmountML = amountML
        modelContext.insert(record)
        RecordWorkflow.checkAchievements(in: modelContext)
        RecordWorkflow.scheduleReminders(in: modelContext)
        Task {
            await FamilySharingManager.shared.upload(record: record, context: modelContext)
        }
    }

    func resetManualInput() {
        let now = Date()
        manualSide = timerManager.feedingSelectedSide
        manualStartTime = now
        manualEndTime = now
        manualErrorMessage = ""
    }

    func resetBottleInput() {
        bottleTime = Date()
        bottleAmount = ""
        bottleErrorMessage = ""
    }

    var manualBreastDurationMinutes: Int? {
        guard manualEndTime > manualStartTime else { return nil }
        return max(1, Int((manualEndTime.timeIntervalSince(manualStartTime) / 60).rounded(.up)))
    }

    var manualBreastDurationText: String {
        guard let minutes = manualBreastDurationMinutes else { return "请选择有效时间" }
        return "\(minutes)分钟"
    }

    func sideDuration(_ index: Int) -> TimeInterval {
        let savedDuration = index == 0 ? timerManager.feedingLeftDuration : timerManager.feedingRightDuration
        let currentDuration = timerManager.feedingSelectedSide == index ? timerManager.feedingCurrentSideDuration : 0
        return savedDuration + currentDuration
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func formatDurationText(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes == 0 { return "\(seconds)秒" }
        return seconds > 0 ? "\(minutes)分\(seconds)秒" : "\(minutes)分钟"
    }

    func dateTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    FeedingTimerView()
}
