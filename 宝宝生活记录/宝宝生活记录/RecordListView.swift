import SwiftUI
import SwiftData

struct RecordListView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \RecordModel.timestamp, order: .reverse) var allRecords: [RecordModel]
    @Query var babyProfiles: [BabyProfile]
    @State private var babyManager = BabyManager.shared
    @State private var selectedFilter = 0
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var showRecordDetail = false
    @State private var selectedRecordType: RecordType = .feeding

    let filters = ["今日", "本周", "本月", "全部"]

    var babyProfile: BabyProfile? { babyManager.getSelectedBaby(from: babyProfiles) }

    var filteredRecords: [RecordModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        let filtered = babyManager.filterRecords(allRecords, for: babyProfile)
        switch selectedFilter {
        case 0:
            return filtered.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        case 1:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            return filtered.filter { $0.timestamp >= weekAgo && $0.timestamp <= calendar.date(byAdding: .day, value: 1, to: today)! }
        case 2:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
            return filtered.filter { $0.timestamp >= monthAgo && $0.timestamp <= calendar.date(byAdding: .day, value: 1, to: today)! }
        default:
            return filtered
        }
    }

    var feedingCount: Int { filteredRecords.filter { $0.recordType == .feeding }.count }
    var sleepCount: Int { filteredRecords.filter { $0.recordType == .sleep }.count }
    var diaperCount: Int { filteredRecords.filter { $0.recordType == .diaper || $0.recordType == .poop }.count }
    var poopCount: Int { filteredRecords.filter { $0.recordType == .poop }.count }
    var formulaCount: Int { filteredRecords.filter { $0.recordType == .formula }.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            filterBar

            if filteredRecords.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        summaryCards
                        analysisSection
                        chartSection
                        timelineList
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.background)
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .sheet(isPresented: $showRecordDetail) {
            RecordDetailView(recordType: selectedRecordType)
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color.outlineVariant)
            Text("暂无记录")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.onSurface)
            Text("该时间段内没有找到记录\n试试切换其他时间范围")
                .font(.system(size: 14))
                .foregroundColor(Color.outline)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("记录")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.onSurface)

                Text(filterSubtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color.outline)
            }

            Spacer()

            Button(action: { showDatePicker = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    Text(dateTitle)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primaryContainer.opacity(0.3))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    var filterSubtitle: String {
        let count = filteredRecords.count
        switch selectedFilter {
        case 0: return "今日 \(count) 条记录"
        case 1: return "本周 \(count) 条记录"
        case 2: return "本月 \(count) 条记录"
        default: return "共 \(count) 条记录"
        }
    }

    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<filters.count, id: \.self) { index in
                    Button(action: { selectedFilter = index }) {
                        Text(filters[index])
                            .font(.system(size: 14, weight: selectedFilter == index ? .bold : .medium))
                            .foregroundColor(selectedFilter == index ? Color.onPrimaryContainer : Color.onSurface)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(selectedFilter == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }

    var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SummaryCard(
                    icon: "figure.child.and.lock.fill",
                    title: "喂奶",
                    value: "\(feedingCount)",
                    unit: "次",
                    subtitle: formulaCount > 0 ? "含配方奶\(formulaCount)次" : "纯母乳",
                    color: Color.secondary
                )
                .onTapGesture {
                    selectedRecordType = .feeding
                    showRecordDetail = true
                }

                SummaryCard(
                    icon: "bed.double.fill",
                    title: "睡眠",
                    value: "\(sleepCount)",
                    unit: "次",
                    subtitle: sleepCount > 0 ? "详情查看记录" : "暂无记录",
                    color: Color.primaryDim
                )
                .onTapGesture {
                    selectedRecordType = .sleep
                    showRecordDetail = true
                }

                SummaryCard(
                    icon: "tshirt.fill",
                    title: "尿布",
                    value: "\(diaperCount)",
                    unit: "次",
                    subtitle: diaperCount > 0 ? "详情查看记录" : "暂无记录",
                    color: Color.onSurfaceVariant
                )
                .onTapGesture {
                    selectedRecordType = .diaper
                    showRecordDetail = true
                }

                SummaryCard(
                    icon: "allergens",
                    title: "大便",
                    value: "\(poopCount)",
                    unit: "次",
                    subtitle: poopCount > 0 ? "详情查看记录" : "暂无记录",
                    color: Color.secondary
                )
                .onTapGesture {
                    selectedRecordType = .poop
                    showRecordDetail = true
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }

    var analysisSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("智能分析")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if feedingCount >= 3 {
                        AnalysisCard(
                            icon: "arrow.up.right",
                            title: "喂奶频率正常",
                            detail: "今日喂奶\(feedingCount)次，间隔规律",
                            color: Color.secondary,
                            isPositive: true
                        )
                    }
                    if sleepCount >= 1 {
                        AnalysisCard(
                            icon: "moon.zzz.fill",
                            title: "睡眠记录良好",
                            detail: "今日睡眠\(sleepCount)次，注意保持规律",
                            color: Color.primaryDim,
                            isPositive: true
                        )
                    }
                    if formulaCount > 0 {
                        AnalysisCard(
                            icon: "drop.fill",
                            title: "配方奶补充",
                            detail: "今日配方奶\(formulaCount)次，注意奶量",
                            color: Color.tertiary,
                            isPositive: true
                        )
                    }
                    if diaperCount >= 4 {
                        AnalysisCard(
                            icon: "tshirt.fill",
                            title: "尿布更换频繁",
                            detail: "今日更换\(diaperCount)次，宝宝状态良好",
                            color: Color.onSurfaceVariant,
                            isPositive: true
                        )
                    }
                    if filteredRecords.isEmpty {
                        AnalysisCard(
                            icon: "info.circle",
                            title: "暂无分析数据",
                            detail: "该时间段内记录不足，无法生成分析",
                            color: Color.outline,
                            isPositive: true
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }

    var chartSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("本周趋势")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Spacer()
            }
            .padding(.horizontal, 20)

            VStack(spacing: 16) {
                FeedingChart(records: allRecords)
                SleepChart(records: allRecords)
                GrowthChartView(records: allRecords)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }

    var timelineList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("时间线")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Spacer()
                Text("\(filteredRecords.count) 条记录")
                    .font(.system(size: 13))
                    .foregroundColor(Color.outline)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            LazyVStack(spacing: 0) {
                ForEach(Array(filteredRecords.enumerated()), id: \.offset) { index, record in
                    timelineRow(record: record, isLast: index == filteredRecords.count - 1)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    func timelineRow(record: RecordModel, isLast: Bool) -> some View {
        let icon = iconName(for: record.recordType)
        let color = iconColor(for: record.recordType)

        return Button(action: {
            selectedRecordType = record.recordType
            showRecordDetail = true
        }) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(timeString(record.timestamp))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.onSurface)
                }
                .frame(width: 50)

                VStack(spacing: 0) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)

                    if !isLast {
                        Rectangle()
                            .fill(Color.outlineVariant.opacity(0.3))
                            .frame(width: 2, height: 40)
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                        .frame(width: 36, height: 36)
                        .background(color.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.recordType.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.onSurface)

                        Text(record.note)
                            .font(.system(size: 12))
                            .foregroundColor(Color.outline)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color.outlineVariant)
                }
                .padding(12)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.bottom, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    Button("取消") { showDatePicker = false }
                    Spacer()
                    Text("选择查询日期")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    Button("今天") { selectedDate = Date() }
                        .foregroundColor(Color.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                CalendarTimePicker(selectedDate: $selectedDate) {
                    selectedFilter = 0
                    showDatePicker = false
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color.background)
        }
    }

    var dateTitle: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "今天"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: selectedDate)
    }

    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func iconName(for type: RecordType) -> String {
        type.iconName
    }

    func iconColor(for type: RecordType) -> Color {
        switch type {
        case .feeding: return Color.secondary
        case .sleep: return Color.primaryDim
        case .diaper: return Color.onSurfaceVariant
        case .formula: return Color.secondary
        case .poop: return Color.secondary
        case .growth: return Color.tertiary
        case .vaccine: return Color(hex: "FF6B6B")
        case .babyFood: return Color(hex: "4ECDC4")
        case .pumping: return Color.secondary
        case .symptom: return Color.error
        case .headCircumference: return Color(hex: "96CEB4")
        case .tooth: return Color.primary
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.outline)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.onSurface)
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.outline)
            }

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(Color.outline)
        }
        .padding(16)
        .frame(width: 140)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: color.opacity(0.1), radius: 8, y: 2)
    }
}

struct AnalysisCard: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isPositive ? Color.tertiary : Color.error)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.onSurface)
            }

            Text(detail)
                .font(.system(size: 13))
                .foregroundColor(Color.outline)
                .lineLimit(2)
        }
        .padding(16)
        .frame(width: 260)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct FeedingChart: View {
    var records: [RecordModel]
    let labels = ["一", "二", "三", "四", "五", "六", "日"]
    let maxValue: CGFloat = 8

    var weeklyData: [CGFloat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let count = records.filter {
                $0.recordType == .feeding && calendar.isDate($0.timestamp, inSameDayAs: date)
            }.count
            return CGFloat(count)
        }
    }

    var average: String {
        let total = weeklyData.reduce(0, +)
        let avg = total / 7
        return String(format: "%.1f", avg)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "figure.child.and.lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.secondary)
                Text("喂奶次数")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.onSurface)
                Spacer()
                Text("平均 \(average)次/天")
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == 6 ? Color.secondary : Color.secondary.opacity(0.3))
                            .frame(height: weeklyData[index] / maxValue * 60)

                        Text(labels[index])
                            .font(.system(size: 10))
                            .foregroundColor(Color.outline)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct SleepChart: View {
    var records: [RecordModel]
    let labels = ["一", "二", "三", "四", "五", "六", "日"]
    let maxValue: CGFloat = 14

    var weeklyData: [CGFloat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayRecords = records.filter {
                $0.recordType == .sleep && calendar.isDate($0.timestamp, inSameDayAs: date)
            }
            var totalHours: CGFloat = 0
            for r in dayRecords {
                if let minutes = r.sleepDurationMinutes {
                    totalHours += CGFloat(minutes) / 60
                }
            }
            return totalHours
        }
    }

    var average: String {
        let total = weeklyData.reduce(0, +)
        let avg = total / 7
        return String(format: "%.1f", avg)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.primaryDim)
                Text("睡眠时长")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.onSurface)
                Spacer()
                Text("平均 \(average)小时/天")
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == 6 ? Color.primaryDim : Color.primaryDim.opacity(0.3))
                            .frame(height: weeklyData[index] / maxValue * 60)

                        Text(labels[index])
                            .font(.system(size: 10))
                            .foregroundColor(Color.outline)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    RecordListView()
}
