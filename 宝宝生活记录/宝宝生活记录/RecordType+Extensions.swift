import SwiftUI

extension RecordType {
    var iconColor: Color {
        switch self {
        case .feeding: return Color.secondary
        case .sleep: return Color.primaryDim
        case .diaper: return Color.onSurfaceVariant
        case .formula: return Color.secondary
        case .poop: return Color.secondary
        case .growth: return Color.tertiary
        case .vaccine: return Color(hex: "FF6B6B")
        case .babyFood: return Color(hex: "4ECDC4")
        case .pumping: return Color.secondary
        case .symptom: return Color.error
        case .headCircumference: return Color(hex: "96CEB4")
        case .tooth: return Color.primary
        }
    }

    var iconBackgroundColor: Color {
        switch self {
        case .feeding: return Color.secondaryContainer.opacity(0.3)
        case .sleep: return Color.primaryContainer.opacity(0.3)
        case .diaper: return Color.surfaceVariant.opacity(0.3)
        case .formula: return Color.secondaryContainer.opacity(0.3)
        case .poop: return Color.secondaryContainer.opacity(0.3)
        case .growth: return Color.tertiaryContainer.opacity(0.3)
        case .vaccine: return Color(hex: "FF6B6B").opacity(0.15)
        case .babyFood: return Color(hex: "4ECDC4").opacity(0.15)
        case .pumping: return Color.secondaryContainer.opacity(0.3)
        case .symptom: return Color.error.opacity(0.15)
        case .headCircumference: return Color(hex: "96CEB4").opacity(0.15)
        case .tooth: return Color.primaryContainer.opacity(0.3)
        }
    }
}
