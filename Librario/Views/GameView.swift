//
//  ContentView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var navigationPath: NavigationPath
    @State private var currentSprite = "normal_sprite"
    @State private var bubbleText = ""
    
    let praisePhrases = ["Nice word!", "Fantastic!", "Awesome!", "Well done!", "Impressive!"]

        var body: some View {
            return ZStack {
                // Background color filling the entire safe area
                Image("red_curtain")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0)
                    .edgesIgnoringSafeArea(.all)

                GeometryReader { geometry in
                    VStack {
                        HStack {
                            ZStack {
                                Image(currentSprite)
                                    .resizable()
                                    .frame(width: 142, height: 150)

                                if currentSprite == "happy_sprite" && Int.random(in: 1...100) <= 20 { // 20% chance for the bubble to appear
                                    TextBubbleView(text: bubbleText)
                                        .offset(x: 75, y: -50) // Position the bubble above the sprite
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.5), value: currentSprite)
                                }
                            }

                            SubmitWordView(tileManager: gameManager.tileManager, gameManager: gameManager)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .padding()
                        .fixedSize(horizontal: false, vertical: true)

                        GameGridView(gameManager: gameManager, tileManager: gameManager.tileManager)

                        GameStatusView(gameManager: gameManager, navigationPath: $navigationPath)
                        
                    }
                    .frame(maxHeight: .infinity)
                }

                if gameManager.checkLevelProgression() {
                    LevelUpView(gameManager: gameManager, navigationPath: $navigationPath)
                        .zIndex(1)
                }
                
                // Show GameOverView directly based on gameState.gameOver
                if gameManager.gameOver {
                    GameOverView(gameManager: gameManager, navigationPath: $navigationPath)
                        .zIndex(1) // Ensure the GameOverView appears on top
                }
            }
            .onAppear {
                // Set up the sprite change handler
                gameManager.spriteChangeHandler = { sprite, duration in
                    changeSprite(to: sprite, for: duration)
                }

                // Listen for fire tile state changes from the TileManager
                gameManager.tileManager.fireTileChangeHandler = { hasFireTile in
                    if hasFireTile {
                        // Keep nervous sprite active as long as there is a fire tile
                        changeSprite(to: "nervous_sprite")
                    } else {
                        // Revert to normal sprite if no fire tiles are present
                        changeSprite(to: "normal_sprite")
                    }
                }

                // Initial fire tile check when view appears
                gameManager.tileManager.checkFireTiles()
            }
        }

    // Function to change the sprite in the UI
    private func changeSprite(to sprite: String) {
        currentSprite = sprite
    }
    
    private func changeSprite(to sprite: String, for duration: TimeInterval = 1.0) {
        // Check if the sprite is "happy_sprite" to show a text bubble
        if sprite == "happy_sprite" {
            bubbleText = praisePhrases.randomElement() ?? "Great!" // Set random praise phrase
        } else {
            bubbleText = "" // Clear the bubble text for other sprites
        }

        currentSprite = sprite
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // After duration, revert to normal sprite if not already changed
            if sprite != "normal_sprite" {
                currentSprite = "normal_sprite"
                bubbleText = "" // Clear the bubble text when the happy_sprite is gone
            }
        }
    }

    
    // Determines the top padding based on the device type
    private func topPaddingForDevice() -> CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return 60 // Less padding for iPhone
        case .pad:
            return 0 // More padding for iPad
        default:
            return 0 // Default padding for other devices or future devices
        }
    }
}

//#Preview {
//    let mockDictionaryManager = DictionaryManager()
//    let mockGameManager = GameManager(dictionaryManager: mockDictionaryManager)
//    
//    // Set up some sample tiles based on the provided Tile structure
//    let sampleTiles = [
//        Tile(letter: "A", type: .regular, points: 1, position: Position(row: 0, column: 0), isPlaceholder: false),
//        Tile(letter: "B", type: .green, points: 2, position: Position(row: 0, column: 1), isPlaceholder: false),
//        Tile(letter: "C", type: .gold, points: 3, position: Position(row: 0, column: 2), isPlaceholder: false)
//    ]
//    mockGameManager.tileManager.selectedTiles = sampleTiles // Add some sample selected tiles
//    
//    return GameView(navigationPath: .constant(NavigationPath()))
//        .environmentObject(mockGameManager) // Inject GameManager into the environment
//}



