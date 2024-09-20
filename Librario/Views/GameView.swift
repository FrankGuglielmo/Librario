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
    @State private var showReminderBubble = false
    @State private var showLevelUp = false // State to control LevelUpView visibility
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

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
                let isCompact = horizontalSizeClass == .compact
                
                let spriteSize: CGFloat = isCompact ? geometry.size.width * 0.32 : geometry.size.width * 0.15
                let SubmitBubbleSize: CGFloat = isCompact ? geometry.size.width * 0.5 : geometry.size.width * 0.5
                
                VStack {
                    HStack {
                        ZStack {
                            // Sprite button that triggers the scramble function
                            Button(action: {
                                gameManager.tileManager.scramble()
                                showReminderBubble = false // Hide reminder bubble after scrambling
                            }) {
                                Image(currentSprite)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: spriteSize)
                            }

                            // Show the praise bubble or reminder bubble
                            if currentSprite == "happy_sprite" && !bubbleText.isEmpty {
                                TextBubbleView(text: bubbleText)
                                    .offset(x: 75, y: -50) // Position the bubble above the sprite
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.5), value: currentSprite)
                            } else if showReminderBubble {
                                TextBubbleView(text: "Need a scramble?")
                                    .offset(x: 75, y: -50) // Position the bubble above the sprite
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.5), value: showReminderBubble)
                            }
                        }
                        
                        if !isCompact {
                            Spacer()
                        }
                        
                        SubmitWordView(tileManager: gameManager.tileManager, gameManager: gameManager)
                            .frame(width: SubmitBubbleSize)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)

                    GameGridView(gameManager: gameManager, tileManager: gameManager.tileManager)

                    GameStatusView(gameManager: gameManager, navigationPath: $navigationPath)
                        
                    
                }
                .frame(maxHeight: .infinity)
            }

            // Show LevelUpView based on showLevelUp state
            if showLevelUp {
                LevelUpView(gameManager: gameManager, navigationPath: $navigationPath, onDismiss: {
                    showLevelUp = false
                })
                .zIndex(1)
                .onAppear {
                    gameManager.levelData.endGameplay()
                    gameManager.stopLevelTimer()
                }
            }
            
            // Show GameOverView directly based on gameState.gameOver
            if gameManager.gameOver {
                GameOverView(gameManager: gameManager, navigationPath: $navigationPath)
                    .zIndex(1)
                    .onAppear {
                        gameManager.levelData.endGameplay()
                        gameManager.stopLevelTimer()
                    }
            }
        }
        .onAppear {
            // Start gameplay timer
            gameManager.startLevelTimer()
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

            // Start the reminder timer
            startReminderTimer()
        }
        .onDisappear {
            // Stop the level timer when GameView disappears
            gameManager.levelData.endGameplay()
            gameManager.stopLevelTimer()
        }
        .onChange(of: gameManager.gameState.score, {
            if gameManager.checkLevelProgression() {
                showLevelUp = true // Show LevelUpView when level progression is reached
            }
        })
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

    // Start a timer to show a reminder bubble periodically
    private func startReminderTimer() {
        Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { _ in
            if currentSprite == "normal_sprite" && gameManager.tileManager.selectedTiles.isEmpty && bubbleText == "" {
                withAnimation {
                    currentSprite = "happy_sprite"
                    showReminderBubble = true
                }
                
                // Hide the bubble after a few seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        currentSprite = "normal_sprite"
                        showReminderBubble = false
                    }
                }
            }
        }
    }
}


struct GameView_Previews: PreviewProvider {
    @State static var navigationPath = NavigationPath()

    static var previews: some View {
        GameView(navigationPath: $navigationPath)
            .environmentObject(GameManager(dictionaryManager: DictionaryManager())) // Replace with your actual GameManager setup
            .environmentObject(UserData())    // Replace with your actual UserData setup
            .previewDevice("iPhone 14 Pro")
    }
}
