import SwiftUI
import SwiftData

struct RecordDetailView: View {
    let recordType: RecordType
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \RecordModel.timestamp, order: .reverse) var allRecords: [RecordModel]
    @Query var babyProfiles: [BabyProfile]
    @State private var babyManager = BabyManager.shared
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showAddRecord = false
    @State private var selectedRecord: RecordModel?

    var babyProfile: BabyProfile? { babyManager.getSelectedBaby(from: babyProfiles) }

    var filteredRecords: [RecordModel] {
        let calendar = Calendar.current
        let filtered = babyManager.filterRecords(allRecords, for: babyProfile)
        return filtered.filter {
            $0.recordType == recordType && calendar.isDate($0.timestamp, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            dateSelector
                            timeSinceLastRecord
                            statsCards
                            recordList
                        }
                        .padding(20)
                        .padding(.bottom, 100)
                    }

                    addRecordButton
                        .padding(20)
                        .background(Color.surface.opacity(0.8))
                        .background(.ultraThinMaterial)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(recordType.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showDatePicker = true }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundColor(Color.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddRecord) {
                AddRecordView(recordType: recordType)
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .sheet(item: $selectedRecord) { record in
                RecordInfoView(record: record)
            }
        }
    }

    var dateSelector: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { changeDate(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.primaryContainer.opacity(0.3))
                        .clipShape(Circle())
                }

                Spacer()

                Button(action: { showDatePicker = true }) {
                    VStack(spacing: 4) {
                        Text(dateTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.onSurface)

                        Text(dateSubtitle)
                            .font(.system(size: 12))
                            .foregroundColor(Color.outline)
                    }
                }

                Spacer()

                Button(action: { changeDate(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.primaryContainer.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack {
                Button("今天") {
                    selectedDate = Date()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isToday ? Color.onPrimaryContainer : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isToday ? Color.primaryContainer : Color.primaryContainer.opacity(0.3))
                .clipShape(Capsule())

                Spacer()

                Text("共 \(filteredRecords.count) 条记录")
                    .font(.system(size: 13))
                    .foregroundColor(Color.outline)
            }
        }
    }

    var timeSinceLastRecord: some View {
        let lastRecord = allRecords.filter { $0.recordType == recordType }.first
        let timeText: String = {
            guard let last = lastRecord else { return "暂无记录" }
            let interval = Date().timeIntervalSince(last.timestamp)
            if interval < 60 { return "刚刚" }
            if interval < 3600 { return "已过 \(Int(interval / 60))分钟" }
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return "已过 \(hours)小时\(minutes)分钟"
        }()

        return HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(size: 18))
                .foregroundColor(Color.primary)
                .frame(width: 40, height: 40)
                .background(Color.primaryContainer.opacity(0.3))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("距离上次\(recordType.displayName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.onSurfaceVariant)

                Text(timeText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.primary)
            }

            Spacer()

            Button(action: { showAddRecord = true }) {
                Text("立即记录")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.onPrimaryContainer)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primaryContainer)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
    }

    var statsCards: some View {
        HStack(spacing: 12) {
            statCard(
                icon: iconName,
                title: "今日次数",
                value: "\(filteredRecords.count)",
                unit: "次",
                color: iconColor
            )

            statCard(
                icon: "clock.arrow.circlepath",
                title: "平均间隔",
                value: averageInterval,
                unit: "小时",
                color: Color.primary
            )
        }
    }

    var averageInterval: String {
        guard filteredRecords.count >= 2 else { return "-" }
        let sorted = filteredRecords.sorted { $0.timestamp < $1.timestamp }
        var totalInterval: TimeInterval = 0
        for i in 1..<sorted.count {
            totalInterval += sorted[i].timestamp.timeIntervalSince(sorted[i-1].timestamp)
        }
        let avg = totalInterval / Double(sorted.count - 1) / 3600
        return String(format: "%.1f", avg)
    }

    func statCard(icon: String, title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.onSurface)
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.outline)
                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: color.opacity(0.1), radius: 8, y: 2)
    }

    var recordList: some View {
        VStack(spacing: 12) {
            HStack {
                Text("记录详情")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.onSurfaceVariant)
                Spacer()
            }

            if filteredRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(Color.outlineVariant)
                    Text("该日期暂无记录")
                        .font(.system(size: 14))
                        .foregroundColor(Color.outline)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(Array(filteredRecords.enumerated()), id: \.offset) { index, record in
                    recordRow(record: record, index: index, isLatest: index == 0)
                }
            }
        }
    }

    func recordRow(record: RecordModel, index: Int, isLatest: Bool) -> some View {
        Button(action: {
            selectedRecord = record
        }) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(timeString(record.timestamp))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isLatest ? Color.primary : Color.onSurface)

                    if recordType == .sleep, let durationText = record.sleepDurationText {
                        Text(durationText)
                            .font(.system(size: 11))
                            .foregroundColor(Color.outline)
                    } else if recordType == .feeding {
                        if let duration = record.feedingDurationMin {
                            Text("\(duration)分钟")
                                .font(.system(size: 11))
                                .foregroundColor(Color.outline)
                        } else if let amount = record.feedingAmountML {
                            Text("\(amount)ml")
                                .font(.system(size: 11))
                                .foregroundColor(Color.outline)
                        }
                    }
                }
                .frame(width: 60)

                VStack(spacing: 2) {
                    Circle()
                        .fill(isLatest ? Color.primary : Color.outlineVariant)
                        .frame(width: 12, height: 12)

                    if index < filteredRecords.count - 1 {
                        Rectangle()
                            .fill(Color.outlineVariant.opacity(0.3))
                            .frame(width: 2, height: 20)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(record.note)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.onSurface)
                            .lineLimit(1)

                        if isLatest {
                            Text("最新")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.onPrimaryContainer)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.primaryContainer)
                                .clipShape(Capsule())
                        }
                    }

                    if index < filteredRecords.count - 1 {
                        let prev = filteredRecords[index + 1]
                        Text("间隔 \(timeInterval(from: prev.timestamp, to: record.timestamp))")
                            .font(.system(size: 12))
                            .foregroundColor(Color.outline)
                    }
                }

                Spacer()

                if recordType == .formula, let amount = record.formulaAmountML {
                    Text("\(amount)ml")
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                } else if recordType == .growth {
                    if let h = record.heightCM {
                        Text("\(String(format: "%.1f", h))cm")
                            .font(.system(size: 13))
                            .foregroundColor(Color.outline)
                    } else if let w = record.weightKG {
                        Text("\(String(format: "%.1f", w))kg")
                            .font(.system(size: 13))
                            .foregroundColor(Color.outline)
                    }
                } else if recordType == .pumping, let amount = record.pumpingAmountML {
                    Text("\(amount)ml")
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                } else if recordType == .headCircumference, let cm = record.headCircumferenceCM {
                    Text("\(String(format: "%.1f", cm))cm")
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                } else if recordType == .symptom, let temp = record.temperature {
                    Text("\(String(format: "%.1f", temp))°C")
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.outlineVariant)
            }
            .padding(16)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }

    var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("选择查询日期")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.onSurface)
                    .padding(.top, 16)

                CalendarTimePicker(selectedDate: $selectedDate) {
                    showDatePicker = false
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showDatePicker = false
                    }
                }
            }
        }
    }

    var addRecordButton: some View {
        Button(action: { showAddRecord = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("添加\(recordType.displayName)")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(Color.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: Color.primary.opacity(0.3), radius: 8, y: 4)
        }
    }

    var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: selectedDate)
    }

    var dateSubtitle: String {
        if isToday { return "今天" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: selectedDate)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var iconName: String {
        switch recordType {
        case .feeding: return "figure.child.and.lock.fill"
        case .sleep: return "bed.double.fill"
        case .diaper: return "tshirt.fill"
        case .formula: return "waterbottle.fill"
        case .poop: return "allergens"
        case .growth: return "scalemass.fill"
        case .vaccine: return "syringe.fill"
        case .babyFood: return "fork.knife"
        case .pumping: return "drop.fill"
        case .symptom: return "heart.text.square.fill"
        case .headCircumference: return "brain.head.profile.fill"
        case .tooth: return "face.smiling.inverse"
        }
    }

    var iconColor: Color {
        recordType.iconColor
    }

    func changeDate(_ days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }

    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func timeInterval(from start: Date, to end: Date) -> String {
        let diff = Int(end.timeIntervalSince(start))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        }
        return "\(minutes)分钟"
    }
}

#Preview {
    RecordDetailView(recordType: .feeding)
}
