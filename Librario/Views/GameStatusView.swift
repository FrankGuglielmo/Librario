//
//  GameStatusView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import SwiftUI

struct GameStatusView: View {
    @ObservedObject var gameManager: GameManager
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

    var body: some View {
        if horizontalSizeClass == .compact {
            // Layout for smaller devices (compact size class)
            VStack(spacing: 0) {
                // Progress bar above the buttons
                progressBarView()

                HStack(spacing: 0) {
                    // Menu Button
                    menuButton()

                    // Scramble Button
                    submitButton()

                    // Level display
                    levelView()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: 140, alignment: .top)
        } else {
            // Layout for larger devices (regular size class)
            HStack(spacing: 0) {
                // Menu Button
                menuButton()

                // Progress Bar
                progressBarView()
                    .frame(maxWidth: .infinity)

                // Level display
                levelView()
            }
            .frame(maxWidth: .infinity, maxHeight: 70, alignment: .top)
        }
    }

    // Progress bar view
    private func progressBarView() -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background (faded) progress bar
                Image("faded_progress_bar")
                    .resizable()
                    .frame(height: 70)
                    .frame(width: geometry.size.width)

                // Foreground (progress) bar, showing only part of the image based on progress
                Image("progress_bar")
                    .resizable()
                    .frame(height: 70)
                    .frame(width: geometry.size.width)
                    .clipShape(
                        Rectangle()
                            .size(width: progress * geometry.size.width, height: 70)
                    )

                // Score text in the center of the progress bar
                Text("\(gameManager.gameState.score)")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.yellow)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(height: 70)
    }

    // Menu button
    private func menuButton() -> some View {
        Button(action: {
            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
            navigationPath.removeLast() // Navigate back to HomeView
            print("Back to home")
        }) {
            VStack {
                Image(systemName: "arrow.left")
                    .font(.title)
                    .foregroundColor(.green)
                Text("Menu")
                    .foregroundStyle(.green)
            }
        }
        .frame(width: 70, height: 70) // Fixed size button
        .background(Color.brown)
        .contentShape(Rectangle()) // Ensure entire button area is tappable
    }

    // Scramble button
    private func submitButton() -> some View {
        Button(action: {
            gameManager.submitWord()
            print("Good word!")
        }) {
            ZStack {
                Rectangle()
                    .strokeBorder(.green, lineWidth: 5)
                    .background(Rectangle().fill(.brown))
                    .foregroundStyle(.brown)

                Text("Submit")
                    .font(.title)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity) // Make this button stretch to fill available space
    }

    // Level display
    private func levelView() -> some View {
        VStack(alignment: .center) {
            Text("LVL")
                .foregroundColor(.green)
            Text("\(gameManager.gameState.level)")
                .foregroundColor(.green)
        }
        .frame(width: 70, height: 70) // Fixed size for the level indicator
        .background(Color.brown)
    }
}

struct GameStatusView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy GameManager for preview purposes
        let gameManager = GameManager(dictionaryManager: DictionaryManager())
        gameManager.gameState.score = 150
        gameManager.gameState.level = 2
        gameManager.levelSystem = [1: 100, 2: 200, 3: 400]

        return Group {
            // Compact size class preview (e.g., iPhone)
            GameStatusView(gameManager: gameManager, navigationPath: .constant(NavigationPath()))
                .previewDisplayName("Compact Width")
                .previewInterfaceOrientation(.portrait)
                .environment(\.horizontalSizeClass, .compact)
                .previewDevice("iPhone 14 Pro")

            // Regular size class preview (e.g., iPad)
            GameStatusView(gameManager: gameManager, navigationPath: .constant(NavigationPath()))
                .previewDisplayName("Regular Width")
                .previewInterfaceOrientation(.landscapeLeft)
                .environment(\.horizontalSizeClass, .regular)
                .previewDevice("iPad Pro (12.9-inch) (5th generation)")
        }
    }
}

