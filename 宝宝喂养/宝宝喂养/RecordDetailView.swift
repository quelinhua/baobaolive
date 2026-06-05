import SwiftUI
import SwiftData

struct DayGroup: Identifiable {
    let id = UUID()
    let date: Date
    let records: [RecordModel]

    var count: Int { records.count }

    func totalValue(for type: RecordType) -> String {
        switch type {
        case .formula:
            let total = records.compactMap { $0.formulaAmountML }.reduce(0, +)
            return total > 0 ? "\(total)ml" : ""
        case .feeding:
            let totalMin = records.compactMap { $0.feedingDurationMin }.reduce(0, +)
            let totalML = records.compactMap { $0.feedingAmountML }.reduce(0, +)
            if totalMin > 0 { return "\(totalMin)min" }
            if totalML > 0 { return "\(totalML)ml" }
            return ""
        case .sleep:
            let total = records.compactMap { $0.sleepDurationMinutes }.reduce(0, +)
            let h = total / 60
            let m = total % 60
            return h > 0 ? "\(h)h\(m)m" : "\(m)m"
        case .pumping:
            let total = records.compactMap { $0.pumpingAmountML }.reduce(0, +)
            return total > 0 ? "\(total)ml" : ""
        case .growth:
            if let lastRecord = records.sorted(by: { $0.timestamp > $1.timestamp }).first {
                var parts: [String] = []
                if let h = lastRecord.heightCM { parts.append("\(String(format: "%.1f", h))cm") }
                if let w = lastRecord.weightKG { parts.append("\(String(format: "%.1f", w))kg") }
                return parts.joined(separator: " ")
            }
            return ""
        default:
            return ""
        }
    }
}

struct RecordDetailView: View {
    let recordType: RecordType
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \RecordModel.timestamp, order: .reverse) var allRecords: [RecordModel]
    @Query var babyProfiles: [BabyProfile]
    @State private var babyManager = BabyManager.shared
    @State private var selectedSegment = 0
    @State private var previousSegment = 0
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showAddRecord = false
    @State private var selectedRecord: RecordModel?
    @State private var animateList = false
    let segments = ["今天", "昨天", "近七天", "全部", "日期"]

    var babyProfile: BabyProfile? { babyManager.getSelectedBaby(from: babyProfiles) }

    var filteredRecords: [RecordModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let filtered = babyManager.filterRecords(allRecords, for: babyProfile).filter { $0.recordType == recordType }

        switch selectedSegment {
        case 0:
            return filtered.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        case 1:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            return filtered.filter { calendar.isDate($0.timestamp, inSameDayAs: yesterday) }
        case 2:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            return filtered.filter { $0.timestamp >= weekAgo }
        case 3:
            return filtered
        default:
            let day = calendar.startOfDay(for: selectedDate)
            return filtered.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
        }
    }

    var groupedRecords: [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { record in
            calendar.startOfDay(for: record.timestamp)
        }
        return grouped.map { DayGroup(date: $0.key, records: $0.value.sorted { $0.timestamp > $1.timestamp }) }
                      .sorted { $0.date > $1.date }
    }

    var isShowingHistory: Bool { selectedSegment >= 2 }

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    segmentBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 6)

                    if selectedSegment == 4 {
                        dateFilterBar
                            .padding(.horizontal, 16)
                            .padding(.bottom, 6)
                    }

                    if isShowingHistory && filteredRecords.count >= 2 && groupedRecords.count > 1 {
                        summaryLine
                            .padding(.horizontal, 16)
                            .padding(.bottom, 6)
                    }

                    if filteredRecords.isEmpty {
                        emptyState
                    } else {
                        recordList
                    }

                    Spacer(minLength: 0)

                    addRecordButton
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.background)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedSegment) { _, newValue in
                if newValue == 4 {
                    showDatePicker = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: recordType.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(Color.primary)
                        Text(recordType.displayName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color.onSurface)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        RecordTimelineStatsView(recordType: recordType)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "timeline.selection")
                                .font(.system(size: 15, weight: .semibold))
                            Text("时间轴")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color.primary)
                    }
                    .accessibilityLabel("查看\(recordType.displayName)时间轴统计")
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

    var segmentBar: some View {
        HStack(spacing: 0) {
            ForEach(segments, id: \.self) { title in
                let index = segments.firstIndex(of: title)!
                Button(action: {
                    if index == 4 {
                        previousSegment = selectedSegment
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSegment = index
                    }
                    resetListAnimation()
                }) {
                    Text(title)
                        .font(.system(size: 14, weight: selectedSegment == index ? .bold : .medium))
                        .foregroundColor(selectedSegment == index ? .white : Color.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedSegment == index ? Color.primary : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(3)
        .background(Color.surfaceContainerHighest)
        .clipShape(Capsule())
    }

    var dateFilterBar: some View {
        Button(action: { showDatePicker = true }) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 13))
                Text(dateTitle)
                    .font(.system(size: 14, weight: .medium))
                    .contentTransition(.numericText())
                Spacer()
                Text("\(filteredRecords.count) 条")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.primary)
            }
            .foregroundColor(Color.onSurface)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    var summaryLine: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("\(groupedRecords.count)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.onSurface)
                    .contentTransition(.numericText())
                Text("天")
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
            }

            Divider().frame(height: 14)

            HStack(spacing: 4) {
                Text("\(filteredRecords.count)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.onSurface)
                    .contentTransition(.numericText())
                Text("次")
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
            }

            Divider().frame(height: 14)

            HStack(spacing: 4) {
                Text("平均间隔")
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
                Text(averageInterval)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.primary)
                Text("小时")
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    var recordList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(groupedRecords.enumerated()), id: \.element.id) { groupIndex, group in
                    daySection(group, groupIndex: groupIndex)
                        .opacity(animateList ? 1 : 0)
                        .offset(y: animateList ? 0 : 10)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7)
                                .delay(Double(min(groupIndex, 5)) * 0.05),
                            value: animateList
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateList = true
            }
        }
    }

    func daySection(_ group: DayGroup, groupIndex: Int) -> some View {
        VStack(spacing: 8) {
            // 日期头部
            dayHeader(group)

            // 记录卡片列表
            VStack(spacing: 6) {
                ForEach(group.records, id: \.persistentModelID) { record in
                    recordRow(record: record, group: group)
                }
            }
        }
    }

    func dayHeader(_ group: DayGroup) -> some View {
        HStack(spacing: 12) {
            // 左侧色条
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.primary)
                .frame(width: 4, height: 20)

            // 日期标题
            Text(dayTitle(group.date))
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color.onSurface)

            Spacer()

            // 统计信息
            HStack(spacing: 12) {
                Text("\(group.count)次")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.outline)

                let total = group.totalValue(for: recordType)
                if !total.isEmpty {
                    Text(total)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.primary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func dayTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    func recordRow(record: RecordModel, group: DayGroup) -> some View {
        Button(action: {
            selectedRecord = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                selectedRecord = record
            }
        }) {
            HStack(spacing: 10) {
                Text(timeString(record.timestamp))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.onSurface)
                    .frame(width: 50, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(record.displaySummary)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.onSurface)
                        .lineLimit(1)

                    if !record.note.isEmpty && record.note != record.displaySummary {
                        Text(record.note)
                            .font(.system(size: 11))
                            .foregroundColor(Color.outline)
                            .lineLimit(1)
                    }
                }

                Spacer()

                recordTrailingValue(record)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(ScaleButtonStyle())
        .contextMenu {
            Button(action: {
                selectedRecord = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    selectedRecord = record
                }
            }) {
                Label("查看详情", systemImage: "eye")
            }

            if record.babyProfile?.isFamilyOwner != false {
                Divider()
                Button(role: .destructive, action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        modelContext.delete(record)
                    }
                }) {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }

    func intervalView(_ current: RecordModel, _ next: RecordModel) -> some View {
        let interval = current.timestamp.timeIntervalSince(next.timestamp)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let text = hours > 0 ? "间隔 \(hours)小时\(minutes)分钟" : "间隔 \(minutes)分钟"

        return HStack(spacing: 8) {
            Spacer().frame(width: 45)
            Rectangle()
                .fill(Color.outlineVariant.opacity(0.15))
                .frame(width: 1.5, height: 18)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(Color.outline)
            Spacer()
        }
    }

    @ViewBuilder
    func recordTrailingValue(_ record: RecordModel) -> some View {
        EmptyView()
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text")
                .font(.system(size: 36))
                .foregroundColor(Color.outlineVariant)

            Text("暂无\(recordType.displayName)记录")
                .font(.system(size: 15))
                .foregroundColor(Color.outline)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    var addRecordButton: some View {
        Button(action: { showAddRecord = true }) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                Text("添加\(recordType.displayName)")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.primary.opacity(0.3), radius: 6, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    Button("取消") {
                        showDatePicker = false
                        selectedSegment = previousSegment
                    }
                    Spacer()
                    Text("选择日期")
                        .font(.system(size: 17, weight: .bold))
                    Spacer()
                    Button("确定") { showDatePicker = false }
                        .foregroundColor(Color.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                CalendarTimePicker(selectedDate: $selectedDate, showsConfirmButton: false) {
                    showDatePicker = false
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color.background)
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

    var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: selectedDate)
    }

    func resetListAnimation() {
        animateList = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animateList = true
        }
    }

    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

#Preview {
    RecordDetailView(recordType: .formula)
}
