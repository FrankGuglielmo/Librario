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
    
    // Function to calculate progress
    private var progress: CGFloat {
        let gameState = gameManager.gameState
        guard let nextLevelThreshold = gameManager.levelSystem[gameState.level] else { return 0 }
        let currentLevelThreshold = gameState.level > 1 ? gameManager.levelSystem[gameState.level - 1]! : 0
        return CGFloat(gameState.score - currentLevelThreshold) / CGFloat(nextLevelThreshold - currentLevelThreshold)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .leading) {
                // Background (faded) progress bar
                Image("faded_progress_bar")
                    .resizable()
                    .frame(height: 70) // Keep height fixed, width will expand
                
                // Foreground (progress) bar, showing only part of the image based on progress
                Image("progress_bar")
                    .resizable()
                    .frame(height: 70) // Fixed height, width adjusts based on progress
                    .clipShape(
                        Rectangle()
                            .size(width: progress * UIScreen.main.bounds.width, height: 70) // Reveal only part of the image based on progress
                    )
                
                // Score text in the center of the progress bar
                Text("\(gameManager.gameState.score)")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.yellow)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Center the text
            }
            .frame(maxWidth: .infinity) // Expand to screen width, fixed height
            
            HStack(spacing: 0) {
                // Custom back button using NavigationPath
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

                // Scramble button
                Button(action: {
                    gameManager.tileManager.scramble()
                    print("Scrambling Tiles...")
                }) {
                    ZStack {
                        Rectangle()
                            .strokeBorder(.green, lineWidth: 5)
                            .background(Rectangle().fill(.brown))
                            .foregroundStyle(.brown)
                        
                        Text("Scramble")
                            .font(.title)
                            .foregroundStyle(.green)
                    }
                }
                .frame(maxWidth: .infinity) // Make this button stretch to fill available space

                // Level display
                VStack(alignment: .center) {
                    Text("LVL")
                        .foregroundColor(.green)
                    Text("\(gameManager.gameState.level)")
                        .foregroundColor(.green)
                }
                .frame(width: 70, height: 70) // Fixed size for the level indicator
                .background(Color.brown)
            }
            .frame(maxWidth: .infinity) // Expand HStack to screen width, fixed height
        }
        .frame(maxWidth: .infinity, maxHeight: 140, alignment: .top) // Ensure the entire view fills width and aligns properly
    }
}
