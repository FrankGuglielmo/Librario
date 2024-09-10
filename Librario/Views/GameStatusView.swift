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
    
    // Function to calculate progress (you can customize this logic)
    private var progress: CGFloat {
        let gameState = gameManager.gameState
        guard let nextLevelThreshold = gameManager.levelSystem[gameState.level] else { return 0 }
        let currentLevelThreshold = gameState.level > 1 ? gameManager.levelSystem[gameState.level - 1]! : 0
        return CGFloat(gameState.score - currentLevelThreshold) / CGFloat(nextLevelThreshold - currentLevelThreshold)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Custom back button using NavigationPath
            Button(action: {
                navigationPath.removeLast() // Navigate back to HomeView
                print("Back to home")
            }) {
                VStack {
                    Image(systemName: "arrow.left")
                        .font(.title)
                        .foregroundColor(.green)
                         // Ensure background is properly defined
                        .cornerRadius(0) // Make the button look nicer
                    
                    Text("Menu")
                        .foregroundStyle(.green)
                    
                }
                
            }
            
            .contentShape(Rectangle()) // Ensure entire button area is tappable
            .frame(width: 70, height: 70) // Define the button size explicitly
            .background(Color.brown)

            ZStack(alignment: .leading) {
                // Background (faded) progress bar
                Image("faded_progress_bar")
                    .resizable()
                    .frame(width: 280, height: 70) // Fixed size
                
                // Foreground (progress) bar, showing only part of the image based on progress
                Image("progress_bar")
                    .resizable()
                    .frame(width: 280, height: 70) // Fixed size
                    .clipShape(
                        Rectangle()
                            .size(width: progress * 280, height: 70) // Reveal only part of the image based on progress
                    )
                
                
                Text("\(gameManager.gameState.score)")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.yellow)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Center the text
                
            }
            .frame(width: 280, height: 70)
            
            
            

            VStack(alignment: .center, content: {
                Text("LVL")
                    .foregroundColor(.green)
                
                Text("\(gameManager.gameState.level)")
                    .foregroundColor(.green)
            })
            .frame(height: 70)
            .padding(.horizontal, 20)
            .background(Color.brown)
            
                
        }
        .frame(height: 70)
        .padding(.vertical)
    }
}

#Preview {
    GameStatusView(gameManager: GameManager(dictionaryManager: DictionaryManager()), navigationPath: .constant(NavigationPath()))
}

