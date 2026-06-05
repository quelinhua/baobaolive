import SwiftUI

extension RecordType {
    var iconColor: Color {
        switch self {
        case .feeding: return Color(hex: "C86F86")
        case .sleep: return Color(hex: "8D7AC3")
        case .diaper: return Color(hex: "5AA6A0")
        case .formula: return Color(hex: "B98242")
        case .poop: return Color(hex: "8B6B4F")
        case .growth: return Color(hex: "6FA66E")
        case .vaccine: return Color(hex: "D56A6A")
        case .babyFood: return Color(hex: "7EA96B")
        case .pumping: return Color(hex: "D58CA0")
        case .symptom: return Color(hex: "D45B5B")
        case .headCircumference: return Color(hex: "6F8FA6")
        case .tooth: return Color(hex: "C89B3C")
        }
    }

    var iconBackgroundColor: Color {
        iconColor.opacity(0.14)
    }
}
