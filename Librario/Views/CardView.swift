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

// Preference key for tab width
struct TabWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// TabView Component for the tabs at the top of the CardView
struct CardTabView: View {
    let card: Card
    let isSelected: Bool
    let tabSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: card.tabIcon)
                .font(.system(size: 20))
                .foregroundColor(card.cardColor.theme.icon)
                .frame(width: tabSize, height: tabSize)
                .background(
                    Rectangle()
                        .fill(card.cardColor.borderColor)
                        .cornerRadius(6, corners: [.topLeft, .topRight]) // Only round the top corners
                )
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: TabWidthPreferenceKey.self,
                    value: max(geo.size.width, geo.size.height) // Make tabs square
                )
            }
        )
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Custom shape for rounded corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
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

// SingleCardView Component with simplified dynamic scrolling
struct SingleCardView: View {
    let card: Card
    let width: CGFloat
    let height: CGFloat
    let onClose: () -> Void
    
    @State private var maxButtonWidth: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // Calculate available content height based on card dimensions
    private var contentAreaHeight: CGFloat {
        // Allocate space for title, subtitle, buttons and padding
        let titleHeight: CGFloat = width * 0.09 + 40 // Font size + padding
        let subtitleHeight: CGFloat = card.subtitle != nil ? (width * 0.05 + 20) : 0
        let buttonAreaHeight: CGFloat = CGFloat(card.buttons.count) * 60 + 40 // Approx button height + spacing + padding
        
        // Allocate remaining space to content area (with some margin)
        return height * 0.9 - titleHeight - subtitleHeight - buttonAreaHeight
    }
    
    var body: some View {
        ZStack {
            // Card background with border using ZStack
            ZStack {
                // Outer rectangle (border)
                RoundedRectangle(cornerRadius: 20)
                    .fill(card.cardColor.borderColor)
                    .frame(width: width, height: height)
                
                // Inner rectangle (main color)
                RoundedRectangle(cornerRadius: 20)
                    .fill(card.cardColor.primaryColor)
                    .frame(width: width - 20, height: height - 20)
            }
            
            // Close button (only if not disabled)
            if !card.isCloseDisabled {
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
            }
            
            // Card content
            VStack(spacing: 20) {
                // Title
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
                
                // Content area with adaptive scrolling
                AdaptiveScrollView {
                    card.content
                        .frame(width: width * 0.85)
                }
                .frame(maxHeight: contentAreaHeight)
                
                // Buttons - with uniform width
                VStack(spacing: 16) {
                    ForEach(card.buttons) { button in
                        CardButtonView(button: button)
                    }
                }
                .padding(.bottom, 32)
            }
            .frame(width: width * 0.9, height: height * 0.9)
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(card.title) card")
    }
}

// A simplified adaptive scroll view that automatically provides scrolling when needed
struct AdaptiveScrollView<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isAtBottom: Bool = false
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack(alignment: .bottom) {
                // Main ScrollView
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Actual content
                        content
                        
                        // Bottom detector view with ID for scrolling
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: BottomDetectorKey.self,
                                            value: geo.frame(in: .named("scrollView")).minY)
                                .frame(height: 1)
                                .id("bottomAnchor")
                        }
                        .frame(height: 1)
                    }
                    .background(
                        // Height measuring view
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    // Measure content height on appear
                                    contentHeight = geometry.size.height
                                }
                                .onChange(of: geometry.size.height) { oldHeight, newHeight in
                                    // Update height if content changes
                                    contentHeight = newHeight
                                }
                        }
                    )
                }
                .overlay(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                // Measure scroll view height on appear
                                scrollViewHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size.height) { oldHeight, newHeight in
                                // Update height if container changes
                                scrollViewHeight = newHeight
                            }
                    }
                )
                .coordinateSpace(name: "scrollView")
                .background(
                    // Track scroll position
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scrollView")).minY
                            )
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = -value
                }
                .onPreferenceChange(BottomDetectorKey.self) { value in
                    // Check if bottom indicator is visible in the scroll view
                    let threshold: CGFloat = 20
                    isAtBottom = value < scrollViewHeight + threshold
                }
                
                // Scroll indicator button
                if contentHeight > scrollViewHeight + 10 {
                    Button(action: {
                        // Animate scrolling to bottom
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isAtBottom = true // Pre-emptively set state for visual feedback
                            scrollProxy.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }) {
                        Image(systemName: "chevron.compact.down")
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 20)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 4)
                    .opacity(isAtBottom ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isAtBottom)
                }
            }
        }
    }
}

// New preference key for bottom detection
struct BottomDetectorKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Preference key for scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Extension to make it easier to create adaptive Text inside cards
extension View {
    func adaptiveCardText(color: Color) -> some View {
        self
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// Main CardView
struct CardView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let cards: [Card]
    @State private var selectedCardIndex: Int = 0
    @State private var tabSize: CGFloat = 55 // Default tab size
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let cardWidth = isCompact ? geometry.size.width * 0.9 : geometry.size.width * 0.7
            let cardHeight = isCompact ? geometry.size.height * 0.8 : geometry.size.height * 0.8
            
            VStack(spacing: 0) {
                // Tabs (only if there are multiple cards)
                if cards.count > 1 {
                    // First pass to measure tab sizes
                    ZStack {
                        ForEach(0..<cards.count, id: \.self) { index in
                            CardTabView(
                                card: cards[index],
                                isSelected: false,
                                tabSize: 0,
                                action: {}
                            )
                            .opacity(0)
                        }
                    }
                    .frame(height: 0)
                    .onPreferenceChange(TabWidthPreferenceKey.self) { width in
                        if width > self.tabSize {
                            self.tabSize = width
                        }
                    }
                    
                    // Second pass to display tabs with uniform size
                    HStack(spacing: 24) {
                        ForEach(0..<cards.count, id: \.self) { index in
                            CardTabView(
                                card: cards[index],
                                isSelected: selectedCardIndex == index,
                                tabSize: tabSize,
                                action: { selectedCardIndex = index }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .zIndex(1) // Ensure tabs are above the card
                }
                
                // Current card content
                if !cards.isEmpty {
                    SingleCardView(
                        card: cards[selectedCardIndex],
                        width: cardWidth,
                        height: cardHeight,
                        onClose: { dismiss() }
                    )
                    .zIndex(0) // Card is below the tabs
                }
            }
            .frame(width: cardWidth, height: cards.count > 1 ? cardHeight + 8 : cardHeight)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
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
                    tabIcon: "star.fill",
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
            
            // Card with disabled close button
            CardView(cards: [
                Card(
                    title: "No Close Button",
                    subtitle: "This card has the close button disabled",
                    cardColor: .crimson,
                    tabIcon: "lock.fill",
                    isCloseDisabled: true,
                    buttons: [
                        CardButton(
                            title: "OK",
                            cardColor: .crimson,
                            action: {}
                        )
                    ]
                ) {
                    VStack(spacing: 16) {
                        Text("This card cannot be closed with the X button")
                            .foregroundColor(.white)
                        Text("It must be dismissed programmatically")
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            ])
            .previewDisplayName("Disabled Close Button")
            
            // Dark mode preview
            CardView(cards: [
                Card(
                    title: "Dark Mode Card",
                    subtitle: "Testing dark mode appearance",
                    cardColor: .amethyst,
                    tabIcon: "moon.fill",
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
                    cardColor: .tangerine,
                    tabIcon: "gift.fill",
                    buttons: [
                        CardButton(
                            title: "Button 1",
                            cardColor: .tangerine,
                            action: {}
                        )
                    ]
                ) {
                    VStack{
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                        Text("Content for first card")
                            .foregroundColor(.white)
                            .padding()
                    }
                },
                Card(
                    title: "Second Card",
                    cardColor: .emerald,
                    tabIcon: "leaf.fill",
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
                },
                Card(
                    title: "Third Card",
                    cardColor: .amber,
                    tabIcon: "sparkles",
                    buttons: [
                        CardButton(
                            title: "Button 3",
                            cardColor: .amber,
                            action: {}
                        )
                    ]
                ) {
                    Text("Content for third card")
                        .foregroundColor(.white)
                        .padding()
                }
            ])
            .previewDisplayName("Multiple Cards")
        }
    }
}
