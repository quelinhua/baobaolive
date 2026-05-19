import Foundation
import SwiftData

enum RecordType: String, Codable, CaseIterable, Identifiable {
    case feeding
    case sleep
    case diaper
    case formula
    case poop
    case growth
    case vaccine
    case babyFood
    case pumping
    case symptom
    case headCircumference
    case tooth

    static var defaultHomePage: [String] {
        ["feeding", "sleep", "diaper", "formula", "poop", "growth"]
    }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .feeding: return "母乳喂养"
        case .sleep: return "睡眠记录"
        case .diaper: return "更换尿布"
        case .formula: return "配方奶粉"
        case .poop: return "大便记录"
        case .growth: return "身高体重"
        case .vaccine: return "疫苗接种"
        case .babyFood: return "辅食添加"
        case .pumping: return "吸奶记录"
        case .symptom: return "症状记录"
        case .headCircumference: return "头围记录"
        case .tooth: return "出牙记录"
        }
    }

    var iconName: String {
        switch self {
        case .feeding: return "figure.child.and.lock.fill"
        case .sleep: return "bed.double.fill"
        case .diaper: return "tshirt.fill"
        case .formula: return "waterbottle.fill"
        case .poop: return "allergens"
        case .growth: return "scalemass.fill"
        case .vaccine: return "syringe.fill"
        case .babyFood: return "fork.knife"
        case .pumping: return "drop.fill"
        case .symptom: return "heart.text.square.fill"
        case .headCircumference: return "brain.head.profile.fill"
        case .tooth: return "face.smiling.inverse"
        }
    }
}

@Model
final class BabyProfile {
    var name: String
    var birthDate: Date
    var gender: String
    var isSelected: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \RecordModel.babyProfile)
    var records: [RecordModel] = []

    init(name: String, birthDate: Date, gender: String = "女") {
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
    }

    var ageDescription: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: birthDate, to: Date())
        let months = components.month ?? 0
        let days = components.day ?? 0
        return "\(months)个月\(days)天"
    }

    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: birthDate, to: Date())
        return components.month ?? 0
    }
}

@Model
final class RecordModel {
    var type: String
    var timestamp: Date
    var note: String

    var babyProfile: BabyProfile?

    var breastSide: String?
    var feedingAmountML: Int?
    var feedingDurationMin: Int?

    var sleepEndTime: Date?

    var formulaAmountML: Int?
    var formulaBrand: String?

    var diaperType: String?

    var poopColor: String?
    var poopTexture: String?

    var heightCM: Double?
    var weightKG: Double?

    var vaccineName: String?
    var vaccineBatch: String?
    var vaccineSite: String?
    var vaccineReaction: String?

    var babyFoodName: String?
    var babyFoodAmount: String?
    var babyFoodReaction: String?

    var pumpingSide: String?
    var pumpingDurationMin: Int?
    var pumpingAmountML: Int?

    var symptomType: String?
    var symptomSeverity: String?
    var temperature: Double?

    var headCircumferenceCM: Double?

    var toothName: String?

    init(type: RecordType, timestamp: Date, note: String = "") {
        self.type = type.rawValue
        self.timestamp = timestamp
        self.note = note
    }

    var recordType: RecordType {
        RecordType(rawValue: type) ?? .feeding
    }

    var sleepDurationMinutes: Int? {
        guard let endTime = sleepEndTime else { return nil }
        return Int(endTime.timeIntervalSince(timestamp)) / 60
    }

    var sleepDurationText: String? {
        guard let minutes = sleepDurationMinutes else { return nil }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 { return "\(hours)小时\(mins)分钟" }
        if hours > 0 { return "\(hours)小时" }
        return "\(mins)分钟"
    }

    var displaySummary: String {
        switch recordType {
        case .feeding:
            var parts: [String] = []
            if let side = breastSide { parts.append(side + "喂奶") }
            if let duration = feedingDurationMin { parts.append("\(duration)分钟") }
            if let amount = feedingAmountML { parts.append("\(amount)ml") }
            return parts.isEmpty ? "母乳喂养" : parts.joined(separator: " ")
        case .sleep:
            return sleepDurationText ?? "睡眠记录"
        case .diaper:
            return diaperType ?? "更换尿布"
        case .formula:
            var parts: [String] = []
            if let brand = formulaBrand, !brand.isEmpty { parts.append(brand) }
            if let amount = formulaAmountML { parts.append("\(amount)ml") }
            return parts.isEmpty ? "配方奶" : parts.joined(separator: " ")
        case .poop:
            var parts: [String] = []
            if let color = poopColor { parts.append(color) }
            if let texture = poopTexture { parts.append(texture) }
            return parts.isEmpty ? "大便记录" : parts.joined(separator: " ")
        case .growth:
            var parts: [String] = []
            if let h = heightCM { parts.append("身高:\(String(format: "%.1f", h))cm") }
            if let w = weightKG { parts.append("体重:\(String(format: "%.1f", w))kg") }
            return parts.isEmpty ? "身高体重" : parts.joined(separator: " ")
        case .vaccine:
            return vaccineName ?? "疫苗接种"
        case .babyFood:
            var parts: [String] = []
            if let name = babyFoodName { parts.append(name) }
            if let reaction = babyFoodReaction { parts.append(reaction) }
            return parts.isEmpty ? "辅食添加" : parts.joined(separator: " ")
        case .pumping:
            var parts: [String] = []
            if let side = pumpingSide { parts.append(side) }
            if let amount = pumpingAmountML { parts.append("\(amount)ml") }
            return parts.isEmpty ? "吸奶记录" : parts.joined(separator: " ")
        case .symptom:
            var parts: [String] = []
            if let type = symptomType { parts.append(type) }
            if let temp = temperature { parts.append("\(String(format: "%.1f", temp))°C") }
            return parts.isEmpty ? "症状记录" : parts.joined(separator: " ")
        case .headCircumference:
            if let cm = headCircumferenceCM { return "头围:\(String(format: "%.1f", cm))cm" }
            return "头围记录"
        case .tooth:
            return toothName ?? "出牙记录"
        }
    }
}
