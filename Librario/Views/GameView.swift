//
//  ContentView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import SwiftUI

struct GameView: View {
    @Bindable var gameManager: GameManager
    @Bindable var userData: UserData
    @Binding var navigationPath: NavigationPath
    @State private var currentSprite = "normal_sprite"
    @State private var bubbleText = ""
    @State private var showReminderBubble = false
    @State private var showLevelUp = false // State to control LevelUpView visibility
    @State private var showPerformanceDebug = false // State to control performance debug visibility
    @State private var showTimerDebug = false // State to control timer debug visibility
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
                
            // Add hidden gesture recognizers to toggle debug views
            // These are developer features that won't be obvious to regular users
            HStack {
                // Performance debug toggle (left corner)
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: 50, height: 50)
                    .position(x: 25, y: 25)
                    .onTapGesture(count: 3) { // Triple tap to toggle
                        showPerformanceDebug.toggle()
                    }
                
                Spacer()
                
                // Timer debug toggle (right corner)
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: 50, height: 50)
                    .position(x: 25, y: 25)
                    .onTapGesture(count: 3) { // Triple tap to toggle
                        showTimerDebug.toggle()
                    }
            }

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
            
            // Debug view overlays
            VStack {
                HStack {
                    // Performance debug view (top left)
                    if showPerformanceDebug {
                        PerformanceDebugView(tileManager: gameManager.tileManager)
                    }
                    
                    Spacer()
                    
                    // Timer debug view (top right)
                    if showTimerDebug {
                        TimerDebugView(gameManager: gameManager, userData: userData)
                    }
                }
                Spacer()
            }
            .zIndex(2)

            // Show LevelUpView based on showLevelUp state
            if showLevelUp {
                LevelUpView(gameManager: gameManager, userData: userData, navigationPath: $navigationPath, onDismiss: {
                    showLevelUp = false
                })
                .zIndex(1)
                .onAppear {
                    gameManager.pauseGameTimer()
                }
            }
            
            // Show GameOverView directly based on gameState.gameOver
            if gameManager.gameOver {
                GameOverView(gameManager: gameManager, userData: userData, navigationPath: $navigationPath)
                    .zIndex(1)
                    .onAppear {
                        gameManager.stopGameTimer()
                        userData.userStatistics.updateHighestLevel(level: gameManager.gameState.level, score: gameManager.gameState.score)
                    }
            }
        }
        .onAppear {
            // Notify that GameView has appeared
            NotificationCenter.default.post(name: .gameViewDidAppear, object: nil)
            
            // Set gameplay state to active if not in game over state
            if !gameManager.gameOver {
                gameManager.gameplayState = .active
            }
            
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
            // Update userData reference in the notification for GameManager to use
            NotificationCenter.default.post(
                name: .gameViewDidDisappear,
                object: nil,
                userInfo: ["userData": userData]
            )
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

#Preview {
    GameView(gameManager: GameManager(dictionaryManager: DictionaryManager()), userData: UserData(), navigationPath: .constant(NavigationPath()))
}
