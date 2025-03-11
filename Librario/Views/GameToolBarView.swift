//
//  GameToolBarView.swift
//  Librario
//
//  Created by Frank Guglielmo on 3/6/25.
//

import SwiftUI

struct GameToolBarView: View {
    @Bindable var gameManager: GameManager
    @Binding var navigationPath: NavigationPath

    // Environment variable to check the horizontal size class
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Function to calculate progress
    private var progress: CGFloat {
        let gameState = gameManager.gameState
        guard let nextLevelThreshold = gameManager.levelSystem[gameState.level] else { return 0 }
        let currentLevelThreshold = gameState.level > 1 ? gameManager.levelSystem[gameState.level - 1]! : 0
        return CGFloat(gameState.score - currentLevelThreshold) / CGFloat(nextLevelThreshold - currentLevelThreshold)
    }

    // Helper function to check if the device has biometric capabilities (Touch ID / Face ID)
    func isDeviceiPhoneSE() -> Bool {
        let screenBounds = UIScreen.main.bounds
        let screenScale = UIScreen.main.scale
        let screenSize = CGSize(width: screenBounds.size.width * screenScale, height: screenBounds.size.height * screenScale)
 
        let iPhoneSE1ScreenSize = CGSize(width: 640, height: 1136)
        let iPhoneSE2ScreenSize = CGSize(width: 750, height: 1334)

        // Compare the screen size to SE models
        if screenSize == iPhoneSE1ScreenSize || screenSize == iPhoneSE2ScreenSize {
            return true
        }
        
        return false
    }
    
    // Format numbers to ensure they're no more than 5 characters
    private func formatCurrency(_ value: Int) -> String {
        if value < 10000 {
            return "\(value)"
        } else if value < 1000000 {
            let thousands = Double(value) / 1000.0
            return String(format: "%.1fK", thousands).prefix(5).description
        } else if value < 1000000000 {
            let millions = Double(value) / 1000000.0
            return String(format: "%.1fM", millions).prefix(5).description
        } else {
            let billions = Double(value) / 1000000000.0
            return String(format: "%.1fB", billions).prefix(5).description
        }
    }

    var body: some View {
        // Use the compact layout for smaller devices or biometric devices like iPhones/iPads with Touch ID or Face ID
        if horizontalSizeClass == .compact && !isDeviceiPhoneSE() {
            // Layout for smaller devices (compact size class without Touch ID/Face ID)
            VStack(spacing: 8) {
                // Progress bar above the buttons
                progressBarView()
                    .cornerRadius(10)

                HStack(spacing: 0) {
                    // Back Button
                    backButton()
                    
                    
                    HStack(spacing: 0) {
                        // Swap Button
                        swapButton()
                        
                        // Wildcard Button
                        wildcardButton()
                        
                        // Extra Life Button
                        extraLifeButton()
                    }
                    
                    
                    // Currency display
                    currencyDisplay()
                    
                    Spacer()
                    
                    // Level display
                    levelView()
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cream)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: 125, alignment: .top)
        } else {
            // Layout for larger devices (regular size class or biometric devices)
            HStack(spacing: 0) {
                // Back Button
                backButton()

                // Progress Bar (takes up as much space as possible)
                progressBarView()
                    .frame(maxWidth: .infinity, maxHeight: 60)
                    .layoutPriority(2)
                
                
                HStack(spacing: 0) {
                    // Swap Button
                    swapButton()
                    
                    // Wildcard Button
                    wildcardButton()
                    
                    // Extra Life Button
                    extraLifeButton()

                    // Currency display
                    currencyDisplay()
                        .padding(.trailing, 30)
                }
    
                // Level display
                levelView()
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cream)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: .infinity, maxHeight: 60, alignment: .top)
        }
    }

    // Combined currency display (coins and diamonds)
    private func currencyDisplay() -> some View {
        VStack(spacing: 2) {
            // Coins
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.callout)
                    .foregroundStyle(Color.yellow)
                Text(formatCurrency(gameManager.getCoins()))
                    .font(.callout)
                    .foregroundStyle(Color.darkGrey)
                    .fontWeight(.bold)
            }
            
            // Diamonds
            HStack(spacing: 4) {
                Image("diamond_icon")
                    .resizable()
                    .frame(width: 20, height: 20)
                    
                Text(formatCurrency(gameManager.getDiamonds()))
                    .font(.callout)
                    .foregroundStyle(Color.darkGrey)
                    .fontWeight(.bold)
            }
        }
        .frame(width: 60, height: 60) // Reduced size
        .background(Color.cream)
    }

    // Progress bar view
    private func progressBarView() -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background (faded) progress bar
                Image("faded_progress_bar")
                    .resizable()
                    .frame(height: 60)
                    .frame(width: geometry.size.width)

                // Foreground (progress) bar, showing only part of the image based on progress
                Image("progress_bar")
                    .resizable()
                    .frame(height: 60)
                    .frame(width: geometry.size.width)
                    .clipShape(
                        Rectangle()
                            .size(width: progress * geometry.size.width, height: 60)
                    )

                // Score text in the center of the progress bar
                Text("\(gameManager.gameState.score)")
                    .font(.title)
                    .bold()
                    .foregroundColor(.yellow)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(height: 60)
    }

    // Back button
    private func backButton() -> some View {
        Button(action: {
            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
            navigationPath.removeLast() // Navigate back to HomeView
        }) {
            VStack {
                Image(systemName: "arrowshape.left")
                    .font(.title3)
                    .foregroundStyle(Color.cream)
                Text("Back")
                    .font(.footnote)
                    .foregroundStyle(Color.cream)
                    .fontWeight(.bold)
            }
        }
        .frame(width: 60, height: 60) // Reduced size button
        .background(Color.forestGreen)
        .contentShape(Rectangle()) // Ensure entire button area is tappable
    }
    
    // Swap button
    private func swapButton() -> some View {
        Button(action: {
            if gameManager.useSwapPowerup() {
                // Swap functionality would be implemented here
                print("Swap powerup used")
            } else {
                // Not enough powerups
                AudioManager.shared.playSoundEffect(named: "incorrect_selection")
            }
        }) {
            ZStack {
                VStack {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.title3)
                        .foregroundStyle(Color.darkGrey)
                    Text("Swap")
                        .font(.footnote)
                        .foregroundStyle(Color.darkGrey)
                        .fontWeight(.bold)
                }
                
                // Count indicator
                if gameManager.getPowerupCount(.swap) > 0 {
                    Text("\(gameManager.getPowerupCount(.swap))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 18, y: -18)
                }
            }
        }
        .frame(width: 60, height: 60) // Reduced size button
        .background(Color.cream)
        .contentShape(Rectangle()) // Ensure entire button area is tappable
    }
    
    // Extra Life button
    private func extraLifeButton() -> some View {
        Button(action: {
            if gameManager.useExtraLifePowerup() {
                // Extra life functionality would be implemented here
                print("Extra life powerup used")
            } else {
                // Not enough powerups
                AudioManager.shared.playSoundEffect(named: "incorrect_selection")
            }
        }) {
            ZStack {
                VStack {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundStyle(Color.darkGrey)
                    Text("Life")
                        .font(.footnote)
                        .foregroundStyle(Color.darkGrey)
                        .fontWeight(.bold)
                }
                
                // Count indicator
                if gameManager.getPowerupCount(.extraLife) > 0 {
                    Text("\(gameManager.getPowerupCount(.extraLife))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 18, y: -18)
                }
            }
        }
        .frame(width: 60, height: 60) // Reduced size button
        .background(Color.cream)
        .contentShape(Rectangle()) // Ensure entire button area is tappable
    }
    
    // Wildcard button
    private func wildcardButton() -> some View {
        Button(action: {
            if gameManager.useWildcardPowerup() {
                // Wildcard functionality would be implemented here
                print("Wildcard powerup used")
            } else {
                // Not enough powerups
                AudioManager.shared.playSoundEffect(named: "incorrect_selection")
            }
        }) {
            ZStack {
                VStack {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(Color.darkGrey)
                    Text("Wild")
                        .font(.footnote)
                        .foregroundStyle(Color.darkGrey)
                        .fontWeight(.bold)
                }
                
                // Count indicator
                if gameManager.getPowerupCount(.wildcard) > 0 {
                    Text("\(gameManager.getPowerupCount(.wildcard))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 18, y: -18)
                }
            }
        }
        .frame(width: 60, height: 60) // Reduced size button
        .background(Color.cream)
        .contentShape(Rectangle()) // Ensure entire button area is tappable
    }

    // Level display
    private func levelView() -> some View {
        VStack(alignment: .center) {
            Text("LVL")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(Color.cream)
            Text("\(gameManager.gameState.level)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.cream)
        }
        .frame(width: 60, height: 60) // Reduced size
        .background(Color.forestGreen)
    }
}

struct GameToolBarView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy GameManager for preview purposes
        let gameManager = GameManager(dictionaryManager: DictionaryManager())
        gameManager.gameState.score = 150
        gameManager.gameState.level = 2
        gameManager.levelSystem = [1: 100, 2: 200, 3: 400]

        return Group {
            // Compact size class preview (e.g., iPhone)
            GameToolBarView(gameManager: gameManager, navigationPath: .constant(NavigationPath()))
                .previewDisplayName("Compact Width")
                .previewInterfaceOrientation(.portrait)
                .environment(\.horizontalSizeClass, .compact)
                .previewDevice("iPhone 14 Pro")

            // Regular size class preview (e.g., iPad)
            GameToolBarView(gameManager: gameManager, navigationPath: .constant(NavigationPath()))
                .previewDisplayName("Regular Width")
                .previewInterfaceOrientation(.landscapeLeft)
                .environment(\.horizontalSizeClass, .regular)
                .previewDevice("iPad Pro (12.9-inch) (5th generation)")
        }
    }
}
