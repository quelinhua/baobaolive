import SwiftUI

extension Color {
    static var primary: Color {
        let theme = ThemeManager.shared.selectedColorTheme
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: theme.primaryLight)) : UIColor(Color(hex: theme.primary))
        })
    }
    static var primaryContainer: Color {
        let theme = ThemeManager.shared.selectedColorTheme
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: theme.primary).opacity(0.3)) : UIColor(Color(hex: theme.primaryContainer))
        })
    }
    static var onPrimary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "3a0e17")) : UIColor(Color.white)
        })
    }
    static var onPrimaryContainer: Color {
        let theme = ThemeManager.shared.selectedColorTheme
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: theme.primaryContainer)) : UIColor(Color(hex: theme.primary))
        })
    }
    static var secondary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "ffb870")) : UIColor(Color(hex: "874e00"))
        })
    }
    static var secondaryContainer: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "5c3300")) : UIColor(Color(hex: "ffc791"))
        })
    }
    static var onSecondary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "4a2800")) : UIColor(Color(hex: "fff0e5"))
        })
    }
    static var onSecondaryContainer: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "ffc791")) : UIColor(Color(hex: "6a3c00"))
        })
    }
    static var tertiary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "6eff6b")) : UIColor(Color(hex: "006b1b"))
        })
    }
    static var tertiaryContainer: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "005314")) : UIColor(Color(hex: "91f78e"))
        })
    }
    static var onTertiary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "003a0d")) : UIColor(Color(hex: "d1ffc8"))
        })
    }
    static var onTertiaryContainer: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "91f78e")) : UIColor(Color(hex: "005e17"))
        })
    }
    static var error: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "ff897d")) : UIColor(Color(hex: "b31b25"))
        })
    }
    static var errorContainer: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "93000a")) : UIColor(Color(hex: "fb5151"))
        })
    }
    static var onError: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "690005")) : UIColor(Color(hex: "ffefee"))
        })
    }
    static var onErrorContainer: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "ffdad4")) : UIColor(Color(hex: "570008"))
        })
    }

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
    static var surfaceDim: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "141618")) : UIColor(Color(hex: "d1d5d7"))
        })
    }
    static var surfaceBright: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "3a3c3e")) : UIColor(Color(hex: "f5f6f7"))
        })
    }
    static var inverseSurface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "e2e3e4")) : UIColor(Color(hex: "0c0f10"))
        })
    }
    static var inverseOnSurface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "2c2f30")) : UIColor(Color(hex: "9b9d9e"))
        })
    }
    static var inversePrimary: Color {
        let theme = ThemeManager.shared.selectedColorTheme
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: theme.primary)) : UIColor(Color(hex: theme.primaryLight))
        })
    }
    static var surfaceTint: Color {
        ThemeManager.shared.currentPrimary
    }
    static var primaryDim: Color {
        ThemeManager.shared.currentPrimary.opacity(0.8)
    }
    static var secondaryDim: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "d69400")) : UIColor(Color(hex: "764400"))
        })
    }
    static var tertiaryDim: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "4bcc4a")) : UIColor(Color(hex: "005d16"))
        })
    }
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
