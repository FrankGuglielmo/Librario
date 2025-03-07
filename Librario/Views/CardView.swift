//
//  CardView.swift
//  Librario
//
//  Created by Frank Guglielmo on 3/7/25.
//

import SwiftUI

// Preference key for measuring content size
struct ContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// Preference key for button width
struct ButtonWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// TabView Component for the tabs at the top of the CardView
struct CardTabView: View {
    let title: String
    let isSelected: Bool
    let cardColor: CardColor
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? cardColor.primaryColor : cardColor.hoverColor)
                )
                .foregroundColor(cardColor.textColor)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// CardButtonView Component for displaying buttons in the card
struct CardButtonView: View {
    let button: CardButton
    let fixedWidth: CGFloat?
    
    init(button: CardButton, fixedWidth: CGFloat? = nil) {
        self.button = button
        self.fixedWidth = fixedWidth
    }
    
    var body: some View {
        Button(action: button.action) {
            Text(button.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(button.textColor)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .frame(width: fixedWidth)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(button.buttonColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(button.buttonBorderColor, lineWidth: 2)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ButtonWidthPreferenceKey.self,
                    value: geo.size.width
                )
            }
        )
    }
}

// SingleCardView Component for displaying a single card
struct SingleCardView: View {
    let card: Card
    let width: CGFloat
    let height: CGFloat
    let onClose: () -> Void
    
    @State private var contentSize: CGSize = .zero
    @State private var maxButtonWidth: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Card background with border using ZStack instead of overlay
            ZStack {
                // Outer rectangle (border)
                RoundedRectangle(cornerRadius: 20)
                    .fill(card.cardColor.borderColor)
                    .frame(width: width, height: height)
                
                // Inner rectangle (main color)
                RoundedRectangle(cornerRadius: 16)
                    .fill(card.cardColor.primaryColor)
                    .frame(width: width - 8, height: height - 8)
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(card.cardColor.textColor)
                            .padding(16)
                    }
                }
                Spacer()
            }
            
            // Card content
            VStack(spacing: 20) {
                // Title - more prominent
                Text(card.title)
                    .font(.system(size: width * 0.09, weight: .bold))
                    .foregroundColor(card.cardColor.textColor)
                    .padding(.top, 32)
                
                // Subtitle if available
                if let subtitle = card.subtitle {
                    Text(subtitle)
                        .font(.system(size: width * 0.05, weight: .medium))
                        .foregroundColor(card.cardColor.textColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Content in a ScrollView (conditionally scrollable) - bigger content
                GeometryReader { geo in
                    if contentSize.height > geo.size.height {
                        ScrollView {
                            card.content
                                .background(
                                    GeometryReader { contentGeometry in
                                        Color.clear.preference(
                                            key: ContentSizePreferenceKey.self,
                                            value: contentGeometry.size
                                        )
                                    }
                                )
                        }
                    } else {
                        card.content
                            .frame(maxWidth: .infinity)
                            .background(
                                GeometryReader { contentGeometry in
                                    Color.clear.preference(
                                        key: ContentSizePreferenceKey.self,
                                        value: contentGeometry.size
                                    )
                                }
                            )
                    }
                }
                .frame(maxHeight: height * 0.55)
                
                // Buttons - with uniform width
                VStack(spacing: 16) {
                    // First pass to measure button widths
                    if card.buttons.count > 0 && maxButtonWidth == 0 {
                        ForEach(card.buttons) { button in
                            CardButtonView(button: button)
                                .opacity(0)
                                .frame(height: 0)
                        }
                    }
                    
                    // Second pass to display buttons with uniform width
                    ForEach(card.buttons) { button in
                        CardButtonView(button: button, fixedWidth: maxButtonWidth > 0 ? maxButtonWidth : nil)
                    }
                }
                .onPreferenceChange(ButtonWidthPreferenceKey.self) { width in
                    if width > self.maxButtonWidth {
                        self.maxButtonWidth = width
                    }
                }
                .padding(.bottom, 32)
            }
            .frame(width: width * 0.9, height: height * 0.9)
        }
        .frame(width: width, height: height)
        .onPreferenceChange(ContentSizePreferenceKey.self) { size in
            self.contentSize = size
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(card.title) card")
    }
}

// Main CardView
struct CardView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let cards: [Card]
    @State private var selectedCardIndex: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let cardWidth = isCompact ? geometry.size.width * 0.9 : geometry.size.width * 0.6
            let cardHeight = isCompact ? geometry.size.height * 0.9 : geometry.size.height * 0.8
            
            ZStack {
                // Background
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Tabs (only if there are multiple cards)
                    if cards.count > 1 {
                        HStack(spacing: 0) {
                            ForEach(0..<cards.count, id: \.self) { index in
                                CardTabView(
                                    title: cards[index].title,
                                    isSelected: selectedCardIndex == index,
                                    cardColor: cards[index].cardColor,
                                    action: { selectedCardIndex = index }
                                )
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.bottom, 8)
                    }
                    
                    // Current card content
                    if !cards.isEmpty {
                        SingleCardView(
                            card: cards[selectedCardIndex],
                            width: cardWidth,
                            height: cardHeight,
                            onClose: { dismiss() }
                        )
                    }
                }
                .frame(width: cardWidth, height: cards.count > 1 ? cardHeight + 50 : cardHeight)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Sample card for preview - Light mode
            CardView(cards: [
                Card(
                    title: "Sample Card",
                    subtitle: "This is a sample subtitle",
                    cardColor: .sapphire,
                    buttons: [
                        CardButton(
                            title: "Primary Button",
                            cardColor: .sapphire,
                            action: {}
                        ),
                        CardButton(
                            title: "Secondary Button",
                            cardColor: .ruby,
                            action: {}
                        )
                    ]
                ) {
                    VStack(spacing: 16) {
                        Text("This is sample content")
                            .foregroundColor(.white)
                        Text("More content here")
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            ])
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            CardView(cards: [
                Card(
                    title: "Dark Mode Card",
                    subtitle: "Testing dark mode appearance",
                    cardColor: .amethyst,
                    buttons: [
                        CardButton(
                            title: "Action Button",
                            cardColor: .amethyst,
                            action: {}
                        )
                    ]
                ) {
                    VStack(spacing: 16) {
                        Text("Dark mode content")
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            ])
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
            
            // Multi-card preview
            CardView(cards: [
                Card(
                    title: "First Card",
                    cardColor: .crimson,
                    buttons: [
                        CardButton(
                            title: "Button 1",
                            cardColor: .crimson,
                            action: {}
                        )
                    ]
                ) {
                    Text("Content for first card")
                        .foregroundColor(.white)
                        .padding()
                },
                Card(
                    title: "Second Card",
                    cardColor: .emerald,
                    buttons: [
                        CardButton(
                            title: "Button 2",
                            cardColor: .emerald,
                            action: {}
                        )
                    ]
                ) {
                    Text("Content for second card")
                        .foregroundColor(.black)
                        .padding()
                }
            ])
            .previewDisplayName("Multiple Cards")
        }
    }
}
