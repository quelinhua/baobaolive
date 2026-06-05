import SwiftUI
import UIKit

struct GrowthReportView: View {
    let records: [RecordModel]
    let babyProfile: BabyProfile?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: GrowthReportMode = .weekly
    @State private var shareItem: GrowthReportShareItem?
    @State private var exportErrorMessage: String?
    @State private var isExporting = false

    private var report: GrowthReportSummary {
        GrowthReportSummary(records: records, babyProfile: babyProfile, mode: selectedMode)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    reportHeader
                    modePicker
                    summaryHero
                    metricsGrid
                    trendSection
                    insightSection
                    latestRecordsSection
                    shareSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color.background)
            .navigationTitle("成长报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { shareTextReport() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("分享成长报告")
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: item.items)
            }
            .alert("导出失败", isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { if !$0 { exportErrorMessage = nil } }
            )) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(exportErrorMessage ?? "")
            }
        }
    }

    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(report.babyName)的\(selectedMode.title)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(report.rangeText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.onSurfaceVariant)
                }

                Spacer()

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(Color(hex: "6B4208"))
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFE8A3"), Color(hex: "F8D68B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Text("根据本机记录自动整理，可用于家庭复盘和就医沟通。")
                .font(.system(size: 13))
                .foregroundColor(Color.outline)
                .lineLimit(2)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color.surfaceContainerLowest,
                    Color(hex: "FFF9EA")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "F8D68B").opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color(hex: "C98924").opacity(0.12), radius: 10, y: 4)
    }

    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(GrowthReportMode.allCases) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        selectedMode = mode
                    }
                }) {
                    Text(mode.title)
                        .font(.system(size: 14, weight: selectedMode == mode ? .bold : .medium))
                        .foregroundColor(selectedMode == mode ? Color.onPrimary : Color.onSurfaceVariant)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedMode == mode ? Color.primary : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(4)
        .background(Color.surfaceContainerHigh)
        .clipShape(Capsule())
    }

    private var summaryHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.summaryTitle)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(Color.onSurface)

                    Text(report.summarySubtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.onSurfaceVariant)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(report.totalRecords)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color.primary)
                        .contentTransition(.numericText())
                    Text("条记录")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.outline)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: report.deltaIcon)
                    .font(.system(size: 12, weight: .bold))
                Text(report.deltaText)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(report.deltaColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(report.deltaColor.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 2)
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            GrowthReportMetricCard(
                icon: RecordType.formula.iconName,
                title: "喂养",
                value: "\(report.totalFeedingCount)次",
                caption: report.feedingCaption,
                color: RecordType.formula.iconColor
            )
            GrowthReportMetricCard(
                icon: RecordType.sleep.iconName,
                title: "睡眠",
                value: report.sleepTotalText,
                caption: report.sleepCaption,
                color: RecordType.sleep.iconColor
            )
            GrowthReportMetricCard(
                icon: RecordType.diaper.iconName,
                title: "换尿布",
                value: "\(report.diaperTotalCount)次",
                caption: report.diaperCaption,
                color: RecordType.diaper.iconColor
            )
            GrowthReportMetricCard(
                icon: RecordType.growth.iconName,
                title: "成长",
                value: report.latestGrowthValue,
                caption: report.growthCaption,
                color: RecordType.growth.iconColor
            )
        }
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("记录趋势", systemImage: "chart.bar.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.onSurface)

                Spacer()

                Text(report.trendCaption)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outline)
                    .lineLimit(1)
            }

            GrowthReportBarChart(buckets: report.chartBuckets)
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 2)
    }

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("报告解读", systemImage: "sparkles")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color.onSurface)

            VStack(spacing: 10) {
                ForEach(Array(report.insights.enumerated()), id: \.offset) { index, text in
                    GrowthReportInsightRow(index: index + 1, text: text)
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 2)
    }

    private var latestRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("最近记录", systemImage: "clock.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.onSurface)

                Spacer()

                Text("本期")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryContainer.opacity(0.35))
                    .clipShape(Capsule())
            }

            if report.recentRecords.isEmpty {
                Text("本期暂无记录，添加喂养、睡眠、尿布或成长记录后会自动生成。")
                    .font(.system(size: 13))
                    .foregroundColor(Color.outline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 0) {
                    ForEach(report.recentRecords, id: \.persistentModelID) { record in
                        GrowthReportRecordRow(record: record)

                        if record.persistentModelID != report.recentRecords.last?.persistentModelID {
                            Divider()
                                .padding(.leading, 42)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 2)
    }

    private var shareSection: some View {
        VStack(spacing: 10) {
            Button(action: { exportReport(as: .pdf) }) {
                reportActionButtonContent(
                    title: isExporting ? "正在导出..." : "导出 PDF 报告",
                    icon: "doc.richtext.fill",
                    filled: true
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isExporting)

            HStack(spacing: 10) {
                Button(action: { exportReport(as: .image) }) {
                    reportActionButtonContent(title: "导出长图", icon: "photo.fill", filled: false)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isExporting)

                Button(action: { shareTextReport() }) {
                    reportActionButtonContent(title: "文字版", icon: "text.alignleft", filled: false)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private func reportActionButtonContent(title: String, icon: String, filled: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundColor(filled ? Color.onPrimary : Color.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(filled ? Color.primary : Color.primaryContainer.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: filled ? Color.primary.opacity(0.22) : Color.clear, radius: 8, y: 3)
    }

    private func shareTextReport() {
        shareItem = GrowthReportShareItem(items: [report.shareText])
    }

    @MainActor
    private func exportReport(as format: GrowthReportExportFormat) {
        isExporting = true
        defer { isExporting = false }

        guard let image = renderReportImage() else {
            exportErrorMessage = "暂时无法生成报告图片，请稍后再试。"
            return
        }

        let fileName = "\(safeFileName(report.babyName))-\(selectedMode.title)-\(report.fileDateText)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName).appendingPathExtension(format.fileExtension)

        do {
            switch format {
            case .pdf:
                try writePDF(image: image, to: url)
            case .image:
                guard let data = image.pngData() else {
                    throw GrowthReportExportError.imageEncodingFailed
                }
                try data.write(to: url, options: .atomic)
            }

            shareItem = GrowthReportShareItem(items: [url])
        } catch {
            exportErrorMessage = "文件生成失败，请稍后再试。"
        }
    }

    @MainActor
    private func renderReportImage() -> UIImage? {
        let width: CGFloat = 390
        let content = GrowthReportExportPage(report: report, mode: selectedMode)
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        return renderer.uiImage
    }

    private func writePDF(image: UIImage, to url: URL) throws {
        let pageWidth: CGFloat = 595
        let pageHeight = pageWidth * image.size.height / image.size.width
        let bounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            image.draw(in: bounds)
        }
    }

    private func safeFileName(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return value.components(separatedBy: invalid).joined(separator: "-")
    }
}

private struct GrowthReportShareItem: Identifiable {
    let id = UUID()
    let items: [Any]
}

private enum GrowthReportExportFormat {
    case pdf
    case image

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .image: return "png"
        }
    }
}

private enum GrowthReportExportError: Error {
    case imageEncodingFailed
}

private struct GrowthReportExportPage: View {
    let report: GrowthReportSummary
    let mode: GrowthReportMode

    var body: some View {
        VStack(spacing: 16) {
            exportHeader
            summaryHero
            metricsGrid
            trendSection
            insightSection
            latestRecordsSection
            exportFooter
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(Color.background)
    }

    private var exportHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(report.babyName)的\(mode.title)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(report.rangeText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.onSurfaceVariant)
                }

                Spacer()

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(Color(hex: "6B4208"))
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFE8A3"), Color(hex: "F8D68B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Text("根据本机记录自动整理，可用于家庭复盘和就医沟通。")
                .font(.system(size: 13))
                .foregroundColor(Color.outline)
                .lineLimit(2)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color.surfaceContainerLowest,
                    Color(hex: "FFF9EA")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "F8D68B").opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color(hex: "C98924").opacity(0.12), radius: 10, y: 4)
    }

    private var summaryHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.summaryTitle)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(Color.onSurface)

                    Text(report.summarySubtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color.onSurfaceVariant)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(report.totalRecords)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color.primary)
                    Text("条记录")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.outline)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: report.deltaIcon)
                    .font(.system(size: 12, weight: .bold))
                Text(report.deltaText)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(report.deltaColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(report.deltaColor.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 2)
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            GrowthReportMetricCard(
                icon: RecordType.formula.iconName,
                title: "喂养",
                value: "\(report.totalFeedingCount)次",
                caption: report.feedingCaption,
                color: RecordType.formula.iconColor
            )
            GrowthReportMetricCard(
                icon: RecordType.sleep.iconName,
                title: "睡眠",
                value: report.sleepTotalText,
                caption: report.sleepCaption,
                color: RecordType.sleep.iconColor
            )
            GrowthReportMetricCard(
                icon: RecordType.diaper.iconName,
                title: "换尿布",
                value: "\(report.diaperTotalCount)次",
                caption: report.diaperCaption,
                color: RecordType.diaper.iconColor
            )
            GrowthReportMetricCard(
                icon: RecordType.growth.iconName,
                title: "成长",
                value: report.latestGrowthValue,
                caption: report.growthCaption,
                color: RecordType.growth.iconColor
            )
        }
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("记录趋势", systemImage: "chart.bar.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.onSurface)

                Spacer()

                Text(report.trendCaption)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outline)
                    .lineLimit(1)
            }

            GrowthReportBarChart(buckets: report.chartBuckets, animated: false)
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 2)
    }

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("报告解读", systemImage: "sparkles")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color.onSurface)

            VStack(spacing: 10) {
                ForEach(Array(report.insights.enumerated()), id: \.offset) { index, text in
                    GrowthReportInsightRow(index: index + 1, text: text)
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 2)
    }

    private var latestRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("最近记录", systemImage: "clock.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.onSurface)

                Spacer()

                Text("本期")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primaryContainer.opacity(0.35))
                    .clipShape(Capsule())
            }

            if report.recentRecords.isEmpty {
                Text("本期暂无记录，添加喂养、睡眠、尿布或成长记录后会自动生成。")
                    .font(.system(size: 13))
                    .foregroundColor(Color.outline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(spacing: 0) {
                    ForEach(report.recentRecords, id: \.persistentModelID) { record in
                        GrowthReportRecordRow(record: record)

                        if record.persistentModelID != report.recentRecords.last?.persistentModelID {
                            Divider()
                                .padding(.leading, 42)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 2)
    }

    private var exportFooter: some View {
        Text("由宝宝记录自动生成 · \(report.generatedAtText)")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color.outline)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }
}

private enum GrowthReportMode: CaseIterable, Identifiable {
    case weekly
    case monthly

    var id: Self { self }

    var title: String {
        switch self {
        case .weekly: return "周报"
        case .monthly: return "月报"
        }
    }

    var summaryName: String {
        switch self {
        case .weekly: return "本周"
        case .monthly: return "本月"
        }
    }
}

private struct GrowthReportSummary {
    let records: [RecordModel]
    let babyProfile: BabyProfile?
    let mode: GrowthReportMode
    let periodStart: Date
    let periodEnd: Date
    let activeEnd: Date
    let previousStart: Date
    let previousEnd: Date

    private let calendar = Calendar.current

    init(records: [RecordModel], babyProfile: BabyProfile?, mode: GrowthReportMode) {
        self.records = records
        self.babyProfile = babyProfile
        self.mode = mode

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()

        switch mode {
        case .weekly:
            let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            self.periodStart = start
            self.periodEnd = tomorrow
            self.activeEnd = tomorrow
            self.previousStart = calendar.date(byAdding: .day, value: -7, to: start) ?? start
            self.previousEnd = start
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: today)
            let start = calendar.date(from: components) ?? today
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: start) ?? tomorrow
            let activeEnd = min(nextMonth, tomorrow)
            let previousStart = calendar.date(byAdding: .month, value: -1, to: start) ?? start
            let elapsedDays = max(calendar.dateComponents([.day], from: start, to: activeEnd).day ?? 1, 1)
            let comparablePreviousEnd = min(start, calendar.date(byAdding: .day, value: elapsedDays, to: previousStart) ?? start)

            self.periodStart = start
            self.periodEnd = nextMonth
            self.activeEnd = activeEnd
            self.previousStart = previousStart
            self.previousEnd = comparablePreviousEnd
        }
    }

    var babyName: String {
        babyProfile?.name ?? "宝宝"
    }

    var periodRecords: [RecordModel] {
        records
            .filter { $0.timestamp >= periodStart && $0.timestamp < periodEnd }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var previousRecords: [RecordModel] {
        records.filter { $0.timestamp >= previousStart && $0.timestamp < previousEnd }
    }

    var recentRecords: [RecordModel] {
        Array(periodRecords.prefix(5))
    }

    var totalRecords: Int {
        periodRecords.count
    }

    var totalFeedingCount: Int {
        feedingCount + formulaCount
    }

    var feedingCount: Int {
        periodRecords.filter { $0.recordType == .feeding }.count
    }

    var feedingMinutes: Int {
        periodRecords.compactMap(\.feedingDurationMin).reduce(0, +)
    }

    var formulaCount: Int {
        periodRecords.filter { $0.recordType == .formula }.count
    }

    var formulaAmount: Int {
        periodRecords.compactMap(\.formulaAmountML).reduce(0, +)
    }

    var sleepCount: Int {
        periodRecords.filter { $0.recordType == .sleep }.count
    }

    var sleepMinutes: Int {
        periodRecords.compactMap(\.sleepDurationMinutes).reduce(0, +)
    }

    var peeCount: Int {
        periodRecords.filter { $0.recordType == .diaper }.count
    }

    var poopCount: Int {
        periodRecords.filter { $0.recordType == .poop }.count
    }

    var diaperTotalCount: Int {
        peeCount + poopCount
    }

    var growthRecords: [RecordModel] {
        records
            .filter {
                ($0.recordType == .growth || $0.recordType == .headCircumference) && $0.timestamp < periodEnd
            }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var latestGrowthRecord: RecordModel? {
        growthRecords.first
    }

    var activeDayCount: Int {
        max(calendar.dateComponents([.day], from: periodStart, to: activeEnd).day ?? 1, 1)
    }

    var rangeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy年M月d日"

        let endDate = calendar.date(byAdding: .day, value: -1, to: activeEnd) ?? Date()
        return "\(formatter.string(from: periodStart)) - \(formatter.string(from: endDate))"
    }

    var fileDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    var generatedAtText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: Date())
    }

    var summaryTitle: String {
        if totalRecords == 0 {
            return "\(mode.summaryName)还没有记录"
        }
        return "\(mode.summaryName)整理了 \(totalRecords) 条记录"
    }

    var summarySubtitle: String {
        guard totalRecords > 0 else {
            return "添加记录后，这里会自动生成喂养、睡眠、尿布和成长总结。"
        }

        let trackedCount = totalFeedingCount + sleepCount + diaperTotalCount + periodRecords.filter { $0.recordType == .growth || $0.recordType == .headCircumference }.count
        let otherCount = max(totalRecords - trackedCount, 0)
        let groups: [(String, Int)] = [
            ("喂养", totalFeedingCount),
            ("睡眠", sleepCount),
            ("换尿布", diaperTotalCount),
            ("成长", periodRecords.filter { $0.recordType == .growth || $0.recordType == .headCircumference }.count),
            ("其他", otherCount)
        ]
        let dominant = groups.max { $0.1 < $1.1 } ?? ("日常", totalRecords)
        return "\(dominant.0)记录最多，继续保持连续记录会让趋势更清晰。"
    }

    var deltaText: String {
        let previous = previousRecords.count
        let delta = totalRecords - previous

        if previous == 0 && totalRecords == 0 {
            return "暂无可对比数据"
        }
        if previous == 0 {
            return "比上个周期多 \(totalRecords) 条"
        }
        if delta > 0 {
            return "比上个周期多 \(delta) 条"
        }
        if delta < 0 {
            return "比上个周期少 \(abs(delta)) 条"
        }
        return "和上个周期持平"
    }

    var deltaIcon: String {
        let delta = totalRecords - previousRecords.count
        if delta > 0 { return "arrow.up.right" }
        if delta < 0 { return "arrow.down.right" }
        return "minus"
    }

    var deltaColor: Color {
        let delta = totalRecords - previousRecords.count
        if delta > 0 { return Color.tertiary }
        if delta < 0 { return Color.secondary }
        return Color.onSurfaceVariant
    }

    var feedingCaption: String {
        var parts: [String] = []
        if feedingCount > 0 { parts.append("母乳 \(feedingCount)次") }
        if feedingMinutes > 0 { parts.append("\(feedingMinutes)分钟") }
        if formulaAmount > 0 { parts.append("奶粉 \(formulaAmount)ml") }
        return parts.isEmpty ? "暂无喂养记录" : parts.joined(separator: " · ")
    }

    var sleepTotalText: String {
        durationText(minutes: sleepMinutes)
    }

    var sleepCaption: String {
        guard sleepMinutes > 0 else { return "暂无睡眠时长" }
        let average = sleepMinutes / activeDayCount
        return "平均每天 \(durationText(minutes: average))"
    }

    var diaperCaption: String {
        guard diaperTotalCount > 0 else { return "暂无尿布记录" }
        return "小便 \(peeCount)次 · 大便 \(poopCount)次"
    }

    var latestGrowthValue: String {
        guard let latestGrowthRecord else { return "暂无" }

        if let weight = latestGrowthRecord.weightKG {
            return String(format: "%.1fkg", weight)
        }
        if let height = latestGrowthRecord.heightCM {
            return String(format: "%.1fcm", height)
        }
        if let head = latestGrowthRecord.headCircumferenceCM {
            return String(format: "%.1fcm", head)
        }
        return "已记录"
    }

    var growthCaption: String {
        guard let latestGrowthRecord else { return "添加身高、体重或头围记录" }
        var parts: [String] = []
        if let height = latestGrowthRecord.heightCM {
            parts.append(String(format: "身高 %.1fcm", height))
        }
        if let weight = latestGrowthRecord.weightKG {
            parts.append(String(format: "体重 %.1fkg", weight))
        }
        if let head = latestGrowthRecord.headCircumferenceCM {
            parts.append(String(format: "头围 %.1fcm", head))
        }
        return parts.isEmpty ? "最近有成长记录" : parts.joined(separator: " · ")
    }

    var trendCaption: String {
        mode == .weekly ? "近7天" : "按周汇总"
    }

    var chartBuckets: [GrowthReportChartBucket] {
        switch mode {
        case .weekly:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_Hans_CN")
            formatter.dateFormat = "M/d"

            return (0..<7).reversed().map { offset in
                let start = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date())) ?? Date()
                let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()
                return bucket(label: formatter.string(from: start), start: start, end: end)
            }
        case .monthly:
            var buckets: [GrowthReportChartBucket] = []
            var start = periodStart
            var index = 1

            while start < activeEnd {
                let end = min(calendar.date(byAdding: .day, value: 7, to: start) ?? activeEnd, activeEnd)
                buckets.append(bucket(label: "第\(index)周", start: start, end: end))
                start = end
                index += 1
            }

            return buckets
        }
    }

    var insights: [String] {
        var values: [String] = []

        if totalFeedingCount > 0 {
            let formulaText = formulaAmount > 0 ? "，其中配方奶共 \(formulaAmount)ml" : ""
            values.append("\(mode.summaryName)喂养 \(totalFeedingCount) 次\(formulaText)，可结合宝宝精神状态和尿布情况判断摄入是否稳定。")
        }

        if sleepMinutes > 0 {
            values.append("\(mode.summaryName)累计睡眠 \(durationText(minutes: sleepMinutes))，平均每天 \(durationText(minutes: sleepMinutes / activeDayCount))。")
        }

        if diaperTotalCount > 0 {
            values.append("\(mode.summaryName)换尿布 \(diaperTotalCount) 次，小便 \(peeCount) 次，大便 \(poopCount) 次，适合和喂养记录一起观察。")
        }

        if let latestGrowthRecord {
            values.append("最近一次成长数据为：\(growthCaption)，记录于 \(shortDateText(latestGrowthRecord.timestamp))。")
        }

        if values.isEmpty {
            values.append("本期数据还不够完整，建议先连续记录喂养、睡眠和尿布，报告会自动变得更有参考价值。")
        }

        return Array(values.prefix(4))
    }

    var shareText: String {
        let insightText = insights.map { "- \($0)" }.joined(separator: "\n")
        return """
        \(babyName)的\(mode.title)
        \(rangeText)

        总记录：\(totalRecords)条
        喂养：\(totalFeedingCount)次（\(feedingCaption)）
        睡眠：\(sleepTotalText)（\(sleepCaption)）
        换尿布：\(diaperTotalCount)次（\(diaperCaption)）
        成长：\(growthCaption)

        报告解读：
        \(insightText)
        """
    }

    private func bucket(label: String, start: Date, end: Date) -> GrowthReportChartBucket {
        let bucketRecords = records.filter { $0.timestamp >= start && $0.timestamp < end }
        return GrowthReportChartBucket(
            label: label,
            total: bucketRecords.count,
            feeding: bucketRecords.filter { $0.recordType == .feeding || $0.recordType == .formula }.count,
            diaper: bucketRecords.filter { $0.recordType == .diaper || $0.recordType == .poop }.count
        )
    }

    private func durationText(minutes: Int) -> String {
        guard minutes > 0 else { return "0分" }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 { return "\(hours)小时\(mins)分" }
        if hours > 0 { return "\(hours)小时" }
        return "\(mins)分"
    }

    private func shortDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

private struct GrowthReportChartBucket: Identifiable {
    let id = UUID()
    let label: String
    let total: Int
    let feeding: Int
    let diaper: Int
}

private struct GrowthReportMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let caption: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outline)

                Text(caption)
                    .font(.system(size: 11))
                    .foregroundColor(Color.onSurfaceVariant)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
        .padding(14)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.035), radius: 8, y: 2)
    }
}

private struct GrowthReportBarChart: View {
    let buckets: [GrowthReportChartBucket]
    var animated = true
    @State private var animateBars = false

    private var maxValue: CGFloat {
        CGFloat(Swift.max(buckets.map(\.total).max() ?? 1, 1))
    }

    private var shouldShowBars: Bool {
        !animated || animateBars
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(buckets) { bucket in
                VStack(spacing: 7) {
                    Text("\(bucket.total)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.onSurfaceVariant)
                        .opacity(bucket.total > 0 ? 1 : 0.45)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.primary.opacity(0.95),
                                    Color.secondary.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: shouldShowBars ? barHeight(for: bucket.total) : 8)
                        .overlay(alignment: .bottom) {
                            if bucket.diaper > 0 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.tertiary.opacity(0.55))
                                    .frame(height: shouldShowBars ? barHeight(for: bucket.diaper) * 0.45 : 0)
                            }
                        }

                    Text(bucket.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.outline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 132)
        .padding(.top, 4)
        .onAppear {
            guard animated else {
                animateBars = true
                return
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.12)) {
                animateBars = true
            }
        }
        .onChange(of: buckets.map(\.total)) { _, _ in
            guard animated else {
                animateBars = true
                return
            }
            animateBars = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    animateBars = true
                }
            }
        }
    }

    private func barHeight(for value: Int) -> CGFloat {
        guard maxValue > 0 else { return 8 }
        return Swift.max(8, CGFloat(value) / maxValue * 82)
    }
}

private struct GrowthReportInsightRow: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color.onPrimary)
                .frame(width: 22, height: 22)
                .background(Color.primary)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.onSurfaceVariant)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct GrowthReportRecordRow: View {
    let record: RecordModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: record.recordType.iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(record.recordType.iconColor)
                .frame(width: 30, height: 30)
                .background(record.recordType.iconBackgroundColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(record.recordType.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.onSurface)

                Text(record.displaySummary)
                    .font(.system(size: 11))
                    .foregroundColor(Color.outline)
                    .lineLimit(1)
            }

            Spacer()

            Text(timeText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color.outline)
        }
        .padding(.vertical, 10)
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: record.timestamp)
    }
}

#Preview {
    GrowthReportView(records: [], babyProfile: nil)
}
