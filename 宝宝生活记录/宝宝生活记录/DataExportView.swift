import SwiftUI
import SwiftData

struct DataExportView: View {
    let records: [RecordModel]
    let babyProfile: BabyProfile?
    @Environment(\.dismiss) var dismiss
    @State private var exportFormat = 0
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    let formats = ["CSV 表格", "JSON 数据"]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 40))
                        .foregroundColor(Color.primary)
                    Text("导出数据")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.onSurface)
                    Text("将宝宝的记录数据导出为文件，方便备份或分享")
                        .font(.system(size: 14))
                        .foregroundColor(Color.outline)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                VStack(spacing: 12) {
                    HStack {
                        Text("导出格式")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.onSurfaceVariant)
                        Spacer()
                    }
                    HStack(spacing: 12) {
                        ForEach(0..<formats.count, id: \.self) { index in
                            Button(action: { exportFormat = index }) {
                                Text(formats[index])
                                    .font(.system(size: 15, weight: exportFormat == index ? .bold : .medium))
                                    .foregroundColor(exportFormat == index ? Color.onPrimaryContainer : Color.onSurface)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(exportFormat == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    statRow(label: "总记录数", value: "\(records.count) 条")
                    statRow(label: "时间范围", value: dateRangeText)
                    statRow(label: "记录类型", value: "\(Set(records.map { $0.recordType }).count) 种")
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                Spacer()

                Button(action: { exportData() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                        Text("导出并分享")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(Color.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(records.isEmpty ? Color.outlineVariant : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: Color.primary.opacity(0.3), radius: 8, y: 4)
                }
                .disabled(records.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color.outline)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.onSurface)
        }
    }

    var dateRangeText: String {
        guard !records.isEmpty else { return "无数据" }
        let sorted = records.sorted { $0.timestamp < $1.timestamp }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return "\(formatter.string(from: sorted.first!.timestamp)) - \(formatter.string(from: sorted.last!.timestamp))"
    }

    func exportData() {
        let data: String
        if exportFormat == 0 {
            data = generateCSV()
        } else {
            data = generateJSON()
        }

        let fileName = exportFormat == 0 ? "宝宝记录.csv" : "宝宝记录.json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            showShareSheet = true
        } catch {
            print("Export failed: \(error)")
        }
    }

    func generateCSV() -> String {
        var csv = "类型,时间,备注,详细信息\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        for record in records.sorted(by: { $0.timestamp < $1.timestamp }) {
            let type = record.recordType.displayName
            let time = formatter.string(from: record.timestamp)
            let note = record.note.replacingOccurrences(of: ",", with: "，")
            let detail = record.displaySummary.replacingOccurrences(of: ",", with: "，")
            csv += "\(type),\(time),\(note),\(detail)\n"
        }
        return csv
    }

    func generateJSON() -> String {
        var items: [[String: Any]] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        for record in records.sorted(by: { $0.timestamp < $1.timestamp }) {
            var item: [String: Any] = [
                "type": record.recordType.rawValue,
                "typeName": record.recordType.displayName,
                "timestamp": formatter.string(from: record.timestamp),
                "note": record.note
            ]
            if let side = record.breastSide { item["breastSide"] = side }
            if let amount = record.feedingAmountML { item["feedingAmountML"] = amount }
            if let duration = record.feedingDurationMin { item["feedingDurationMin"] = duration }
            if let end = record.sleepEndTime { item["sleepEndTime"] = formatter.string(from: end) }
            if let amount = record.formulaAmountML { item["formulaAmountML"] = amount }
            if let brand = record.formulaBrand { item["formulaBrand"] = brand }
            if let type = record.diaperType { item["diaperType"] = type }
            if let color = record.poopColor { item["poopColor"] = color }
            if let texture = record.poopTexture { item["poopTexture"] = texture }
            if let h = record.heightCM { item["heightCM"] = h }
            if let w = record.weightKG { item["weightKG"] = w }
            if let name = record.vaccineName { item["vaccineName"] = name }
            if let batch = record.vaccineBatch { item["vaccineBatch"] = batch }
            if let site = record.vaccineSite { item["vaccineSite"] = site }
            if let reaction = record.vaccineReaction { item["vaccineReaction"] = reaction }
            if let name = record.babyFoodName { item["babyFoodName"] = name }
            if let amount = record.babyFoodAmount { item["babyFoodAmount"] = amount }
            if let reaction = record.babyFoodReaction { item["babyFoodReaction"] = reaction }
            if let side = record.pumpingSide { item["pumpingSide"] = side }
            if let dur = record.pumpingDurationMin { item["pumpingDurationMin"] = dur }
            if let amt = record.pumpingAmountML { item["pumpingAmountML"] = amt }
            if let type = record.symptomType { item["symptomType"] = type }
            if let sev = record.symptomSeverity { item["symptomSeverity"] = sev }
            if let temp = record.temperature { item["temperature"] = temp }
            if let cm = record.headCircumferenceCM { item["headCircumferenceCM"] = cm }
            if let tooth = record.toothName { item["toothName"] = tooth }
            items.append(item)
        }

        let output: [String: Any] = [
            "babyName": babyProfile?.name ?? "宝宝",
            "exportDate": formatter.string(from: Date()),
            "totalRecords": items.count,
            "records": items
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: output, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DataExportView(records: [], babyProfile: nil)
}
