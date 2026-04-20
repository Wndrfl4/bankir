import SwiftUI

// Глобальная тема приложения: цвета, отступы, радиусы и т.п.
public struct Theme {
    public static let cornerRadius: CGFloat = 16
    public static let largeCornerRadius: CGFloat = 28
    public static let sectionSpacing: CGFloat = 12
    public static let cardPadding: CGFloat = 16
    public static let cardBackground = Color(red: 0.95, green: 0.97, blue: 0.99)
    public static let secondaryCardBackground = Color.white.opacity(0.72)
    public static let accent = Color(red: 0.04, green: 0.39, blue: 0.78)
    public static let accentStrong = Color(red: 0.02, green: 0.26, blue: 0.58)
    public static let success = Color(red: 0.10, green: 0.60, blue: 0.37)
    public static let warning = Color(red: 0.90, green: 0.52, blue: 0.10)
    public static let danger = Color(red: 0.82, green: 0.20, blue: 0.22)
    public static let ink = Color(red: 0.09, green: 0.14, blue: 0.22)
    public static let mutedText = Color(red: 0.38, green: 0.45, blue: 0.55)
    
    public static let appBackground = LinearGradient(
        colors: [
            Color(red: 0.97, green: 0.98, blue: 1.00),
            Color(red: 0.91, green: 0.95, blue: 0.99),
            Color(red: 0.98, green: 0.96, blue: 0.93)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.34, blue: 0.70),
            Color(red: 0.09, green: 0.51, blue: 0.84),
            Color(red: 0.25, green: 0.69, blue: 0.78)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
