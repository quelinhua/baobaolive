import SwiftUI
import SwiftData

struct AddRecordView: View {
    let recordType: RecordType
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var notes = ""
    @State private var amount = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var autoFillTime = true
    @State private var selectedPoopColor = 2
    @State private var selectedPoopTexture = 1
    @State private var selectedBreastSide = 0
    @State private var selectedDiaperType = 0
    @State private var formulaBrand = ""
    @State private var vaccineName = ""
    @State private var vaccineBatch = ""
    @State private var vaccineSite = ""
    @State private var vaccineReaction = ""
    @State private var babyFoodName = ""
    @State private var babyFoodAmount = ""
    @State private var babyFoodReaction = ""
    @State private var pumpingSide = 0
    @State private var pumpingDuration = ""
    @State private var pumpingAmount = ""
    @State private var symptomType = ""
    @State private var symptomSeverity = 0
    @State private var temperature = ""
    @State private var headCircumference = ""
    @State private var toothName = ""
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false
    @State private var showError = false
    @State private var errorMessage = ""

    let poopColors: [(String, Color)] = [
        ("金黄", Color(hex: "E8B931")),
        ("深绿", Color(hex: "6B8E23")),
        ("棕色", Color(hex: "8B4513")),
        ("灰土", Color(hex: "D2B48C")),
        ("黑色", Color(hex: "3D2B1F"))
    ]

    let poopTextures = ["正常", "稀便", "硬便", "泡沫", "粘液", "颗粒", "蛋花汤", "血丝"]
    let breastSides = ["左侧", "右侧", "双侧"]
    let diaperTypes = ["湿的", "干的", "混合"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            formContent
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
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.primary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(recordType.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18))
                            .foregroundColor(Color.primary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var formContent: some View {
        switch recordType {
        case .poop:
            poopFormContent
        case .feeding:
            feedingFormContent
        case .sleep:
            sleepFormContent
        case .diaper:
            diaperFormContent
        case .formula:
            formulaFormContent
        case .growth:
            growthFormContent
        case .vaccine:
            vaccineFormContent
        case .babyFood:
            babyFoodFormContent
        case .pumping:
            pumpingFormContent
        case .symptom:
            symptomFormContent
        case .headCircumference:
            headCircumferenceFormContent
        case .tooth:
            toothFormContent
        }
    }

    // MARK: - 母乳喂养
    var feedingFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection

            autoFillSection

            VStack(spacing: 12) {
                sectionLabel("喂奶部位")

                HStack(spacing: 12) {
                    ForEach(0..<breastSides.count, id: \.self) { index in
                        Button(action: { selectedBreastSide = index }) {
                            Text(breastSides[index])
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

    // MARK: - 睡眠记录
    var sleepFormContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                sectionLabel("开始时间")
                timeCard(time: startTime, label: "入睡时间")
            }

            VStack(spacing: 12) {
                sectionLabel("结束时间")
                timeCard(time: endTime, label: "醒来时间", isStartTime: false)
            }

            autoFillSection

            VStack(spacing: 12) {
                sectionLabel("睡眠时长")

                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.primaryDim)
                        .frame(width: 44, height: 44)
                        .background(Color.primaryContainer.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text(calculateSleepDuration())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.onSurface)

                    Spacer()

                    Text("自动计算")
                        .font(.system(size: 12))
                        .foregroundColor(Color.outline)
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.primary.opacity(0.08), radius: 12, y: 4)
            }

            notesSection
        }
    }

    // MARK: - 更换尿布
    var diaperFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection

            autoFillSection

            VStack(spacing: 12) {
                sectionLabel("尿布状态")

                HStack(spacing: 12) {
                    ForEach(0..<diaperTypes.count, id: \.self) { index in
                        Button(action: { selectedDiaperType = index }) {
                            VStack(spacing: 8) {
                                Image(systemName: diaperIcon(index))
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedDiaperType == index ? Color.onPrimaryContainer : Color.secondary)

                                Text(diaperTypes[index])
                                    .font(.system(size: 14, weight: selectedDiaperType == index ? .bold : .medium))
                                    .foregroundColor(selectedDiaperType == index ? Color.onPrimaryContainer : Color.onSurface)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selectedDiaperType == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }

            notesSection
        }
    }

    // MARK: - 配方奶粉
    var formulaFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection

            autoFillSection

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

    // MARK: - 身高体重
    var growthFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection

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

    // MARK: - 疫苗接种
    var vaccineFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection
            autoFillSection

            VStack(spacing: 12) {
                sectionLabel("疫苗名称")
                HStack {
                    Image(systemName: "syringe.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "FF6B6B").opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("如：乙肝疫苗、百白破", text: $vaccineName)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            VStack(spacing: 12) {
                sectionLabel("疫苗批号 (可选)")
                HStack {
                    Image(systemName: "barcode")
                        .font(.system(size: 18))
                        .foregroundColor(Color.outline)
                        .frame(width: 44, height: 44)
                        .background(Color.surfaceVariant.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("输入批号", text: $vaccineBatch)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            VStack(spacing: 12) {
                sectionLabel("接种部位 (可选)")
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
                sectionLabel("接种反应 (可选)")
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

    // MARK: - 辅食添加
    var babyFoodFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection
            autoFillSection

            VStack(spacing: 12) {
                sectionLabel("食物名称")
                HStack {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "4ECDC4"))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "4ECDC4").opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("如：米粉、南瓜泥、苹果泥", text: $babyFoodName)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            VStack(spacing: 12) {
                sectionLabel("食用量 (可选)")
                HStack {
                    Image(systemName: "scalemass")
                        .font(.system(size: 18))
                        .foregroundColor(Color.outline)
                        .frame(width: 44, height: 44)
                        .background(Color.surfaceVariant.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    TextField("如：30g、半碗", text: $babyFoodAmount)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(16)
                .background(Color.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            VStack(spacing: 12) {
                sectionLabel("接受度 / 过敏反应 (可选)")
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

    // MARK: - 吸奶记录
    var pumpingFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection
            autoFillSection

            VStack(spacing: 12) {
                sectionLabel("吸奶部位")
                HStack(spacing: 12) {
                    ForEach(0..<breastSides.count, id: \.self) { index in
                        Button(action: { pumpingSide = index }) {
                            Text(breastSides[index])
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
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.secondaryContainer.opacity(0.2))
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

    // MARK: - 症状记录
    var symptomFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection
            autoFillSection

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
                        .foregroundColor(Color.error)
                        .frame(width: 44, height: 44)
                        .background(Color.error.opacity(0.15))
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

    // MARK: - 头围记录
    var headCircumferenceFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection
            autoFillSection

            VStack(spacing: 12) {
                sectionLabel("头围 (cm)")
                HStack {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "96CEB4"))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "96CEB4").opacity(0.15))
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

    // MARK: - 出牙记录
    var toothFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection
            autoFillSection

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

    // MARK: - 大便记录
    var poopFormContent: some View {
        VStack(spacing: 24) {
            timeCardSection

            autoFillSection

            VStack(spacing: 12) {
                sectionLabel("大便颜色")

                HStack(spacing: 16) {
                    ForEach(0..<poopColors.count, id: \.self) { index in
                        Button(action: { selectedPoopColor = index }) {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(poopColors[index].1)
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedPoopColor == index ? Color.primary : Color.clear, lineWidth: 3)
                                            .padding(2)
                                    )

                                Text(poopColors[index].0)
                                    .font(.system(size: 10, weight: selectedPoopColor == index ? .bold : .medium))
                                    .foregroundColor(selectedPoopColor == index ? Color.primary : Color.onSurfaceVariant)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
                .background(Color.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            VStack(spacing: 12) {
                sectionLabel("形状与质地")

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(0..<poopTextures.count, id: \.self) { index in
                        Button(action: { selectedPoopTexture = index }) {
                            Text(poopTextures[index])
                                .font(.system(size: 14, weight: selectedPoopTexture == index ? .bold : .medium))
                                .foregroundColor(selectedPoopTexture == index ? Color.onPrimaryContainer : Color.onSurface)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedPoopTexture == index ? Color.primaryContainer : Color.surfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }

            notesSection
        }
    }

    // MARK: - 公共组件
    func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.onSurfaceVariant)
                .textCase(.uppercase)
            Spacer()
        }
    }

    var timeCardSection: some View {
        VStack(spacing: 12) {
            sectionLabel("时间")
            timeCard(time: startTime, label: "今天")
        }
    }

    func timeCard(time: Date, label: String, isStartTime: Bool = true) -> some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.primary)
                    .frame(width: 44, height: 44)
                    .background(Color.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(time, style: .time)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.onSurface)
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundColor(Color.onSurfaceVariant)
                }
            }

            Spacer()

            Button("编辑") {
                if isStartTime {
                    if autoFillTime { startTime = Date() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        showStartTimePicker = true
                    }
                } else {
                    if autoFillTime { endTime = Date() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        showEndTimePicker = true
                    }
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color.onPrimaryContainer)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color.primaryContainer)
            .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.primary.opacity(0.08), radius: 12, y: 4)
        .sheet(isPresented: isStartTime ? $showStartTimePicker : $showEndTimePicker) {
            timePickerSheet(date: isStartTime ? $startTime : $endTime, title: label)
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
                    showStartTimePicker = false
                    showEndTimePicker = false
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showStartTimePicker = false
                        showEndTimePicker = false
                    }
                }
            }
        }
    }

    var autoFillSection: some View {
        HStack(spacing: 8) {
            Button(action: { autoFillTime.toggle() }) {
                Image(systemName: autoFillTime ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(autoFillTime ? Color.primary : Color.outline)
            }

            Text("自动填充当前时间")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.onSurfaceVariant)

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

    var saveButton: some View {
        Button(action: {
            if validateInput() {
                saveRecord()
                dismiss()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("保存记录")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(Color.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: Color.primary.opacity(0.3), radius: 8, y: 4)
        }
        .alert("输入错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - 输入验证
    func validateInput() -> Bool {
        switch recordType {
        case .sleep:
            if endTime <= startTime {
                errorMessage = "结束时间必须晚于开始时间"
                showError = true
                return false
            }
        case .feeding:
            if !amount.isEmpty, Int(amount) == nil || (Int(amount) ?? 0) <= 0 {
                errorMessage = "请输入有效的奶量（正整数）"
                showError = true
                return false
            }
        case .formula:
            if !amount.isEmpty, Int(amount) == nil || (Int(amount) ?? 0) <= 0 {
                errorMessage = "请输入有效的奶粉量（正整数）"
                showError = true
                return false
            }
        case .growth:
            if !height.isEmpty, Double(height) == nil || (Double(height) ?? 0) <= 0 {
                errorMessage = "请输入有效的身高"
                showError = true
                return false
            }
            if !weight.isEmpty, Double(weight) == nil || (Double(weight) ?? 0) <= 0 {
                errorMessage = "请输入有效的体重"
                showError = true
                return false
            }
        case .pumping:
            if !pumpingAmount.isEmpty, Int(pumpingAmount) == nil || (Int(pumpingAmount) ?? 0) <= 0 {
                errorMessage = "请输入有效的吸奶量（正整数）"
                showError = true
                return false
            }
        case .symptom:
            if !temperature.isEmpty, Double(temperature) == nil {
                errorMessage = "请输入有效的体温"
                showError = true
                return false
            }
        case .headCircumference:
            if !headCircumference.isEmpty, Double(headCircumference) == nil || (Double(headCircumference) ?? 0) <= 0 {
                errorMessage = "请输入有效的头围"
                showError = true
                return false
            }
        default:
            break
        }
        return true
    }

    // MARK: - 辅助函数
    func calculateSleepDuration() -> String {
        let duration = endTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }

    func diaperIcon(_ index: Int) -> String {
        switch index {
        case 0: return "drop.fill"
        case 1: return "checkmark.circle.fill"
        case 2: return "circle.grid.2x2.fill"
        default: return "circle.fill"
        }
    }

    func saveRecord() {
        let record = RecordModel(
            type: recordType,
            timestamp: startTime,
            note: notes
        )

        let babyManager = BabyManager.shared
        let descriptor = FetchDescriptor<BabyProfile>()
        if let babies = try? modelContext.fetch(descriptor), let baby = babyManager.getSelectedBaby(from: babies) {
            record.babyProfile = baby
        }

        switch recordType {
        case .feeding:
            record.breastSide = breastSides[selectedBreastSide]
            if !amount.isEmpty, let ml = Int(amount) { record.feedingAmountML = ml }
        case .sleep:
            record.sleepEndTime = endTime
        case .diaper:
            record.diaperType = diaperTypes[selectedDiaperType]
        case .formula:
            if !amount.isEmpty, let ml = Int(amount) { record.formulaAmountML = ml }
            if !formulaBrand.isEmpty { record.formulaBrand = formulaBrand }
        case .poop:
            record.poopColor = poopColors[selectedPoopColor].0
            record.poopTexture = poopTextures[selectedPoopTexture]
        case .growth:
            if !height.isEmpty, let h = Double(height) { record.heightCM = h }
            if !weight.isEmpty, let w = Double(weight) { record.weightKG = w }
        case .vaccine:
            if !vaccineName.isEmpty { record.vaccineName = vaccineName }
            if !vaccineBatch.isEmpty { record.vaccineBatch = vaccineBatch }
            if !vaccineSite.isEmpty { record.vaccineSite = vaccineSite }
            if !vaccineReaction.isEmpty { record.vaccineReaction = vaccineReaction }
        case .babyFood:
            if !babyFoodName.isEmpty { record.babyFoodName = babyFoodName }
            if !babyFoodAmount.isEmpty { record.babyFoodAmount = babyFoodAmount }
            if !babyFoodReaction.isEmpty { record.babyFoodReaction = babyFoodReaction }
        case .pumping:
            record.pumpingSide = breastSides[pumpingSide]
            if !pumpingDuration.isEmpty, let min = Int(pumpingDuration) { record.pumpingDurationMin = min }
            if !pumpingAmount.isEmpty, let ml = Int(pumpingAmount) { record.pumpingAmountML = ml }
        case .symptom:
            if !symptomType.isEmpty { record.symptomType = symptomType }
            record.symptomSeverity = ["轻微", "中等", "严重"][symptomSeverity]
            if !temperature.isEmpty, let t = Double(temperature) { record.temperature = t }
        case .headCircumference:
            if !headCircumference.isEmpty, let cm = Double(headCircumference) { record.headCircumferenceCM = cm }
        case .tooth:
            if !toothName.isEmpty { record.toothName = toothName }
        }

        modelContext.insert(record)
        schedulePostRecordNotifications()
    }

    func schedulePostRecordNotifications() {
        let defaults = UserDefaults.standard
        let feedingInterval = defaults.integer(forKey: "feedingIntervalHours")
        let sleepInterval = defaults.integer(forKey: "sleepIntervalHours")
        let diaperInterval = defaults.integer(forKey: "diaperIntervalHours")

        let descriptor = FetchDescriptor<RecordModel>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let allRecs = (try? modelContext.fetch(descriptor)) ?? []

        let lastFeeding = allRecs.first(where: { $0.recordType == .feeding })?.timestamp
        let lastSleep = allRecs.first(where: { $0.recordType == .sleep })?.timestamp
        let lastDiaper = allRecs.first(where: { $0.recordType == .diaper || $0.recordType == .poop })?.timestamp

        NotificationManager.shared.scheduleReminders(
            feedingInterval: feedingInterval > 0 ? feedingInterval : 3,
            sleepInterval: sleepInterval > 0 ? sleepInterval : 6,
            diaperInterval: diaperInterval > 0 ? diaperInterval : 3,
            lastFeeding: lastFeeding,
            lastSleep: lastSleep,
            lastDiaper: lastDiaper
        )
    }
}

#Preview {
    AddRecordView(recordType: .feeding)
}
