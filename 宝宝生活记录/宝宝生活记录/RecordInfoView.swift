import SwiftUI

struct RecordInfoView: View {
    let record: RecordModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var showEditView = false
    @State private var showDeleteConfirm = false
    @State private var animateContent = false

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
                    Button(action: { showEditView = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.primary)
                            .frame(width: 32, height: 32)
                            .background(Color.primaryContainer)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showEditView) {
                EditRecordView(recordType: record.recordType, record: record)
            }
            .alert("确认删除", isPresented: $showDeleteConfirm) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        modelContext.delete(record)
                    }
                    dismiss()
                }
            } message: {
                Text("确定要删除这条记录吗？删除后无法恢复。")
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                animateContent = true
            }
        }
    }

    var headerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(record.recordType.iconColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: record.recordType.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(record.recordType.iconColor)
            }
            .scaleEffect(animateContent ? 1 : 0.8)
            .opacity(animateContent ? 1 : 0)

            VStack(spacing: 8) {
                Text(record.recordType.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.onSurface)

                Text(formattedDate(record.timestamp))
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
        .shadow(color: record.recordType.iconColor.opacity(0.1), radius: 12, y: 4)
    }

    var detailSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("记录详情")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.onSurface)
                Spacer()
            }

            VStack(spacing: 1) {
                detailRow(icon: "clock", label: "时间", value: formattedTime(record.timestamp))

                if record.recordType == .feeding {
                    if let duration = record.feedingDurationMin {
                        detailRow(icon: "timer", label: "喂奶时长", value: "\(duration) 分钟")
                    }
                    if let amount = record.feedingAmountML {
                        detailRow(icon: "drop", label: "奶量", value: "\(amount) ml")
                    }
                    if let side = record.breastSide {
                        detailRow(icon: "arrow.left.arrow.right", label: "喂奶侧", value: side)
                    }
                }

                if record.recordType == .sleep {
                    if let duration = record.sleepDurationMinutes {
                        let hours = duration / 60
                        let mins = duration % 60
                        detailRow(icon: "moon.zzz", label: "睡眠时长", value: hours > 0 ? "\(hours)小时\(mins)分钟" : "\(mins)分钟")
                    }
                }

                if record.recordType == .pumping, let amount = record.pumpingAmountML {
                    detailRow(icon: "drop", label: "吸奶量", value: "\(amount) ml")
                }

                if record.recordType == .formula, let amount = record.formulaAmountML {
                    detailRow(icon: "drop", label: "配方奶量", value: "\(amount) ml")
                }

                if record.recordType == .growth {
                    if let height = record.heightCM {
                        detailRow(icon: "ruler", label: "身高", value: String(format: "%.1f cm", height))
                    }
                    if let weight = record.weightKG {
                        detailRow(icon: "scalemass", label: "体重", value: String(format: "%.2f kg", weight))
                    }
                    if let head = record.headCircumferenceCM {
                        detailRow(icon: "brain.head.profile", label: "头围", value: String(format: "%.1f cm", head))
                    }
                }

                if record.recordType == .symptom {
                    if let temp = record.temperature {
                        detailRow(icon: "thermometer", label: "体温", value: String(format: "%.1f°C", temp))
                    }
                }

                if record.recordType == .headCircumference, let cm = record.headCircumferenceCM {
                    detailRow(icon: "brain.head.profile", label: "头围", value: String(format: "%.1f cm", cm))
                }

                if !record.note.isEmpty {
                    detailRow(icon: "note.text", label: "备注", value: record.note)
                }
            }
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }

    var actionButtons: some View {
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
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
    }

    func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(record.recordType.iconColor)
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
