import SwiftUI
import SwiftData

struct GrowthChartView: View {
    let records: [RecordModel]
    @State private var selectedMetric = 0

    let metrics = ["体重", "身高"]

    var growthRecords: [RecordModel] {
        records.filter { $0.recordType == .growth }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var weightData: [(Date, Double)] {
        growthRecords.compactMap { r in
            r.weightKG.map { (r.timestamp, $0) }
        }
    }

    var heightData: [(Date, Double)] {
        growthRecords.compactMap { r in
            r.heightCM.map { (r.timestamp, $0) }
        }
    }

    var currentData: [(Date, Double)] {
        selectedMetric == 0 ? weightData : heightData
    }

    var unit: String { selectedMetric == 0 ? "kg" : "cm" }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("成长趋势")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.onSurface)
                Spacer()
                HStack(spacing: 0) {
                    ForEach(0..<metrics.count, id: \.self) { index in
                        Button(action: { selectedMetric = index }) {
                            Text(metrics[index])
                                .font(.system(size: 11, weight: selectedMetric == index ? .bold : .medium))
                                .foregroundColor(selectedMetric == index ? Color.onPrimaryContainer : Color.outline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(selectedMetric == index ? Color.primaryContainer : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                }
                .background(Color.surfaceContainerHighest.opacity(0.5))
                .clipShape(Capsule())
            }

            if currentData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(Color.outlineVariant)
                    Text("暂无\(selectedMetric == 0 ? "体重" : "身高")数据")
                        .font(.system(size: 12))
                        .foregroundColor(Color.outline)
                    Text("在「身高体重」中记录数据后这里会显示趋势")
                        .font(.system(size: 10))
                        .foregroundColor(Color.outlineVariant)
                }
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    chartView

                    HStack {
                        if let latest = currentData.last {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("最新")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color.outline)
                                Text("\(formatValue(latest.1))\(unit)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.onSurface)
                            }
                        }

                        Spacer()

                        if currentData.count >= 2 {
                            let first = currentData.first!.1
                            let last = currentData.last!.1
                            let diff = last - first
                            let trend = diff >= 0 ? "+" : ""

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("变化")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color.outline)
                                Text("\(trend)\(formatValue(diff))\(unit)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(diff >= 0 ? Color.tertiary : Color.error)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("记录次数")
                                .font(.system(size: 9))
                                .foregroundColor(Color.outline)
                            Text("\(currentData.count) 次")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.onSurface)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var chartView: some View {
        GeometryReader { geometry in
            let data = currentData
            let values = data.map { $0.1 }
            let minVal = values.min() ?? 0
            let maxVal = values.max() ?? 1
            let range = maxVal - minVal
            let padding = range == 0 ? max(abs(maxVal) * 0.1, 1) : range * 0.1
            let adjustedMin = minVal - padding
            let adjustedMax = maxVal + padding
            let adjustedRange = adjustedMax - adjustedMin

            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    let y = geometry.size.height * CGFloat(i) / 3
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.outlineVariant.opacity(0.2), lineWidth: 0.5)
                }

                if data.count > 1 {
                    Path { path in
                        for (index, point) in data.enumerated() {
                            let x = geometry.size.width * CGFloat(index) / CGFloat(data.count - 1)
                            let y = geometry.size.height * (1 - (point.1 - adjustedMin) / adjustedRange)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }

                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    let x = geometry.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1))
                    let y = geometry.size.height * (1 - (point.1 - adjustedMin) / adjustedRange)

                    Circle()
                        .fill(Color.primary)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)

                    if index == data.count - 1 || index == 0 {
                        Text("\(formatValue(point.1))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.onSurface)
                            .position(x: x, y: y - 14)
                    }
                }
            }
        }
        .frame(height: 120)
    }

    func formatValue(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

#Preview {
    GrowthChartView(records: [])
        .padding()
}
