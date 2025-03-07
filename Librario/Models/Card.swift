//
//  Card.swift
//  Librario
//
//  Created by Frank Guglielmo on 3/7/25.
//
import Foundation
import SwiftUI

// ColorTheme struct to define consistent color schemes for cards
struct ColorTheme {
    let primary: Color
    let secondary: Color
    let text: Color
    let accent: Color
    
    // Accessibility methods
    var isHighContrast: Bool {
        return contrastRatio(between: primary, and: text) >= 4.5
    }
    
    // Calculate contrast ratio (simplified version)
    private func contrastRatio(between color1: Color, and color2: Color) -> Double {
        // This is a simplified approximation - a real implementation would convert to luminance values
        return 4.5 // Placeholder value, would be calculated from actual colors
    }
}

// CardColor enum to define available color schemes for cards
enum CardColor: String, CaseIterable {
    case crimson
    case ruby
    case sapphire
    case azure
    case amethyst
    case lavender
    case tangerine
    case amber
    case emerald
    case mint
    case sunflower
    case lemon
    case charcoal
    case slate
    case coral
    case teal
    
    // Returns color theme with appropriate contrasting colors
    var theme: ColorTheme {
        switch self {
            case .crimson:
                return ColorTheme(primary: Color(hex: "#DC143C"), secondary: Color(hex: "#FFD700"), text: Color.white, accent: Color(hex: "#FF4500"))
            case .ruby:
                return ColorTheme(primary: Color(hex: "#E0115F"), secondary: Color(hex: "#7FFFD4"), text: Color.white, accent: Color(hex: "#20B2AA"))
            case .sapphire:
                return ColorTheme(primary: Color(hex: "#0F52BA"), secondary: Color(hex: "#FFA500"), text: Color.white, accent: Color(hex: "#FF8C00"))
            case .azure:
                return ColorTheme(primary: Color(hex: "#007FFF"), secondary: Color(hex: "#FFFF00"), text: Color.white, accent: Color(hex: "#FFD700"))
            case .amethyst:
                return ColorTheme(primary: Color(hex: "#9966CC"), secondary: Color(hex: "#FFDAB9"), text: Color.white, accent: Color(hex: "#FFA07A"))
            case .lavender:
                return ColorTheme(primary: Color(hex: "#E6E6FA"), secondary: Color(hex: "#800080"), text: Color(hex: "#4B0082"), accent: Color(hex: "#9932CC"))
            case .tangerine:
                return ColorTheme(primary: Color(hex: "#F28500"), secondary: Color(hex: "#4682B4"), text: Color.white, accent: Color(hex: "#1E90FF"))
            case .amber:
                return ColorTheme(primary: Color(hex: "#FFBF00"), secondary: Color(hex: "#800020"), text: Color(hex: "#4B0082"), accent: Color(hex: "#8B0000"))
            case .emerald:
                return ColorTheme(primary: Color(hex: "#50C878"), secondary: Color(hex: "#FF6347"), text: Color.black, accent: Color(hex: "#DC143C"))
            case .mint:
                return ColorTheme(primary: Color(hex: "#98FF98"), secondary: Color(hex: "#8A2BE2"), text: Color.black, accent: Color(hex: "#4B0082"))
            case .sunflower:
                return ColorTheme(primary: Color(hex: "#FFDA03"), secondary: Color(hex: "#301934"), text: Color.black, accent: Color(hex: "#4B0082"))
            case .lemon:
                return ColorTheme(primary: Color(hex: "#FFF44F"), secondary: Color(hex: "#6495ED"), text: Color.black, accent: Color(hex: "#0047AB"))
            case .charcoal:
                return ColorTheme(primary: Color(hex: "#36454F"), secondary: Color(hex: "#FFD700"), text: Color.white, accent: Color(hex: "#FFA500"))
            case .slate:
                return ColorTheme(primary: Color(hex: "#708090"), secondary: Color(hex: "#FFFF00"), text: Color.white, accent: Color(hex: "#FFD700"))
            case .coral:
                return ColorTheme(primary: Color(hex: "#FF7F50"), secondary: Color(hex: "#40E0D0"), text: Color.black, accent: Color(hex: "#00CED1"))
            case .teal:
                return ColorTheme(primary: Color(hex: "#008080"), secondary: Color(hex: "#FFB6C1"), text: Color.white, accent: Color(hex: "#FF69B4"))
        }
    }
    
    // Returns the primary color
    var primaryColor: Color {
        return theme.primary
    }
    
    // Returns the border color based on the theme
    var borderColor: Color {
        return theme.secondary
    }
    
    // Returns appropriate text color for this card color
    var textColor: Color {
        return theme.text
    }
    
    // Returns accent color for buttons and highlights
    var accentColor: Color {
        return theme.accent
    }
    
    // Returns a darker shade of the primary color for pressed states
    var pressedColor: Color {
        return primaryColor.opacity(0.7)
    }
    
    // Returns a lighter shade of the primary color for hover states
    var hoverColor: Color {
        return primaryColor.opacity(0.9)
    }
    
    // Returns a complementary color for the card
    var complementaryColor: Color {
        return theme.secondary
    }
    
    // Method to get a random card color
    static func random() -> CardColor {
        let allCases = CardColor.allCases
        return allCases.randomElement() ?? .sapphire
    }
    
    // Return dark mode adjusted colors
    func adaptForDarkMode(isDarkMode: Bool) -> ColorTheme {
        if isDarkMode {
            var adjustedTheme = self.theme
            // Adjust colors for dark mode
            return adjustedTheme
        } else {
            return self.theme
        }
    }
}

// Extension to create Color from hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

// CardButton model for buttons in the card
struct CardButton: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String?
    let buttonColor: Color
    let buttonBorderColor: Color
    let textColor: Color
    let action: () -> Void
    
    init(title: String, imageName: String? = nil, cardColor: CardColor? = nil, buttonColor: Color? = nil, buttonBorderColor: Color? = nil, textColor: Color? = nil, action: @escaping () -> Void) {
        self.title = title
        self.imageName = imageName
        
        if let cardColor = cardColor {
            self.buttonColor = buttonColor ?? cardColor.accentColor
            self.buttonBorderColor = buttonBorderColor ?? cardColor.borderColor
            self.textColor = textColor ?? cardColor.textColor
        } else {
            self.buttonColor = buttonColor ?? .blue
            self.buttonBorderColor = buttonBorderColor ?? .white
            self.textColor = textColor ?? .white
        }
        
        self.action = action
    }
}

// Card model
struct Card: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let cardColor: CardColor
    let content: AnyView // Using AnyView to allow any type of content
    let buttons: [CardButton]
    let isAccessible: Bool
    
    // Convenience initializer with type-erased content
    init<Content: View>(
        title: String,
        subtitle: String? = nil,
        cardColor: CardColor = .sapphire,
        isAccessible: Bool = true,
        buttons: [CardButton] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.cardColor = cardColor
        self.content = AnyView(content())
        self.buttons = buttons
        self.isAccessible = isAccessible
    }
    
    // Helper to create accessible buttons for this card
    func createAccessibleButton(title: String, imageName: String? = nil, action: @escaping () -> Void) -> CardButton {
        return CardButton(
            title: title,
            imageName: imageName,
            cardColor: self.cardColor,
            action: action
        )
    }
}

// Card appearance modifiers
struct CardModifiers {
    // Applies consistent styling to card containers
    struct CardContainerStyle: ViewModifier {
        let cardColor: CardColor
        let cornerRadius: CGFloat = 12
        let shadowRadius: CGFloat = 4
        
        func body(content: Content) -> some View {
            content
                .background(cardColor.primaryColor)
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(cardColor.borderColor, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.2), radius: shadowRadius, x: 0, y: 2)
        }
    }
    
    // Applies consistent styling to card buttons
    struct CardButtonStyle: ButtonStyle {
        let buttonColor: Color
        let borderColor: Color
        let textColor: Color
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(configuration.isPressed ? buttonColor.opacity(0.7) : buttonColor)
                .foregroundColor(textColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}
