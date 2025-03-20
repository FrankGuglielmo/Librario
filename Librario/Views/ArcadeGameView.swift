//
//  ArcadeGameView.swift
//  Librario
//
//  Created on 3/19/25.
//

import SwiftUI

struct ArcadeGameView: View {
    @Bindable var arcadeGameManager: GameManagerProtocol
    @Bindable var userData: UserData
    @Binding var navigationPath: NavigationPath
    @State private var currentSprite = "normal_sprite"
    @State private var bubbleText = ""
    @State private var showReminderBubble = false
    @State private var showLevelUp = false
    @State private var showPerformanceDebug = false
    @State private var showTimerDebug = false  // Debug view toggle
    @State private var showScrambleConfirmation = false
    @State private var timerColor: Color = .green
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // Access shared settings
    @Bindable private var settings = Settings.shared
    
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
                
                VStack(spacing: 0) {
                    // Arcade Mode Timer - only visible when debug mode is enabled
                    if settings.showDebugTimer {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(height: 8)
                                .opacity(0.3)
                                .foregroundColor(.gray)
                            
                            Rectangle()
                                .frame(width: getTimerWidth(geometry: geometry), height: 8)
                                .foregroundColor(timerColor)
                                .animation(.linear, value: arcadeGameManager.nextFireTileCountdown)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Timer text
                        Text("Next Fire Tile: \(Int(arcadeGameManager.nextFireTileCountdown))s")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.bottom, 4)
                    } else {
                        // Add empty spacer with zero height when timer is hidden
                        // This ensures consistent layout between both states
                        Spacer()
                            .frame(height: 0)
                    }
                    
                    HStack {
                        ZStack {
                            // Sprite button that triggers the scramble function
                            Button(action: {
                                // Show confirmation dialog instead of immediately scrambling
                                showScrambleConfirmation = true
                                showReminderBubble = false // Hide reminder bubble when showing confirmation
                            }) {
                                Image(currentSprite)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: spriteSize)
                            }
                            .confirmationDialog(
                                "Are you sure you want to scramble the board?",
                                isPresented: $showScrambleConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Scramble", role: .destructive) {
                                    arcadeGameManager.tileManager.scramble()
                                    AudioManager.shared.playSoundEffect(named: "tile_drop")
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("This will rearrange all tiles and add more fire tiles.")
                            }
                            
                            // Show the praise bubble, reminder bubble, swap mode or wildcard mode instructions
                            if arcadeGameManager.isInWildcardMode {
                                let message = arcadeGameManager.selectedWildcardTile == nil ?
                                "Select a tile to change" :
                                "Choose a new letter"
                                TextBubbleView(text: message)
                                    .offset(x: 75, y: -50) // Position the bubble above the sprite
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.5), value: arcadeGameManager.isInWildcardMode)
                            } else if arcadeGameManager.isInSwapMode {
                                let message = arcadeGameManager.selectedSwapTile == nil ?
                                "Select a tile to swap" :
                                "Select an adjacent tile"
                                TextBubbleView(text: message)
                                    .offset(x: 75, y: -50) // Position the bubble above the sprite
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.5), value: arcadeGameManager.isInSwapMode)
                            } else if currentSprite == "happy_sprite" && !bubbleText.isEmpty {
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
                        
                        SubmitWordView(tileManager: arcadeGameManager.tileManager, gameManager: arcadeGameManager)
                            .frame(width: SubmitBubbleSize)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                    
                    GameGridView(gameManager: arcadeGameManager, tileManager: arcadeGameManager.tileManager)
                    
                    GameToolBarView(gameManager: arcadeGameManager, navigationPath: $navigationPath)
                }
                .frame(maxHeight: .infinity)
            }
            
            // Debug view overlays
            VStack {
                HStack {
                    // Performance debug view (top left)
                    if showPerformanceDebug {
                        PerformanceDebugView(tileManager: arcadeGameManager.tileManager)
                    }
                    
                    Spacer()
                    
                    // Timer debug view (top right)
                    if showTimerDebug {
                        TimerDebugView(gameManager: arcadeGameManager, userData: userData)
                    }
                }
                Spacer()
            }
            .zIndex(2)
            
            // Wildcard selection popup
            if arcadeGameManager.showWildcardSelection {
                WildcardPopupView(gameManager: arcadeGameManager)
                    .zIndex(3)
            }
            
            // Wildcard confirmation popup
            if arcadeGameManager.showWildcardConfirmation {
                WildcardConfirmationView(gameManager: arcadeGameManager)
                    .zIndex(3)
            }
            
            // Swap confirmation card
            if arcadeGameManager.showSwapConfirmation,
               let fromTile = arcadeGameManager.selectedSwapTile,
               let toTile = arcadeGameManager.targetSwapTile {
                CardView(cards: [
                    Card(
                        title: "Confirm Swap",
                        subtitle: "Swap these two tiles?",
                        cardColor: .sapphire,
                        tabIcon: "arrow.2.squarepath",
                        isCloseDisabled: true,
                        buttons: [
                            CardButton(
                                title: "Confirm",
                                cardColor: .sapphire,
                                action: {
                                    arcadeGameManager.confirmSwap(from: fromTile.position, to: toTile.position)
                                }
                            ),
                            CardButton(
                                title: "Cancel",
                                cardColor: .sapphire,
                                action: {
                                    arcadeGameManager.exitSwapMode()
                                }
                            )
                        ]
                    ) {
                        VStack(spacing: 20) {
                            HStack(spacing: 40) {
                                VStack {
                                    Text("From")
                                        .foregroundColor(.white)
                                    Image(fromTile.imageName)
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                }
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                
                                VStack {
                                    Text("To")
                                        .foregroundColor(.white)
                                    Image(toTile.imageName)
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                }
                            }
                            
                            Text("This will use 1 Swap powerup")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    }
                ])
                .zIndex(3)
            }
            
            // Show LevelUpView based on showLevelUp state
            if showLevelUp {
                LevelUpView(gameManager: arcadeGameManager, userData: userData, navigationPath: $navigationPath, onDismiss: {
                    showLevelUp = false
                })
                .zIndex(1)
                .onAppear {
                    arcadeGameManager.pauseGameTimer()
                }
            }
            
            // Show Extra Life popup if available
            if arcadeGameManager.showExtraLifePopup {
                ExtraLifePopupView(gameManager: arcadeGameManager)
                    .zIndex(2)
                    .onAppear {
                        arcadeGameManager.pauseGameTimer()
                    }
            }
            
            // Show GameOverView directly based on gameState.gameOver
            if arcadeGameManager.gameOver {
                GameOverView(gameManager: arcadeGameManager, userData: userData, navigationPath: $navigationPath)
                    .zIndex(1)
                    .onAppear {
                        arcadeGameManager.stopGameTimer()
                        userData.userStatistics.updateHighestLevel(level: arcadeGameManager.gameState.level, score: arcadeGameManager.gameState.score)
                    }
            }
        }
        .onAppear {
            // Notify that GameView has appeared
            NotificationCenter.default.post(name: .gameViewDidAppear, object: nil)
            
            // Set gameplay state to active if not in game over state
            if !arcadeGameManager.gameOver {
                arcadeGameManager.gameplayState = .active
            }
            
            // Set up the sprite change handler
            arcadeGameManager.spriteChangeHandler = { sprite, duration in
                changeSprite(to: sprite, for: duration)
            }
            
            // Listen for fire tile state changes from the TileManager
            arcadeGameManager.tileManager.fireTileChangeHandler = { hasFireTile in
                if hasFireTile {
                    // Keep nervous sprite active as long as there is a fire tile
                    changeSprite(to: "nervous_sprite")
                } else {
                    // Revert to normal sprite if no fire tiles are present
                    changeSprite(to: "normal_sprite")
                }
            }
            
            // Initial fire tile check when view appears
            arcadeGameManager.tileManager.checkFireTiles()
            
            // Start the reminder timer
            startReminderTimer()
            
            // Start arcade timer
            arcadeGameManager.startFireTileTimer()
        }
        .onDisappear {
            // Update userData reference in the notification for GameManager to use
            NotificationCenter.default.post(
                name: .gameViewDidDisappear,
                object: nil,
                userInfo: ["userData": userData]
            )
        }
        .onChange(of: arcadeGameManager.gameState.score) {
            if arcadeGameManager.checkLevelProgression() {
                showLevelUp = true // Show LevelUpView when level progression is reached
            }
        }
        .onChange(of: arcadeGameManager.nextFireTileCountdown) { _, newValue in
            // Update timer color based on urgency
            if newValue < 3 {
                timerColor = .red
            } else if newValue < 5 {
                timerColor = .orange
            } else {
                timerColor = .green
            }
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
    
    // Start a timer to show a reminder bubble periodically
    private func startReminderTimer() {
        Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { _ in
            if currentSprite == "normal_sprite" && arcadeGameManager.tileManager.selectedTiles.isEmpty && bubbleText == "" {
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
    
    private func getTimerWidth(geometry: GeometryProxy) -> CGFloat {
        let percentage = arcadeGameManager.nextFireTileCountdown / arcadeGameManager.currentFireTileInterval
        return geometry.size.width * CGFloat(max(0, min(1, percentage)))
    }
}

#Preview {
    let userData = UserData()
    let dictionaryManager = DictionaryManager()
    let arcadeGameManager = ArcadeGameManager(dictionaryManager: dictionaryManager, userData: userData)
    
    return ArcadeGameView(
        arcadeGameManager: arcadeGameManager,
        userData: userData,
        navigationPath: .constant(NavigationPath())
    )
}
