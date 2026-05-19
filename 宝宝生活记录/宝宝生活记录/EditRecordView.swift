import SwiftUI
import SwiftData

struct EditRecordView: View {
    let recordType: RecordType
    let record: RecordModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    @State private var amount: String
    @State private var durationMin: String
    @State private var height: String
    @State private var weight: String
    @State private var selectedBreastSide: Int
    @State private var selectedDiaperType: Int
    @State private var selectedPoopColor: Int
    @State private var selectedPoopTexture: Int
    @State private var showDeleteAlert = false
    @State private var showTimePicker = false
    @State private var showEndTimePicker = false

    static let breastSides = ["左侧", "右侧", "双侧"]
    static let diaperTypes = ["湿的", "干的", "混合"]
    static let poopColors = ["金黄", "深绿", "棕色", "灰土", "黑色"]
    static let poopTextures = ["正常", "稀便", "硬便", "泡沫", "粘液", "颗粒", "蛋花汤", "血丝"]

    init(recordType: RecordType, record: RecordModel) {
        self.recordType = recordType
        self.record = record
        _startTime = State(initialValue: record.timestamp)
        _endTime = State(initialValue: record.sleepEndTime ?? record.timestamp)
        _notes = State(initialValue: record.note)
        _amount = State(initialValue: {
            switch recordType {
            case .feeding: return record.feedingAmountML.map { String($0) } ?? ""
            case .formula: return record.formulaAmountML.map { String($0) } ?? ""
            default: return ""
            }
        }())
        _durationMin = State(initialValue: record.feedingDurationMin.map { String($0) } ?? "")
        _height = State(initialValue: record.heightCM.map { String(format: "%.1f", $0) } ?? "")
        _weight = State(initialValue: record.weightKG.map { String(format: "%.1f", $0) } ?? "")
        _selectedBreastSide = State(initialValue: {
            if let side = record.breastSide {
                if side.contains("双") { return 2 }
                if side.contains("左") { return 0 }
            }
            return 1
        }())
        _selectedDiaperType = State(initialValue: {
            if let type = record.diaperType {
                if type.contains("干") { return 1 }
                if type.contains("混") { return 2 }
            }
            return 0
        }())
        _selectedPoopColor = State(initialValue: {
            guard let color = record.poopColor else { return 2 }
            return Self.poopColors.firstIndex(of: color) ?? 2
        }())
        _selectedPoopTexture = State(initialValue: {
            guard let texture = record.poopTexture else { return 0 }
            return Self.poopTextures.firstIndex(of: texture) ?? 0
        }())
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            timeSection
                            formContent
                            deleteButton
                        }
                        .padding(20)
                        .padding(.bottom, 100)
                    }

                    saveButton
                        .padding(20)
                        .background(Color.surface.opacity(0.8))
                        .background(.ultraThinMaterial)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("编辑\(recordType.displayName)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.primary)
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    modelContext.delete(record)
                    dismiss()
                }
            } message: {
                Text("确定要删除这条记录吗？删除后无法恢复。")
            }
            .sheet(isPresented: $showTimePicker) {
                timePickerSheet(date: $startTime, title: "开始时间")
            }
            .sheet(isPresented: $showEndTimePicker) {
                timePickerSheet(date: $endTime, title: "结束时间")
            }
        }
    }

    func timePickerSheet(date: Binding<Date>, title: String) -> some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("选择\(title)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.onSurface)
                    .padding(.top, 16)

                CalendarTimePicker(selectedDate: date) {
                    showTimePicker = false
                    showEndTimePicker = false
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showTimePicker = false
                        showEndTimePicker = false
                    }
                }
            }
        }
    }

    var timeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("记录时间")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.onSurfaceVariant)
                    .textCase(.uppercase)
                Spacer()
            }

            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.primary)
                            .frame(width: 44, height: 44)
                            .background(Color.surfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button(action: { showTimePicker = true }) {
                            HStack(spacing: 4) {
                                Text(startTime, style: .time)
                                    .font(.system(size: 16, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Color.onSurface)
                        }
                    }

                    Spacer()
                }

                if recordType == .sleep {
                    Divider()
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.primaryDim)
                                .frame(width: 44, height: 44)
                                .background(Color.surfaceContainer)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button(action: { showEndTimePicker = true }) {
                                HStack(spacing: 4) {
                                    Text(endTime, style: .time)
                                        .font(.system(size: 16, weight: .medium))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(Color.onSurface)
                            }
                        }

                        Spacer()

                        Text("醒来时间")
                            .font(.system(size: 12))
                            .foregroundColor(Color.outline)
                    }
                }
            }
            .padding(16)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.primary.opacity(0.08), radius: 12, y: 4)
        }
    }

    @ViewBuilder
    var formContent: some View {
        switch recordType {
        case .feeding:
            feedingContent
        case .sleep:
            sleepContent
        case .diaper:
            diaperContent
        case .formula:
            formulaContent
        case .poop:
            poopContent
        case .growth:
            growthContent
        default:
            notesOnlyContent
        }
    }

    var notesOnlyContent: some View {
        VStack(spacing: 24) {
            notesSection
        }
    }

    var feedingContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("喂奶部位")
                HStack(spacing: 12) {
                    ForEach(0..<Self.breastSides.count, id: \.self) { index in
                        Button(action: { selectedBreastSide = index }) {
                            Text(Self.breastSides[index])
                                .font(.system(size: 15, weight: selectedBreastSide == index ? .bold : .medium))
                                .foregroundColor(selectedBreastSide == index ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(selectedBreastSide == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                sectionLabel("喂奶时长 (分钟)")
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 18))
                        .foregroundColor(Color.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.secondaryContainer.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入时长", text: $durationMin)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16, weight: .medium))
                    Text("分钟")
                        .font(.system(size: 14))
                        .foregroundColor(Color.outline)
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            VStack(spacing: 12) {
                sectionLabel("喂奶量 (ml) - 可选")
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.secondaryContainer.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入量", text: $amount)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16, weight: .medium))
                    Text("ml")
                        .font(.system(size: 14))
                        .foregroundColor(Color.outline)
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            notesSection
        }
    }

    var sleepContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("睡眠时长")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.onSurfaceVariant)
                Text(calculateSleepDuration())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.primaryDim)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            notesSection
        }
    }

    func calculateSleepDuration() -> String {
        let duration = endTime.timeIntervalSince(startTime)
        guard duration > 0 else { return "0分钟" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 && minutes > 0 { return "\(hours)小时\(minutes)分钟" }
        if hours > 0 { return "\(hours)小时" }
        return "\(minutes)分钟"
    }

    var diaperContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("尿布状态")
                HStack(spacing: 12) {
                    ForEach(0..<Self.diaperTypes.count, id: \.self) { index in
                        Button(action: { selectedDiaperType = index }) {
                            Text(Self.diaperTypes[index])
                                .font(.system(size: 15, weight: selectedDiaperType == index ? .bold : .medium))
                                .foregroundColor(selectedDiaperType == index ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(selectedDiaperType == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            notesSection
        }
    }

    var formulaContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("奶粉量 (ml)")
                HStack {
                    Image(systemName: "waterbottle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.secondaryContainer.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入量", text: $amount)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16, weight: .medium))
                    Text("ml")
                        .font(.system(size: 14))
                        .foregroundColor(Color.outline)
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            notesSection
        }
    }

    var poopContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("大便颜色")
                HStack(spacing: 12) {
                    ForEach(0..<Self.poopColors.count, id: \.self) { index in
                        Button(action: { selectedPoopColor = index }) {
                            Text(Self.poopColors[index])
                                .font(.system(size: 14, weight: selectedPoopColor == index ? .bold : .medium))
                                .foregroundColor(selectedPoopColor == index ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedPoopColor == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                sectionLabel("形状与质地")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(0..<Self.poopTextures.count, id: \.self) { index in
                        Button(action: { selectedPoopTexture = index }) {
                            Text(Self.poopTextures[index])
                                .font(.system(size: 14, weight: selectedPoopTexture == index ? .bold : .medium))
                                .foregroundColor(selectedPoopTexture == index ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedPoopTexture == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            notesSection
        }
    }

    var growthContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("身高 (cm)")
                HStack {
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.tertiary)
                        .frame(width: 44, height: 44)
                        .background(Color.tertiaryContainer.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入身高", text: $height)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16, weight: .medium))
                    Text("cm")
                        .font(.system(size: 14))
                        .foregroundColor(Color.outline)
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            VStack(spacing: 12) {
                sectionLabel("体重 (kg)")
                HStack {
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.tertiary)
                        .frame(width: 44, height: 44)
                        .background(Color.tertiaryContainer.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入体重", text: $weight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16, weight: .medium))
                    Text("kg")
                        .font(.system(size: 14))
                        .foregroundColor(Color.outline)
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            notesSection
        }
    }

    func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.onSurfaceVariant)
                .textCase(.uppercase)
            Spacer()
        }
    }

    var notesSection: some View {
        VStack(spacing: 12) {
            sectionLabel("备注")
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(12)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 1)
                )
        }
    }

    var deleteButton: some View {
        Button(action: { showDeleteAlert = true }) {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                Text("删除记录")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(Color.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.error.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    var saveButton: some View {
        Button(action: {
            saveChanges()
            dismiss()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("保存修改")
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

    func saveChanges() {
        record.timestamp = startTime
        record.note = notes
        switch recordType {
        case .feeding:
            record.breastSide = Self.breastSides[selectedBreastSide]
            if !durationMin.isEmpty, let min = Int(durationMin) { record.feedingDurationMin = min }
            if !amount.isEmpty, let ml = Int(amount) { record.feedingAmountML = ml }
        case .sleep:
            record.sleepEndTime = endTime
        case .diaper:
            record.diaperType = Self.diaperTypes[selectedDiaperType]
        case .formula:
            if !amount.isEmpty, let ml = Int(amount) { record.formulaAmountML = ml }
        case .poop:
            record.poopColor = Self.poopColors[selectedPoopColor]
            record.poopTexture = Self.poopTextures[selectedPoopTexture]
        case .growth:
            if !height.isEmpty, let h = Double(height) { record.heightCM = h }
            if !weight.isEmpty, let w = Double(weight) { record.weightKG = w }
        default:
            break
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RecordModel.self, configurations: config)
        let record = RecordModel(type: .feeding, timestamp: Date(), note: "双侧喂奶")
        record.breastSide = "双侧"
        record.feedingAmountML = 150
        return EditRecordView(recordType: .feeding, record: record)
            .modelContainer(container)
    } catch {
        return Text("Preview error: \(error.localizedDescription)")
    }
}
