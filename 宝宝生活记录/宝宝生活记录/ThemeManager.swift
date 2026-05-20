import SwiftUI

enum AppColorTheme: String, CaseIterable, Identifiable {
    case cherryBlossom = "樱花粉"
    case skyBlue = "天空蓝"
    case mintGreen = "薄荷绿"
    case lavender = "薰衣草紫"
    case warmOrange = "暖阳橙"
    case oceanBlue = "海洋蓝"
    case roseRed = "玫瑰红"
    case forestGreen = "森林绿"
    case peachPink = "蜜桃粉"

    var id: String { rawValue }

    var isProOnly: Bool {
        switch self {
        case .cherryBlossom: return false
        default: return true
        }
    }

    var primary: String {
        switch self {
        case .cherryBlossom: return "834b55"
        case .skyBlue: return "4A90D9"
        case .mintGreen: return "2ECC71"
        case .lavender: return "9B59B6"
        case .warmOrange: return "E67E22"
        case .oceanBlue: return "3498DB"
        case .roseRed: return "E74C3C"
        case .forestGreen: return "27AE60"
        case .peachPink: return "FF8A80"
        }
    }

    var primaryLight: String {
        switch self {
        case .cherryBlossom: return "f0a8b3"
        case .skyBlue: return "87BDE9"
        case .mintGreen: return "7DCEA0"
        case .lavender: return "C39BD3"
        case .warmOrange: return "F0B27A"
        case .oceanBlue: return "7FB3D8"
        case .roseRed: return "F1948A"
        case .forestGreen: return "82E0AA"
        case .peachPink: return "FFB3AD"
        }
    }

    var primaryContainer: String {
        switch self {
        case .cherryBlossom: return "ffb6c1"
        case .skyBlue: return "B8D4F0"
        case .mintGreen: return "A9DFBF"
        case .lavender: return "D7BDE2"
        case .warmOrange: return "FAD7A0"
        case .oceanBlue: return "AED6F1"
        case .roseRed: return "F5B7B1"
        case .forestGreen: return "ABEBC6"
        case .peachPink: return "FFCDC7"
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
        storedTheme = theme
        selectedColorTheme = theme
    }
}
