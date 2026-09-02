import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(hex: "#2563EB")
    static let background = Color(uiColor: .systemGroupedBackground)
    static let rowBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let divider = Color.primary.opacity(0.09)
    static let rowCorner: CGFloat = 10
    static let courseCorner: CGFloat = 6
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red, green, blue: Double
        if cleaned.count == 6 {
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        } else {
            red = 0.15
            green = 0.39
            blue = 0.92
        }
        self.init(red: red, green: green, blue: blue)
    }
}

