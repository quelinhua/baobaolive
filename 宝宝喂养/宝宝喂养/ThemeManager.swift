import SwiftUI

enum AppColorTheme: String, CaseIterable, Identifiable {
    case cherryBlossom = "樱花粉"
    case mistRose = "雾玫瑰"
    case milkTea = "奶茶杏"
    case sageGreen = "鼠尾草"
    case mistBlue = "云雾蓝"
    case lavenderGray = "薰衣草灰"
    case warmPomelo = "暖柚橘"

    var id: String { rawValue }

    var isProOnly: Bool {
        switch self {
        case .cherryBlossom: return false
        default: return true
        }
    }

    var primary: String {
        switch self {
        case .cherryBlossom: return "A7566A"
        case .mistRose: return "9B5668"
        case .milkTea: return "856247"
        case .sageGreen: return "597A62"
        case .mistBlue: return "587491"
        case .lavenderGray: return "76689A"
        case .warmPomelo: return "9A6540"
        }
    }

    var primaryLight: String {
        switch self {
        case .cherryBlossom: return "F0B6C2"
        case .mistRose: return "D9A6B2"
        case .milkTea: return "D4B99F"
        case .sageGreen: return "A6C0AC"
        case .mistBlue: return "A7BAD0"
        case .lavenderGray: return "B9ADD4"
        case .warmPomelo: return "D7AD86"
        }
    }

    var primaryContainer: String {
        switch self {
        case .cherryBlossom: return "F9E1E6"
        case .mistRose: return "F6E1E7"
        case .milkTea: return "F3E8DD"
        case .sageGreen: return "E4EEE7"
        case .mistBlue: return "E4EDF6"
        case .lavenderGray: return "ECE7F6"
        case .warmPomelo: return "F4E5D8"
        }
    }

    var previewGradient: [Color] {
        [Color(hex: primary), Color(hex: primaryLight)]
    }
}

@Observable
class ThemeManager {
    static let shared = ThemeManager()

    @ObservationIgnored
    @AppStorage("selectedColorTheme") private var storedTheme: AppColorTheme = .cherryBlossom

    var selectedColorTheme: AppColorTheme = .cherryBlossom

    private init() {
        selectedColorTheme = storedTheme
    }

    var currentPrimary: Color {
        Color(hex: selectedColorTheme.primary)
    }

    var currentPrimaryLight: Color {
        Color(hex: selectedColorTheme.primaryLight)
    }

    var currentPrimaryContainer: Color {
        Color(hex: selectedColorTheme.primaryContainer)
    }

    func setTheme(_ theme: AppColorTheme) {
        if theme.isProOnly && !SubscriptionManager.shared.isProUser {
            return
        }
        storedTheme = theme
        selectedColorTheme = theme
    }
}
