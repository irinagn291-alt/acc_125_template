import SwiftUI

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
            (a, r, g, b) = (255, 0, 0, 0)
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

// SolarStride — Solar Energy UI
enum AppColor {
    static let background = Color(hex: "#0F0B04")
    static let surface = Color(hex: "#1A1206")
    static let elevatedSurface = Color(hex: "#261C08")

    static let primary = Color(hex: "#FFC107")
    static let secondary = Color(hex: "#FF8F00")
    static let accent = Color(hex: "#FF5722")

    static let onPrimary = Color(hex: "#1A0E00")

    static let textPrimary = Color(hex: "#FFF8E7")
    static let textSecondary = Color(hex: "#C4A574")
    static let textMuted = Color(hex: "#8A7248")

    static let success = Color(hex: "#66BB6A")
    static let warning = Color(hex: "#FFB300")
    static let danger = Color(hex: "#E65100")
    static let info = Color(hex: "#FFD54F")

    static let protein = Color(hex: "#FFB74D")
    static let fat = Color(hex: "#FF9800")
    static let carbs = Color(hex: "#FFA000")
}
