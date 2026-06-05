import SwiftUI
import SwiftData

struct RecordInfoView: View {
    let record: RecordModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var allRecords: [RecordModel] = []
    @State private var showEditView = false
    @State private var showDeleteConfirm = false
    @State private var animateContent = false

    var currentRecord: RecordModel {
        allRecords.first { $0.persistentModelID == record.persistentModelID } ?? record
    }

    var canManageCurrentRecord: Bool {
        currentRecord.babyProfile?.isFamilyOwner != false
    }

    func fetchRecords() {
        let descriptor = FetchDescriptor<RecordModel>()
        allRecords = (try? modelContext.fetch(descriptor)) ?? []
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    detailSection
                    actionButtons
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.onSurface)
                            .frame(width: 32, height: 32)
                            .background(Color.surfaceContainerHighest)
                            .clipShape(Circle())
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if canManageCurrentRecord {
                        Button("编辑") {
                            showEditView = true
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.primary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showEditView, onDismiss: {
                fetchRecords()
            }) {
                EditRecordView(recordType: currentRecord.recordType, record: currentRecord)
            }
            .alert("确认删除", isPresented: $showDeleteConfirm) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        modelContext.delete(currentRecord)
                    }
                    dismiss()
                }
            } message: {
                Text("确定要删除这条记录吗？删除后无法恢复。")
            }
        }
        .onAppear {
            fetchRecords()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateContent = true
            }
        }
    }

    var headerCard: some View {
        let r = currentRecord
        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(r.recordType.iconColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: r.recordType.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(r.recordType.iconColor)
            }
            .scaleEffect(animateContent ? 1 : 0.8)
            .opacity(animateContent ? 1 : 0)

            VStack(spacing: 8) {
                Text(r.recordType.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.onSurface)

                Text(formattedDate(r.timestamp))
                    .font(.system(size: 15))
                    .foregroundColor(Color.outline)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 10)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: r.recordType.iconColor.opacity(0.1), radius: 12, y: 4)
    }

    var detailSection: some View {
        let r = currentRecord
        return VStack(spacing: 16) {
            HStack {
                Text("记录详情")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.onSurface)
                Spacer()
            }

            VStack(spacing: 1) {
                detailRow(icon: "clock", label: "时间", value: formattedTime(r.timestamp), r: r)

                switch r.recordType {
                case .feeding:
                    if let side = r.breastSide {
                        detailRow(icon: side == "瓶喂" ? "waterbottle.fill" : "arrow.left.arrow.right", label: side == "瓶喂" ? "喂养方式" : "喂奶侧", value: side, r: r)
                    }
                    if let duration = r.feedingDurationMin {
                        detailRow(icon: "timer", label: "喂奶时长", value: "\(duration) 分钟", r: r)
                        let endTime = r.timestamp.addingTimeInterval(TimeInterval(duration * 60))
                        detailRow(icon: "stop.circle", label: "结束时间", value: formattedTime(endTime), r: r)
                    }
                    if let amount = r.feedingAmountML {
                        detailRow(icon: "drop.circle", label: "奶量", value: "\(amount) ml", r: r)
                    }

                case .sleep:
                    if let duration = r.sleepDurationMinutes {
                        let hours = duration / 60
                        let mins = duration % 60
                        detailRow(icon: "moon.zzz", label: "睡眠时长", value: hours > 0 ? "\(hours)小时\(mins)分钟" : "\(mins)分钟", r: r)
                    }

                case .diaper:
                    if let type = r.diaperType {
                        detailRow(icon: RecordType.diaper.iconName, label: "尿布类型", value: type, r: r)
                    }

                case .formula:
                    if let brand = r.formulaBrand, !brand.isEmpty {
                        detailRow(icon: "tag", label: "奶粉品牌", value: brand, r: r)
                    }
                    if let amount = r.formulaAmountML {
                        detailRow(icon: RecordType.formula.iconName, label: "奶量", value: "\(amount) ml", r: r)
                    }

                case .poop:
                    if let color = r.poopColor {
                        detailRow(icon: "paintpalette", label: "颜色", value: color, r: r)
                    }
                    if let texture = r.poopTexture {
                        detailRow(icon: "circle.grid.3x3", label: "形状与质地", value: texture, r: r)
                    }

                case .pumping:
                    if let side = r.pumpingSide, !side.isEmpty {
                        detailRow(icon: "arrow.left.arrow.right", label: "吸奶侧", value: side, r: r)
                    }
                    if let duration = r.pumpingDurationMin {
                        detailRow(icon: "timer", label: "吸奶时长", value: "\(duration) 分钟", r: r)
                    }
                    if let amount = r.pumpingAmountML {
                        detailRow(icon: RecordType.pumping.iconName, label: "吸奶量", value: "\(amount) ml", r: r)
                    }

                case .growth:
                    if let height = r.heightCM {
                        detailRow(icon: "ruler", label: "身高", value: String(format: "%.1f cm", height), r: r)
                    }
                    if let weight = r.weightKG {
                        detailRow(icon: "scalemass", label: "体重", value: String(format: "%.2f kg", weight), r: r)
                    }

                case .vaccine:
                    if let name = r.vaccineName, !name.isEmpty {
                        detailRow(icon: "syringe", label: "疫苗名称", value: name, r: r)
                    }
                    if let batch = r.vaccineBatch, !batch.isEmpty {
                        detailRow(icon: "number", label: "批次", value: batch, r: r)
                    }
                    if let site = r.vaccineSite, !site.isEmpty {
                        detailRow(icon: "mappin", label: "接种部位", value: site, r: r)
                    }
                    if let reaction = r.vaccineReaction, !reaction.isEmpty {
                        detailRow(icon: "exclamationmark.triangle", label: "反应", value: reaction, r: r)
                    }

                case .babyFood:
                    if let name = r.babyFoodName, !name.isEmpty {
                        detailRow(icon: "fork.knife", label: "辅食名称", value: name, r: r)
                    }
                    if let amount = r.babyFoodAmount, !amount.isEmpty {
                        detailRow(icon: "scalemass", label: "食量", value: amount, r: r)
                    }
                    if let reaction = r.babyFoodReaction, !reaction.isEmpty {
                        detailRow(icon: "face.smiling", label: "反应", value: reaction, r: r)
                    }

                case .symptom:
                    if let type = r.symptomType, !type.isEmpty {
                        detailRow(icon: "heart.text.square", label: "症状类型", value: type, r: r)
                    }
                    if let severity = r.symptomSeverity, !severity.isEmpty {
                        detailRow(icon: "gauge", label: "严重程度", value: severity, r: r)
                    }
                    if let temp = r.temperature {
                        detailRow(icon: "thermometer", label: "体温", value: String(format: "%.1f°C", temp), r: r)
                    }

                case .headCircumference:
                    if let cm = r.headCircumferenceCM {
                        detailRow(icon: RecordType.headCircumference.iconName, label: "头围", value: String(format: "%.1f cm", cm), r: r)
                    }

                case .tooth:
                    if let name = r.toothName, !name.isEmpty {
                        detailRow(icon: RecordType.tooth.iconName, label: "牙齿名称", value: name, r: r)
                    }
                }

                if !r.note.isEmpty {
                    detailRow(icon: "note.text", label: "备注", value: r.note, r: r)
                }
            }
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }

    var actionButtons: some View {
        Group {
            if canManageCurrentRecord {
                HStack(spacing: 16) {
                    Button(action: { showEditView = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                            Text("编辑")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.primaryContainer)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: { showDeleteConfirm = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                            Text("删除")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.error.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }

    func detailRow(icon: String, label: String, value: String, r: RecordModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(r.recordType.iconColor)
                .frame(width: 28)

            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Color.outline)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.onSurface)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.surfaceContainerLowest)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    RecordInfoView(record: RecordModel(type: .feeding, timestamp: Date(), note: "测试记录"))
}
