import SwiftUI
import SwiftData

struct RecordTimelineStatsView: View {
    let recordType: RecordType

    @Query(sort: \RecordModel.timestamp, order: .reverse) private var allRecords: [RecordModel]
    @Query private var babyProfiles: [BabyProfile]
    @State private var babyManager = BabyManager.shared
    @State private var selectedRange = TimelineRange.all
    @State private var selectedRecord: RecordModel?

    private var babyProfile: BabyProfile? {
        babyManager.getSelectedBaby(from: babyProfiles)
    }

    private var recordsForType: [RecordModel] {
        babyManager
            .filterRecords(allRecords, for: babyProfile)
            .filter { $0.recordType == recordType }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var visibleRecords: [RecordModel] {
        guard let startDate = selectedRange.startDate else { return recordsForType }
        return recordsForType.filter { $0.timestamp >= startDate }
    }

    private var todayRecords: [RecordModel] {
        let calendar = Calendar.current
        return recordsForType.filter { calendar.isDateInToday($0.timestamp) }
    }

    private var recent24HourRecords: [RecordModel] {
        let start = Date().addingTimeInterval(-24 * 60 * 60)
        return recordsForType.filter { $0.timestamp >= start }
    }

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                rangePicker
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                ScrollView {
                    VStack(spacing: 16) {
                        overviewCard

                        if visibleRecords.isEmpty {
                            emptyState
                                .padding(.top, 48)
                        } else {
                            timelineSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("时间轴统计")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.onSurface)
            }
        }
        .sheet(item: $selectedRecord) { record in
            RecordInfoView(record: record)
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimelineRange.allCases) { range in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedRange = range
                    }
                } label: {
                    Text(range.title)
                        .font(.system(size: 14, weight: selectedRange == range ? .bold : .medium))
                        .foregroundColor(selectedRange == range ? .white : Color.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedRange == range ? Color.primary : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(3)
        .background(Color.surfaceContainerHighest)
        .clipShape(Capsule())
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: recordType.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.primary)
                    .frame(width: 42, height: 42)
                    .background(Color.primaryContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 3) {
                    Text(recordType.displayName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.onSurface)

                    Text(summarySubtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.outline)
                        .lineLimit(1)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                TimelineMetricTile(title: "今日", value: "\(todayRecords.count)", unit: "次", color: Color.primary)
                TimelineMetricTile(title: "24小时", value: "\(recent24HourRecords.count)", unit: "次", color: Color.primary)
                TimelineMetricTile(title: "平均间隔", value: averageIntervalText, unit: "", color: Color.primary)
            }

            if !rangeTotalText.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.primary)
                    Text(rangeTotalText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.onSurfaceVariant)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.primaryContainer)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("记录时间轴")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.onSurface)
                Spacer()
                Text("\(visibleRecords.count)条")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.outline)
            }

            VStack(spacing: 0) {
                nowMarker

                ForEach(Array(visibleRecords.enumerated()), id: \.element.persistentModelID) { index, record in
                    timelineRow(record: record, index: index)
                }
            }
        }
    }

    private var nowMarker: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("现在")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color.onSurface)
                .frame(width: 58, alignment: .trailing)

            VStack(spacing: 0) {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.outlineVariant.opacity(0.35))
                    .frame(width: 1)
                    .frame(height: 22)
            }
            .frame(width: 18)

            Spacer()
        }
        .padding(.bottom, 4)
    }

    private func timelineRow(record: RecordModel, index: Int) -> some View {
        let previousDate = index == 0 ? Date() : visibleRecords[index - 1].timestamp
        let isLast = index == visibleRecords.count - 1

        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeText(record.timestamp))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.onSurface)

                Text(shortDateText(record.timestamp))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outline)
            }
            .frame(width: 58, alignment: .trailing)
            .padding(.top, 27)

            VStack(spacing: 0) {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 34)

                if !isLast {
                    Rectangle()
                        .fill(Color.outlineVariant.opacity(0.35))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 18)

            VStack(alignment: .leading, spacing: 8) {
                intervalLabel(from: previousDate, to: record.timestamp, isFirst: index == 0)

                Button {
                    selectedRecord = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        selectedRecord = record
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: recordType.iconName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.primary)
                            .frame(width: 30, height: 30)
                            .background(Color.primaryContainer)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(recordType.displayName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.onSurface)

                            Text(timelineSummary(for: record))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.outline)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.outlineVariant)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.035), radius: 8, y: 3)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
    }

    private func intervalLabel(from previousDate: Date, to currentDate: Date, isFirst: Bool) -> some View {
        let interval = max(previousDate.timeIntervalSince(currentDate), 0)
        let text = intervalText(interval, isFirst: isFirst)
        let isLongGap = interval > 30 * 24 * 60 * 60

        return HStack(spacing: 6) {
            Image(systemName: isLongGap ? "calendar.badge.exclamationmark" : "clock")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isLongGap ? Color.outline : Color.primary)

            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isLongGap ? Color.outline : Color.onSurface)
                .lineLimit(1)

            Spacer()
        }
        .padding(.top, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "timeline.selection")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(Color.outlineVariant)

            Text("暂无\(recordType.displayName)时间轴")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.onSurface)

            Text("新增记录后，这里会自动整理每次记录和间隔。")
                .font(.system(size: 13))
                .foregroundColor(Color.outline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var summarySubtitle: String {
        if visibleRecords.isEmpty {
            return "\(selectedRange.title)暂无记录"
        }
        return "\(selectedRange.title) · \(visibleRecords.count)条记录"
    }

    private var averageIntervalText: String {
        guard recordsForType.count >= 2 else { return "--" }
        let sorted = recordsForType.sorted { $0.timestamp < $1.timestamp }
        let total = zip(sorted.dropFirst(), sorted).reduce(TimeInterval(0)) { partial, pair in
            partial + pair.0.timestamp.timeIntervalSince(pair.1.timestamp)
        }
        return shortDurationText(total / Double(sorted.count - 1))
    }

    private var rangeTotalText: String {
        switch recordType {
        case .formula:
            let total = visibleRecords.compactMap(\.formulaAmountML).reduce(0, +)
            return total > 0 ? "\(selectedRange.title)配方奶共 \(total) ml" : ""
        case .feeding:
            let totalMinutes = visibleRecords.compactMap(\.feedingDurationMin).reduce(0, +)
            let totalAmount = visibleRecords.compactMap(\.feedingAmountML).reduce(0, +)
            if totalMinutes > 0 { return "\(selectedRange.title)母乳亲喂共 \(totalMinutes) 分钟" }
            if totalAmount > 0 { return "\(selectedRange.title)母乳瓶喂共 \(totalAmount) ml" }
            return ""
        case .sleep:
            let total = visibleRecords.compactMap(\.sleepDurationMinutes).reduce(0, +)
            return total > 0 ? "\(selectedRange.title)睡眠共 \(durationText(minutes: total))" : ""
        case .pumping:
            let total = visibleRecords.compactMap(\.pumpingAmountML).reduce(0, +)
            return total > 0 ? "\(selectedRange.title)吸奶共 \(total) ml" : ""
        case .growth:
            guard let latest = visibleRecords.first else { return "" }
            return "最近一次：\(timelineSummary(for: latest))"
        case .headCircumference:
            guard let latest = visibleRecords.first else { return "" }
            return "最近一次：\(timelineSummary(for: latest))"
        default:
            return ""
        }
    }

    private func timelineSummary(for record: RecordModel) -> String {
        switch record.recordType {
        case .feeding:
            var parts: [String] = []
            if let side = record.breastSide { parts.append(side) }
            if let duration = record.feedingDurationMin { parts.append("\(duration) 分钟") }
            if let amount = record.feedingAmountML { parts.append("\(amount) ml") }
            return parts.isEmpty ? "母乳喂养" : parts.joined(separator: " · ")
        case .sleep:
            if let duration = record.sleepDurationMinutes {
                return durationText(minutes: duration)
            }
            return "睡眠记录"
        case .diaper:
            return record.diaperType ?? "小便记录"
        case .formula:
            var parts: [String] = []
            if let brand = record.formulaBrand, !brand.isEmpty { parts.append(brand) }
            if let amount = record.formulaAmountML { parts.append("\(amount) ml") }
            return parts.isEmpty ? "配方奶粉" : parts.joined(separator: " · ")
        case .poop:
            var parts: [String] = []
            if let color = record.poopColor { parts.append(color) }
            if let texture = record.poopTexture { parts.append(texture) }
            return parts.isEmpty ? "大便记录" : parts.joined(separator: " · ")
        case .growth:
            var parts: [String] = []
            if let height = record.heightCM { parts.append("身高 \(String(format: "%.1f", height)) cm") }
            if let weight = record.weightKG { parts.append("体重 \(String(format: "%.2f", weight)) kg") }
            return parts.isEmpty ? "身高体重" : parts.joined(separator: " · ")
        case .vaccine:
            return record.vaccineName ?? "疫苗接种"
        case .babyFood:
            var parts: [String] = []
            if let name = record.babyFoodName { parts.append(name) }
            if let amount = record.babyFoodAmount, !amount.isEmpty { parts.append(amount) }
            if let reaction = record.babyFoodReaction, !reaction.isEmpty { parts.append(reaction) }
            return parts.isEmpty ? "辅食添加" : parts.joined(separator: " · ")
        case .pumping:
            var parts: [String] = []
            if let side = record.pumpingSide { parts.append(side) }
            if let duration = record.pumpingDurationMin { parts.append("\(duration) 分钟") }
            if let amount = record.pumpingAmountML { parts.append("\(amount) ml") }
            return parts.isEmpty ? "吸奶记录" : parts.joined(separator: " · ")
        case .symptom:
            var parts: [String] = []
            if let type = record.symptomType { parts.append(type) }
            if let severity = record.symptomSeverity { parts.append(severity) }
            if let temp = record.temperature { parts.append("\(String(format: "%.1f", temp))°C") }
            return parts.isEmpty ? "症状记录" : parts.joined(separator: " · ")
        case .headCircumference:
            if let cm = record.headCircumferenceCM { return "头围 \(String(format: "%.1f", cm)) cm" }
            return "头围记录"
        case .tooth:
            return record.toothName ?? "出牙记录"
        }
    }

    private func intervalText(_ interval: TimeInterval, isFirst: Bool) -> String {
        if interval > 30 * 24 * 60 * 60 {
            return isFirst ? "暂无近期记录" : "暂无近期连续记录"
        }

        let prefix = isFirst ? "距现在" : "间隔"
        return "\(prefix) \(shortDurationText(interval))"
    }

    private func shortDurationText(_ interval: TimeInterval) -> String {
        let totalMinutes = max(Int(interval / 60), 0)
        if totalMinutes < 1 { return "刚刚" }

        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60

        if days > 0 && hours > 0 { return "\(days)天\(hours)小时" }
        if days > 0 { return "\(days)天" }
        if hours > 0 && minutes > 0 { return "\(hours)小时\(minutes)分钟" }
        if hours > 0 { return "\(hours)小时" }
        return "\(minutes)分钟"
    }

    private func durationText(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 { return "\(hours)小时\(mins)分钟" }
        if hours > 0 { return "\(hours)小时" }
        return "\(mins)分钟"
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func shortDateText(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInYesterday(date) { return "昨天" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = calendar.isDate(date, equalTo: Date(), toGranularity: .year) ? "MM月dd日" : "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}

private struct TimelineMetricTile: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.outline)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: value == "--" ? .default : .rounded))
                    .foregroundColor(Color.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.outline)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private enum TimelineRange: String, CaseIterable, Identifiable {
    case all
    case sevenDays
    case thirtyDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sevenDays: return "近七天"
        case .thirtyDays: return "近30天"
        case .all: return "全部"
        }
    }

    var startDate: Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch self {
        case .sevenDays:
            return calendar.date(byAdding: .day, value: -7, to: today)
        case .thirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: today)
        case .all:
            return nil
        }
    }
}

#Preview {
    NavigationView {
        RecordTimelineStatsView(recordType: .formula)
    }
}
