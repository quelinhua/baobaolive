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
    @State private var showMoreTypeFilters = false
    @State private var selectedRecord: RecordModel?
    @State private var addRecordType: RecordType?
    @State private var selectedTypeFilter: RecordType? = nil
    @State private var animateCards = false
    @State private var animateTimeline = false
    @State private var showCharts = false
    @Namespace private var namespace

    let filters = ["今天", "近7天", "本月", "全部"]
    let primaryTypeFilters: [RecordType?] = [nil, .feeding, .sleep, .diaper, .poop, .formula]
    let moreTypeFilters: [RecordType] = [.growth, .vaccine, .babyFood, .pumping, .symptom, .headCircumference, .tooth]

    var babyProfile: BabyProfile? { babyManager.getSelectedBaby(from: babyProfiles) }

    var babyRecords: [RecordModel] {
        babyManager.filterRecords(allRecords, for: babyProfile)
    }

    var timeFilteredRecords: [RecordModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        switch selectedFilter {
        case 0:
            return babyRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        case 1:
            let weekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            return babyRecords.filter { $0.timestamp >= weekAgo && $0.timestamp < tomorrow }
        case 2:
            let monthComponents = calendar.dateComponents([.year, .month], from: today)
            let monthStart = calendar.date(from: monthComponents) ?? today
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? calendar.date(byAdding: .day, value: 1, to: today)!
            return babyRecords.filter { $0.timestamp >= monthStart && $0.timestamp < nextMonth }
        default:
            return babyRecords
        }
    }

    var filteredRecords: [RecordModel] {
        guard let selectedTypeFilter else { return timeFilteredRecords }
        return timeFilteredRecords.filter { $0.recordType == selectedTypeFilter }
    }

    struct DayGroup: Identifiable {
        let id = UUID()
        let date: Date
        let records: [RecordModel]
        var feedingCount: Int { records.filter { $0.recordType == .feeding }.count }
        var sleepCount: Int { records.filter { $0.recordType == .sleep }.count }
        var sleepMinutes: Int { records.compactMap { $0.sleepDurationMinutes }.reduce(0, +) }
        var diaperCount: Int { records.filter { $0.recordType == .diaper }.count }
        var poopCount: Int { records.filter { $0.recordType == .poop }.count }
    }

    var groupedRecords: [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredRecords) { record in
            calendar.startOfDay(for: record.timestamp)
        }
        return grouped
            .map { DayGroup(date: $0.key, records: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            compactHeader

            if filteredRecords.isEmpty {
                emptyState
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        periodSummaryCard

                        chartsToggle

                        if showCharts {
                            chartsSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }

                        groupedTimeline
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .background(Color.background)
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .sheet(item: $selectedRecord) { record in
            RecordInfoView(record: record)
        }
        .sheet(item: $addRecordType) { type in
            AddRecordView(recordType: type)
        }
        .confirmationDialog("更多筛选", isPresented: $showMoreTypeFilters, titleVisibility: .visible) {
            ForEach(moreTypeFilters) { type in
                Button(type.displayName) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTypeFilter = type
                    }
                }
            }
            Button("显示全部类型") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedTypeFilter = nil
                }
            }
            Button("取消", role: .cancel) {}
        }
        .onChange(of: selectedFilter) { _, _ in
            resetTimelineAnimation()
        }
        .onChange(of: selectedTypeFilter) { _, _ in
            resetTimelineAnimation()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateTimeline = true
            }
        }
    }

    var compactHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("记录")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.onSurface)
                    Text(filterSubtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                        .contentTransition(.numericText())
                        .lineLimit(2)
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<filters.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = index
                            }
                        }) {
                            Text(filters[index])
                                .font(.system(size: 13, weight: selectedFilter == index ? .bold : .medium))
                                .foregroundColor(selectedFilter == index ? .white : Color.onSurface)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Group {
                                        if selectedFilter == index {
                                            Capsule()
                                                .fill(Color.primary)
                                                .matchedGeometryEffect(id: "filterCapsule", in: namespace)
                                        } else {
                                            Capsule()
                                                .fill(Color.surfaceContainerHighest)
                                        }
                                    }
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    Button(action: { showDatePicker = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                            Text(dateTitle)
                                .font(.system(size: 13, weight: .semibold))
                                .contentTransition(.numericText())
                        }
                        .foregroundColor(Color.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.primaryContainer.opacity(0.3))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            typeFilterBar
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color.background)
    }

    var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(primaryTypeFilters.indices, id: \.self) { index in
                    let type = primaryTypeFilters[index]
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedTypeFilter = type
                        }
                    }) {
                        HStack(spacing: 6) {
                            if let type {
                                Image(systemName: type.iconName)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            Text(type?.shortFilterName ?? "全部类型")
                                .font(.system(size: 12, weight: selectedTypeFilter == type ? .bold : .medium))
                        }
                        .foregroundColor(selectedTypeFilter == type ? Color.onPrimary : Color.onSurfaceVariant)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(selectedTypeFilter == type ? Color.primary : Color.surfaceContainerHighest)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel(type == nil ? "显示全部记录类型" : "只显示\(type!.displayName)")
                }

                Button(action: { showMoreTypeFilters = true }) {
                    HStack(spacing: 6) {
                        if let selectedTypeFilter, moreTypeFilters.contains(selectedTypeFilter) {
                            Image(systemName: selectedTypeFilter.iconName)
                                .font(.system(size: 12, weight: .semibold))
                            Text(selectedTypeFilter.shortFilterName)
                                .font(.system(size: 12, weight: .bold))
                        } else {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12, weight: .bold))
                            Text("更多")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(isMoreTypeSelected ? Color.onPrimary : Color.onSurfaceVariant)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(isMoreTypeSelected ? Color.primary : Color.surfaceContainerHighest)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("更多记录类型筛选")
            }
        }
    }

    var groupedTimeline: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(groupedRecords.enumerated()), id: \.element.id) { groupIndex, group in
                dayCard(group: group, groupIndex: groupIndex)
                    .opacity(animateTimeline ? 1 : 0)
                    .offset(y: animateTimeline ? 0 : 20)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(min(groupIndex, 5)) * 0.08),
                        value: animateTimeline
                    )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                animateTimeline = true
            }
        }
        .onChange(of: filteredRecords.count) { _, _ in
            resetTimelineAnimation()
        }
    }

    var periodSummaryCard: some View {
        let feeding = timeFilteredRecords.filter { $0.recordType == .feeding }.count
        let sleepMinutes = timeFilteredRecords.compactMap { $0.sleepDurationMinutes }.reduce(0, +)
        let diaper = timeFilteredRecords.filter { $0.recordType == .diaper }.count
        let poop = timeFilteredRecords.filter { $0.recordType == .poop }.count

        return HStack(spacing: 0) {
            summaryMetric(icon: RecordType.feeding.iconName, value: "\(feeding)", label: "喂奶", color: RecordType.feeding.iconColor)
            Divider().frame(height: 36)
            summaryMetric(icon: RecordType.sleep.iconName, value: sleepSummaryText(minutes: sleepMinutes), label: "睡眠", color: RecordType.sleep.iconColor)
            Divider().frame(height: 36)
            summaryMetric(icon: RecordType.diaper.iconName, value: "\(diaper)", label: "尿布", color: RecordType.diaper.iconColor)
            Divider().frame(height: 36)
            summaryMetric(icon: RecordType.poop.iconName, value: "\(poop)", label: "大便", color: RecordType.poop.iconColor)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 2)
    }

    func summaryMetric(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.outline)
        }
        .frame(maxWidth: .infinity)
    }

    func sleepSummaryText(minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)小时\(mins)分" : "\(hours)小时"
        }
        return "\(minutes)分"
    }

    func dayCard(group: DayGroup, groupIndex: Int) -> some View {
        VStack(spacing: 0) {
            dayHeader(group: group)

            VStack(spacing: 0) {
                ForEach(group.records, id: \.persistentModelID) { record in
                    recordRow(record: record, isLast: record.persistentModelID == group.records.last?.persistentModelID)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
        }
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }

    func dayHeader(group: DayGroup) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayTitle(group.date))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Text(daySubtitle(group))
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
            }

            Spacer()

            Text("\(group.records.count) 条")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primaryContainer.opacity(0.3))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.surfaceContainerLowest)
    }

    func recordRow(record: RecordModel, isLast: Bool) -> some View {
        let color = iconColor(for: record.recordType)

        return Button(action: {
            selectedRecord = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                selectedRecord = record
            }
        }) {
            HStack(spacing: 10) {
                Text(recordTimeText(record))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.outline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 74, alignment: .trailing)

                Image(systemName: record.recordType.iconName)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(recordHeadline(record))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.onSurface)
                        .lineLimit(1)

                    Text(recordSubtitle(record))
                        .font(.system(size: 11))
                        .foregroundColor(Color.outline)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.outlineVariant.opacity(0.4))
            }
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                if !isLast {
                    Divider()
                        .padding(.leading, 96)
                }
            }
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

    var chartsToggle: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showCharts.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.primary)

                Text("近7天趋势")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.onSurface)

                Spacer()

                Text(showCharts ? "收起" : "展开")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.primary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.primary)
                    .rotationEffect(.degrees(showCharts ? 180 : 0))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    var chartsSection: some View {
        VStack(spacing: 12) {
            FeedingChart(records: babyRecords)
            FormulaChart(records: babyRecords)
            DiaperChangeChart(records: babyRecords)
            GrowthChartView(records: babyRecords)
        }
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.primaryContainer.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateCards ? 1 : 0.8)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(Color.primary)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 6) {
                Text(emptyTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.onSurface)

                Text(emptyDescription)
                    .font(.system(size: 14))
                    .foregroundColor(Color.outline)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button(action: {
                    addRecordType = selectedTypeFilter ?? .feeding
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("添加\(selectedTypeFilter?.displayName ?? "记录")")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color.onPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: { resetFiltersForEmptyState() }) {
                    Text("查看全部记录")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.primaryContainer.opacity(0.35))
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
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
                    HStack(spacing: 14) {
                        Button("今天") { selectedDate = Date() }
                        Button("确定") {
                            selectedFilter = 0
                            showDatePicker = false
                        }
                        .fontWeight(.semibold)
                    }
                    .foregroundColor(Color.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                CalendarTimePicker(selectedDate: $selectedDate, showsConfirmButton: false) {
                    selectedFilter = 0
                    showDatePicker = false
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color.background)
        }
    }

    func resetTimelineAnimation() {
        animateTimeline = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animateTimeline = true
        }
    }

    var filterSubtitle: String {
        let count = filteredRecords.count
        let scopeText = filters.indices.contains(selectedFilter) ? filters[selectedFilter] : "全部"
        let typeText = selectedTypeFilter?.shortFilterName ?? "记录"
        let countText = "\(scopeText) \(count) 条\(typeText)"

        guard let latestRecord = filteredRecords.max(by: { $0.timestamp < $1.timestamp }) else {
            return countText
        }
        return "\(countText) · 最近一次 \(timeString(latestRecord.timestamp)) \(latestRecord.recordType.shortFilterName)"
    }

    var isMoreTypeSelected: Bool {
        guard let selectedTypeFilter else { return false }
        return moreTypeFilters.contains(selectedTypeFilter)
    }

    var emptyTitle: String {
        if let selectedTypeFilter {
            return "暂无\(selectedTypeFilter.displayName)"
        }
        return "暂无记录"
    }

    var emptyDescription: String {
        if selectedTypeFilter != nil {
            return "当前时间范围内没有这类记录\n可以换个范围，或现在补记一条"
        }
        return "当前时间范围内没有找到记录\n可以选择日期，或直接添加一条新记录"
    }

    func resetFiltersForEmptyState() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            selectedFilter = 3
            selectedTypeFilter = nil
        }
    }

    var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: selectedDate)
    }

    func dayTitle(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInYesterday(date) { return "昨天" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日 · EEEE"
        return formatter.string(from: date)
    }

    func daySubtitle(_ group: DayGroup) -> String {
        var parts: [String] = []
        if group.feedingCount > 0 { parts.append("喂奶\(group.feedingCount)次") }
        if group.sleepMinutes > 0 { parts.append("睡眠\(sleepSummaryText(minutes: group.sleepMinutes))") }
        if group.diaperCount > 0 { parts.append("尿布\(group.diaperCount)次") }
        if group.poopCount > 0 { parts.append("大便\(group.poopCount)次") }
        return parts.isEmpty ? "无记录" : parts.joined(separator: " · ")
    }

    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func iconColor(for type: RecordType) -> Color {
        type.iconColor
    }

    func recordTimeText(_ record: RecordModel) -> String {
        if record.recordType == .sleep, let endTime = record.sleepEndTime {
            return "\(timeString(record.timestamp))-\(timeString(endTime))"
        }
        if record.recordType == .feeding, let duration = record.feedingDurationMin {
            let endTime = record.timestamp.addingTimeInterval(TimeInterval(duration * 60))
            return "\(timeString(record.timestamp))-\(timeString(endTime))"
        }
        return timeString(record.timestamp)
    }

    func recordHeadline(_ record: RecordModel) -> String {
        switch record.recordType {
        case .feeding:
            return joinedRecordParts([
                record.breastSide,
                record.feedingDurationMin.map { "\($0)分钟" },
                record.feedingAmountML.map { "\($0)ml" }
            ], fallback: "母乳喂养")
        case .sleep:
            return record.sleepDurationText ?? "睡眠记录"
        case .diaper:
            return record.diaperType ?? "更换尿布"
        case .formula:
            return joinedRecordParts([
                record.formulaBrand,
                record.formulaAmountML.map { "\($0)ml" }
            ], fallback: "配方奶")
        case .poop:
            return joinedRecordParts([
                record.poopColor,
                record.poopTexture
            ], fallback: "大便记录")
        case .growth:
            return joinedRecordParts([
                record.heightCM.map { "身高\(String(format: "%.1f", $0))cm" },
                record.weightKG.map { "体重\(String(format: "%.1f", $0))kg" }
            ], fallback: "身高体重")
        case .vaccine:
            return record.vaccineName ?? "疫苗接种"
        case .babyFood:
            return joinedRecordParts([
                record.babyFoodName,
                record.babyFoodAmount,
                record.babyFoodReaction
            ], fallback: "辅食添加")
        case .pumping:
            return joinedRecordParts([
                record.pumpingSide,
                record.pumpingDurationMin.map { "\($0)分钟" },
                record.pumpingAmountML.map { "\($0)ml" }
            ], fallback: "吸奶记录")
        case .symptom:
            return joinedRecordParts([
                record.symptomType,
                record.symptomSeverity,
                record.temperature.map { "\(String(format: "%.1f", $0))°C" }
            ], fallback: "症状记录")
        case .headCircumference:
            return record.headCircumferenceCM.map { "头围\(String(format: "%.1f", $0))cm" } ?? "头围记录"
        case .tooth:
            return record.toothName ?? "出牙记录"
        }
    }

    func recordSubtitle(_ record: RecordModel) -> String {
        let note = record.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return record.recordType.shortFilterName }
        if note == record.displaySummary || note == recordHeadline(record) {
            return record.recordType.shortFilterName
        }
        return "\(record.recordType.shortFilterName) · \(note)"
    }

    func joinedRecordParts(_ parts: [String?], fallback: String) -> String {
        let cleanedParts = parts.compactMap { value -> String? in
            guard let value else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return cleanedParts.isEmpty ? fallback : cleanedParts.joined(separator: " · ")
    }
}

private extension RecordType {
    var shortFilterName: String {
        switch self {
        case .feeding: return "喂奶"
        case .sleep: return "睡眠"
        case .diaper: return "尿布"
        case .formula: return "奶粉"
        case .poop: return "大便"
        case .growth: return "成长"
        case .vaccine: return "疫苗"
        case .babyFood: return "辅食"
        case .pumping: return "吸奶"
        case .symptom: return "症状"
        case .headCircumference: return "头围"
        case .tooth: return "出牙"
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct FeedingChart: View {
    var records: [RecordModel]
    let labels = ["一", "二", "三", "四", "五", "六", "日"]
    let maxValue: CGFloat = 8
    @State private var animateChart = false

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
                Image(systemName: RecordType.feeding.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(RecordType.feeding.iconColor)
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
                            .frame(height: animateChart ? (min(weeklyData[index], maxValue) / maxValue * 60) : 0)

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
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateChart = true
            }
        }
    }
}

struct FormulaChart: View {
    var records: [RecordModel]
    let labels = ["一", "二", "三", "四", "五", "六", "日"]
    let maxValue: CGFloat = 8
    @State private var animateChart = false

    var weeklyData: [CGFloat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let count = records.filter {
                $0.recordType == .formula && calendar.isDate($0.timestamp, inSameDayAs: date)
            }.count
            return CGFloat(count)
        }
    }

    var totalAmount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        return records
            .filter { $0.recordType == .formula && $0.timestamp >= startDate && $0.timestamp < tomorrow }
            .compactMap(\.formulaAmountML)
            .reduce(0, +)
    }

    var average: String {
        let total = weeklyData.reduce(0, +)
        let avg = total / 7
        return String(format: "%.1f", avg)
    }

    var summaryText: String {
        if totalAmount > 0 {
            return "平均 \(average)次/天 · 共 \(totalAmount)ml"
        }
        return "平均 \(average)次/天"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: RecordType.formula.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(RecordType.formula.iconColor)
                Text("配方奶次数")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.onSurface)
                Spacer()
                Text(summaryText)
                    .font(.system(size: 12))
                    .foregroundColor(Color.outline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == 6 ? Color.secondary : Color.secondary.opacity(0.3))
                            .frame(height: animateChart ? (min(weeklyData[index], maxValue) / maxValue * 60) : 0)

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
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                animateChart = true
            }
        }
    }
}

struct DiaperChangeChart: View {
    var records: [RecordModel]
    let labels = ["一", "二", "三", "四", "五", "六", "日"]
    let maxValue: CGFloat = 10
    @State private var animateChart = false

    var weeklyData: [CGFloat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let count = records.filter {
                ($0.recordType == .diaper || $0.recordType == .poop)
                && calendar.isDate($0.timestamp, inSameDayAs: date)
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
                Image(systemName: RecordType.diaper.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(RecordType.diaper.iconColor)
                Text("换尿布次数")
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
                            .fill(index == 6 ? Color.onSurfaceVariant : Color.onSurfaceVariant.opacity(0.3))
                            .frame(height: animateChart ? (min(weeklyData[index], maxValue) / maxValue * 60) : 0)

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
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                animateChart = true
            }
        }
    }
}

#Preview {
    RecordListView()
}
