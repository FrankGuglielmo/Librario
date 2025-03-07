//
//  TipView.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/10/24.
//

import SwiftUI

struct TipView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        let tipCard = Card(
            title: "Game Tips",
            subtitle: "Helpful strategies to improve your gameplay",
            cardColor: .sapphire,
            buttons: [
                CardButton(
                    title: "Back",
                    cardColor: .sapphire,
                    action: { 
                        AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                        navigationPath.removeLast() 
                    }
                )
            ]
        ) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(tipsData, id: \.id) { tip in
                    TipRow(tip: tip, popupWidth: horizontalSizeClass == .compact ? UIScreen.main.bounds.width * 0.9 : UIScreen.main.bounds.width * 0.6)
                }
            }
            .padding(.horizontal)
        }
        
        ZStack {
            // Background image filling the entire safe area
            Image("Background_Image_2")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0)
                .edgesIgnoringSafeArea(.all)
            
            CardView(cards: [tipCard])
        }
    }
}

// Data model for tips
struct Tip: Identifiable {
    let id = UUID()
    let imageName: String
    let imageColor: Color? // Optional for custom images
    let title: String
    let description: String
    let isSystemImage: Bool // New property to indicate image type
}

// Sample data for tips
let tipsData: [Tip] = [
    Tip(
        imageName: "TileSelectionTip",
        imageColor: nil,
        title: "Link Letters",
        description: "Click on the letters to link them into words. The longer the word, the higher the score.",
        isSystemImage: false
    ),
    Tip(
        imageName: "checkmark.square", // Replace with your custom image name
        imageColor: .green, // No tint color for custom images
        title: "Submit Words",
        description: "Click on 'Submit' to confirm your word. You earn points based on the word length and tile values.",
        isSystemImage: true
    ),
    Tip(
        imageName: "FireTileTip",
        imageColor: nil,
        title: "Beware of Burning Tiles",
        description: "Burning tiles will appear occasionally. If they reach the bottom, it's game over!",
        isSystemImage: false
    ),
    Tip(
        imageName: "arrow.3.trianglepath",
        imageColor: .yellow,
        title: "Scramble Letters",
        description: "Scramble letters if you can't make a word, but beware, this comes at a cost!",
        isSystemImage: true
    ),
    Tip(
        imageName: "SpecialTileTip",
        imageColor: nil,
        title: "Special Reward Tiles",
        description: "Green, Gold, and Diamond tiles appear when making good words. Use them in words for bonus points!",
        isSystemImage: false
    )
]


// Reusable tip row view
struct TipRow: View {
    let tip: Tip
    let popupWidth: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: popupWidth * 0.025) {
            Group {
                // Use appropriate Image initializer
                if tip.isSystemImage {
                    Image(systemName: tip.imageName)
                        .resizable()
                        .foregroundColor(tip.imageColor)
                } else {
                    Image(tip.imageName)
                        .resizable()
                        // Optional: Apply tint color if needed
                        .foregroundColor(tip.imageColor)
                }
            }
            .frame(width: popupWidth * 0.1, height: popupWidth * 0.1)
            .padding(.top, popupWidth * 0.005)

            VStack(alignment: .leading, spacing: popupWidth * 0.005) {
                Text(tip.title)
                    .font(.system(size: popupWidth * 0.045, weight: .semibold))
                    .foregroundColor(.white)
                Text(tip.description)
                    .font(.system(size: popupWidth * 0.035))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, popupWidth * 0.015)
    }
}

struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Compact size class preview (e.g., iPhone)
            TipView(navigationPath: .constant(NavigationPath()))
                .previewDisplayName("Compact Width")
                .environment(\.horizontalSizeClass, .compact)
                .previewDevice("iPhone 14 Pro")

            // Regular size class preview (e.g., iPad)
            TipView(navigationPath: .constant(NavigationPath()))
                .previewDisplayName("Regular Width")
                .environment(\.horizontalSizeClass, .regular)
                .previewDevice("iPad Pro (12.9-inch) (5th generation)")
        }
    }
}
