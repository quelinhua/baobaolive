import SwiftUI

extension Color {
    static var primary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "f0a8b3")) : UIColor(Color(hex: "834b55"))
        })
    }
    static var primaryContainer: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "5e2a34")) : UIColor(Color(hex: "ffb6c1"))
        })
    }
    static var onPrimary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "3a0e17")) : UIColor(Color(hex: "ffeff0"))
        })
    }
    static var onPrimaryContainer: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "ffb6c1")) : UIColor(Color(hex: "65323c"))
        })
    }
    static let secondary = Color(hex: "874e00")
    static let secondaryContainer = Color(hex: "ffc791")
    static let onSecondary = Color(hex: "fff0e5")
    static let onSecondaryContainer = Color(hex: "6a3c00")
    static let tertiary = Color(hex: "006b1b")
    static let tertiaryContainer = Color(hex: "91f78e")
    static let onTertiary = Color(hex: "d1ffc8")
    static let onTertiaryContainer = Color(hex: "005e17")
    static let error = Color(hex: "b31b25")
    static let errorContainer = Color(hex: "fb5151")
    static let onError = Color(hex: "ffefee")
    static let onErrorContainer = Color(hex: "570008")

    static var background: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "1a1c1e")) : UIColor(Color(hex: "f5f6f7"))
        })
    }
    static var onBackground: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "e2e3e4")) : UIColor(Color(hex: "2c2f30"))
        })
    }
    static var surface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "1a1c1e")) : UIColor(Color(hex: "f5f6f7"))
        })
    }
    static var onSurface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "e2e3e4")) : UIColor(Color(hex: "2c2f30"))
        })
    }
    static var surfaceVariant: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "3b3e40")) : UIColor(Color(hex: "dadddf"))
        })
    }
    static var onSurfaceVariant: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "c0c3c5")) : UIColor(Color(hex: "595c5d"))
        })
    }
    static var outline: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "8a8d8e")) : UIColor(Color(hex: "757778"))
        })
    }
    static var outlineVariant: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "454749")) : UIColor(Color(hex: "abadae"))
        })
    }
    static var surfaceContainerLowest: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "141618")) : UIColor(Color(hex: "ffffff"))
        })
    }
    static var surfaceContainerLow: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "1e2022")) : UIColor(Color(hex: "eff1f2"))
        })
    }
    static var surfaceContainer: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "222426")) : UIColor(Color(hex: "e6e8ea"))
        })
    }
    static var surfaceContainerHigh: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "2c2e30")) : UIColor(Color(hex: "e0e3e4"))
        })
    }
    static var surfaceContainerHighest: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "333537")) : UIColor(Color(hex: "dadddf"))
        })
    }
    static let surfaceDim = Color(hex: "d1d5d7")
    static let surfaceBright = Color(hex: "f5f6f7")
    static let inverseSurface = Color(hex: "0c0f10")
    static let inverseOnSurface = Color(hex: "9b9d9e")
    static let inversePrimary = Color(hex: "ffb6c1")
    static let surfaceTint = Color(hex: "834b55")
    static let primaryDim = Color(hex: "764049")
    static let secondaryDim = Color(hex: "764400")
    static let tertiaryDim = Color(hex: "005d16")
    static let primaryFixed = Color(hex: "ffb6c1")
    static let primaryFixedDim = Color(hex: "f0a8b3")
    static let secondaryFixed = Color(hex: "ffc791")
    static let secondaryFixedDim = Color(hex: "ffb467")
    static let tertiaryFixed = Color(hex: "91f78e")
    static let tertiaryFixedDim = Color(hex: "83e881")
    static let onPrimaryFixed = Color(hex: "4e1f29")
    static let onPrimaryFixedVariant = Color(hex: "703b45")
    static let onSecondaryFixed = Color(hex: "4f2c00")
    static let onSecondaryFixedVariant = Color(hex: "774400")
    static let onTertiaryFixed = Color(hex: "00480f")
    static let onTertiaryFixedVariant = Color(hex: "00691a")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
