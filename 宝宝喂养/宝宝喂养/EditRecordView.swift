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
    @State private var formulaBrand: String
    @State private var vaccineName: String
    @State private var vaccineBatch: String
    @State private var vaccineSite: String
    @State private var vaccineReaction: String
    @State private var babyFoodName: String
    @State private var babyFoodAmount: String
    @State private var babyFoodReaction: String
    @State private var pumpingSide: Int
    @State private var pumpingDuration: String
    @State private var pumpingAmount: String
    @State private var symptomType: String
    @State private var symptomSeverity: Int
    @State private var temperature: String
    @State private var headCircumference: String
    @State private var toothName: String
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
            case .pumping: return record.pumpingAmountML.map { String($0) } ?? ""
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
        _formulaBrand = State(initialValue: record.formulaBrand ?? "")
        _vaccineName = State(initialValue: record.vaccineName ?? "")
        _vaccineBatch = State(initialValue: record.vaccineBatch ?? "")
        _vaccineSite = State(initialValue: record.vaccineSite ?? "")
        _vaccineReaction = State(initialValue: record.vaccineReaction ?? "")
        _babyFoodName = State(initialValue: record.babyFoodName ?? "")
        _babyFoodAmount = State(initialValue: record.babyFoodAmount ?? "")
        _babyFoodReaction = State(initialValue: record.babyFoodReaction ?? "")
        _pumpingSide = State(initialValue: {
            if let side = record.pumpingSide {
                if side.contains("双") { return 2 }
                if side.contains("左") { return 0 }
            }
            return 1
        }())
        _pumpingDuration = State(initialValue: record.pumpingDurationMin.map { String($0) } ?? "")
        _pumpingAmount = State(initialValue: record.pumpingAmountML.map { String($0) } ?? "")
        _symptomType = State(initialValue: record.symptomType ?? "")
        _symptomSeverity = State(initialValue: {
            guard let severity = record.symptomSeverity else { return 0 }
            if severity.contains("严重") { return 2 }
            if severity.contains("中等") { return 1 }
            return 0
        }())
        _temperature = State(initialValue: record.temperature.map { String(format: "%.1f", $0) } ?? "")
        _headCircumference = State(initialValue: record.headCircumferenceCM.map { String(format: "%.1f", $0) } ?? "")
        _toothName = State(initialValue: record.toothName ?? "")
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
                    Button("取消") { dismiss() }
                        .foregroundColor(Color.primary)
                }

                ToolbarItem(placement: .principal) {
                    Text("编辑\(recordType.displayName)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
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

                CalendarTimePicker(selectedDate: date, showsConfirmButton: false) {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        showTimePicker = false
                        showEndTimePicker = false
                    }
                    .fontWeight(.semibold)
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
        case .vaccine:
            vaccineContent
        case .babyFood:
            babyFoodContent
        case .pumping:
            pumpingContent
        case .symptom:
            symptomContent
        case .headCircumference:
            headCircumferenceContent
        case .tooth:
            toothContent
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
                    Image(systemName: "drop.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(RecordType.feeding.iconColor)
                        .frame(width: 44, height: 44)
                        .background(RecordType.feeding.iconBackgroundColor)
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
                    Image(systemName: RecordType.formula.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(RecordType.formula.iconColor)
                        .frame(width: 44, height: 44)
                        .background(RecordType.formula.iconBackgroundColor)
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

            VStack(spacing: 12) {
                sectionLabel("奶粉品牌 - 可选")
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.secondaryContainer.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入品牌", text: $formulaBrand)
                        .font(.system(size: 16, weight: .medium))
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

    var vaccineContent: some View {
        VStack(spacing: 24) {
            inputField(icon: RecordType.vaccine.iconName, iconColor: RecordType.vaccine.iconColor, label: "疫苗名称", text: $vaccineName, placeholder: "如：乙肝疫苗、百白破")
            inputField(icon: "barcode", iconColor: Color.outline, label: "疫苗批号", text: $vaccineBatch, placeholder: "输入批号")

            VStack(spacing: 12) {
                sectionLabel("接种部位")
                HStack(spacing: 12) {
                    ForEach(["左臂", "右臂", "左腿", "右腿"], id: \.self) { site in
                        Button(action: { vaccineSite = site }) {
                            Text(site)
                                .font(.system(size: 14, weight: vaccineSite == site ? .bold : .medium))
                                .foregroundColor(vaccineSite == site ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(vaccineSite == site ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                sectionLabel("接种反应")
                HStack(spacing: 12) {
                    ForEach(["无异常", "轻微红肿", "低热", "哭闹"], id: \.self) { reaction in
                        Button(action: { vaccineReaction = reaction }) {
                            Text(reaction)
                                .font(.system(size: 13, weight: vaccineReaction == reaction ? .bold : .medium))
                                .foregroundColor(vaccineReaction == reaction ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(vaccineReaction == reaction ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            notesSection
        }
    }

    var babyFoodContent: some View {
        VStack(spacing: 24) {
            inputField(icon: RecordType.babyFood.iconName, iconColor: RecordType.babyFood.iconColor, label: "食物名称", text: $babyFoodName, placeholder: "如：米粉、南瓜泥")
            inputField(icon: "scalemass", iconColor: Color.outline, label: "食用量", text: $babyFoodAmount, placeholder: "如：30g、半碗")

            VStack(spacing: 12) {
                sectionLabel("接受度 / 过敏反应")
                HStack(spacing: 12) {
                    ForEach(["爱吃", "一般", "不爱吃", "过敏"], id: \.self) { reaction in
                        Button(action: { babyFoodReaction = reaction }) {
                            Text(reaction)
                                .font(.system(size: 14, weight: babyFoodReaction == reaction ? .bold : .medium))
                                .foregroundColor(babyFoodReaction == reaction ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(babyFoodReaction == reaction ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            notesSection
        }
    }

    var pumpingContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("吸奶部位")
                HStack(spacing: 12) {
                    ForEach(0..<Self.breastSides.count, id: \.self) { index in
                        Button(action: { pumpingSide = index }) {
                            Text(Self.breastSides[index])
                                .font(.system(size: 15, weight: pumpingSide == index ? .bold : .medium))
                                .foregroundColor(pumpingSide == index ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(pumpingSide == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                sectionLabel("吸奶时长 (分钟)")
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 18))
                        .foregroundColor(Color.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.secondaryContainer.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入时长", text: $pumpingDuration)
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
                sectionLabel("吸奶量 (ml)")
                HStack {
                    Image(systemName: RecordType.pumping.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(RecordType.pumping.iconColor)
                        .frame(width: 44, height: 44)
                        .background(RecordType.pumping.iconBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入量", text: $pumpingAmount)
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

    var symptomContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("症状类型")
                HStack(spacing: 12) {
                    ForEach(["发烧", "咳嗽", "腹泻", "呕吐", "出牙不适", "湿疹", "鼻塞", "其他"], id: \.self) { type in
                        Button(action: { symptomType = type }) {
                            Text(type)
                                .font(.system(size: 13, weight: symptomType == type ? .bold : .medium))
                                .foregroundColor(symptomType == type ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(symptomType == type ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                sectionLabel("严重程度")
                HStack(spacing: 12) {
                    ForEach(0..<["轻微", "中等", "严重"].count, id: \.self) { index in
                        let labels = ["轻微", "中等", "严重"]
                        let colors = [Color.tertiary, Color(hex: "FFB347"), Color.error]
                        Button(action: { symptomSeverity = index }) {
                            Text(labels[index])
                                .font(.system(size: 15, weight: symptomSeverity == index ? .bold : .medium))
                                .foregroundColor(symptomSeverity == index ? .white : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(symptomSeverity == index ? colors[index] : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                sectionLabel("体温 (°C) - 可选")
                HStack {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 18))
                        .foregroundColor(RecordType.symptom.iconColor)
                        .frame(width: 44, height: 44)
                        .background(RecordType.symptom.iconBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("如：37.5", text: $temperature)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16, weight: .medium))
                    Text("°C")
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

    var headCircumferenceContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("头围 (cm)")
                HStack {
                    Image(systemName: RecordType.headCircumference.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(RecordType.headCircumference.iconColor)
                        .frame(width: 44, height: 44)
                        .background(RecordType.headCircumference.iconBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入头围", text: $headCircumference)
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

            notesSection
        }
    }

    var toothContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("牙齿名称")
                HStack(spacing: 12) {
                    ForEach(["下门牙", "上门牙", "侧切牙", "第一乳磨牙", "犬牙", "第二乳磨牙"], id: \.self) { name in
                        Button(action: { toothName = name }) {
                            Text(name)
                                .font(.system(size: 13, weight: toothName == name ? .bold : .medium))
                                .foregroundColor(toothName == name ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(toothName == name ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            notesSection
        }
    }

    func inputField(icon: String, iconColor: Color, label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(spacing: 12) {
            sectionLabel(label)
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                TextField(placeholder, text: text)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(16)
            .background(Color.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 20))
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
            saveAndDismiss()
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

    func saveAndDismiss() {
        saveChanges()
        dismiss()
    }

    func saveChanges() {
        record.timestamp = startTime
        record.note = notes
        switch recordType {
        case .feeding:
            record.breastSide = Self.breastSides[selectedBreastSide]
            record.feedingDurationMin = durationMin.isEmpty ? nil : Int(durationMin)
            record.feedingAmountML = amount.isEmpty ? nil : Int(amount)
        case .sleep:
            record.sleepEndTime = endTime
        case .diaper:
            record.diaperType = Self.diaperTypes[selectedDiaperType]
        case .formula:
            record.formulaAmountML = amount.isEmpty ? nil : Int(amount)
            record.formulaBrand = formulaBrand.isEmpty ? nil : formulaBrand
        case .poop:
            record.poopColor = Self.poopColors[selectedPoopColor]
            record.poopTexture = Self.poopTextures[selectedPoopTexture]
        case .growth:
            record.heightCM = height.isEmpty ? nil : Double(height)
            record.weightKG = weight.isEmpty ? nil : Double(weight)
        case .vaccine:
            record.vaccineName = vaccineName.isEmpty ? nil : vaccineName
            record.vaccineBatch = vaccineBatch.isEmpty ? nil : vaccineBatch
            record.vaccineSite = vaccineSite.isEmpty ? nil : vaccineSite
            record.vaccineReaction = vaccineReaction.isEmpty ? nil : vaccineReaction
        case .babyFood:
            record.babyFoodName = babyFoodName.isEmpty ? nil : babyFoodName
            record.babyFoodAmount = babyFoodAmount.isEmpty ? nil : babyFoodAmount
            record.babyFoodReaction = babyFoodReaction.isEmpty ? nil : babyFoodReaction
        case .pumping:
            record.pumpingSide = Self.breastSides[pumpingSide]
            record.pumpingDurationMin = pumpingDuration.isEmpty ? nil : Int(pumpingDuration)
            record.pumpingAmountML = pumpingAmount.isEmpty ? nil : Int(pumpingAmount)
        case .symptom:
            record.symptomType = symptomType.isEmpty ? nil : symptomType
            record.symptomSeverity = ["轻微", "中等", "严重"][symptomSeverity]
            record.temperature = temperature.isEmpty ? nil : Double(temperature)
        case .headCircumference:
            record.headCircumferenceCM = headCircumference.isEmpty ? nil : Double(headCircumference)
        case .tooth:
            record.toothName = toothName.isEmpty ? nil : toothName
        }
        try? modelContext.save()
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
