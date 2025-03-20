//
//  ArcadeGameManager.swift
//  Librario
//
//  Created on 3/19/25.
//

import Foundation
import SwiftUI
import Observation

@Observable class ArcadeGameManager: GameManager {
    // Arcade-specific properties
    private var fireTileTimer: Timer?
    private var fireTileInterval: TimeInterval = 10.0  // Base interval (seconds)
    private var lastFireTileDropTime: Date?
    private var isPaused: Bool = false
    
    // Dynamic timer adjustment properties
    private var baseInterval: TimeInterval = 10.0
    private var minInterval: TimeInterval = 3.0
    private var maxInterval: TimeInterval = 15.0
    
    // Timer display properties
    var nextFireTileCountdown: TimeInterval = 10.0
    var showCountdown: Bool = true
    
    // Expose fire tile interval for the view
    var currentFireTileInterval: TimeInterval {
        return fireTileInterval
    }
    
    // Completely different initialization approach to avoid any 'self' issues
    override init(dictionaryManager: DictionaryManager, userData: UserData? = nil) {
        // Create all objects we need before super.init
        
        // Set initial values for the base GameManager to use
        let arcadeGameState = GameState.loadGameState(gameMode: .arcade) ?? {
            let state = GameState()
            state.gameMode = .arcade
            return state
        }()
        
        let arcadeTileManager = TileManager.loadTileManager(dictionaryManager: dictionaryManager, for: .arcade) ?? {
            let performanceEvaluator = PerformanceEvaluator()
            let letterGenerator = LetterGenerator(performanceEvaluator: performanceEvaluator)
            let tileTypeGenerator = TileTypeGenerator(performanceEvaluator: performanceEvaluator)
            let tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator, performanceEvaluator: performanceEvaluator)
            let tileConverter = TileConverter()
            let wordChecker = WordChecker(wordStore: dictionaryManager.wordDictionary)
            return TileManager(tileGenerator: tileGenerator, tileConverter: tileConverter, wordChecker: wordChecker, performanceEvaluator: performanceEvaluator)
        }()
        
        // Create a custom init for GameManager that doesn't require internal tileManager creation
        // Instead, we'll provide our arcade tileManager directly
        super.init(
            dictionaryManager: dictionaryManager,
            tileManager: arcadeTileManager,  // Using existing arcade tile manager
            gameState: arcadeGameState,      // Using arcade game state
            userData: userData
        )
        
        // Now it's safe to use self, but we don't need to modify tileManager/gameState anymore
        // because they've been correctly set during parent initialization
        
        // Set up notification observers for arcade mode
        setupArcadeNotificationObservers()
        monitorGameplayState()
        
        // Ensure our game over handler is set
        tileManager.gameOverHandler = { [weak self] in
            self?.handleGameOver()
        }
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    // MARK: - Timer Management
    
    // Start the fire tile timer
    func startFireTileTimer() {
        stopFireTileTimer() // Clear any existing timer
        
        // Set initial interval based on level only (not performance yet)
        let levelFactor = max(0.5, 1.0 - (Double(gameState.level) * 0.02))
        fireTileInterval = min(maxInterval, max(minInterval, baseInterval * levelFactor))
        
        lastFireTileDropTime = Date()
        
        fireTileTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            
            // Update countdown display
            if let lastDropTime = self.lastFireTileDropTime {
                let elapsedTime = Date().timeIntervalSince(lastDropTime)
                self.nextFireTileCountdown = max(0, self.fireTileInterval - elapsedTime)
                
                // Drop a fire tile when the interval is reached
                if elapsedTime >= self.fireTileInterval {
                    self.dropFireTile()
                    self.lastFireTileDropTime = Date()
                    // Note: updateFireTileInterval() is called inside dropFireTile()
                }
            }
        }
    }
    
    // Stop the fire tile timer
    func stopFireTileTimer() {
        fireTileTimer?.invalidate()
        fireTileTimer = nil
    }
    
    // Pause the fire tile timer
    func pauseFireTileTimer() {
        isPaused = true
        // Store the remaining time until next fire tile
        if let lastDropTime = lastFireTileDropTime {
            nextFireTileCountdown = fireTileInterval - Date().timeIntervalSince(lastDropTime)
        }
    }
    
    // Resume the fire tile timer
    func resumeFireTileTimer() {
        isPaused = false
        // Reset the last drop time based on the remaining countdown
        lastFireTileDropTime = Date().addingTimeInterval(-fireTileInterval + nextFireTileCountdown)
    }
    
    // Helper methods to check hot/cold streak without directly accessing performanceEvaluator
    private func isHotStreak() -> Bool {
        // Use word checker's word validation to check if a test word is valid
        // This is just a trick to get access to the internal state
        let testWord = "TEST"
        let testPoints = 500
        let result = tileManager.processWordSubmissionForStreak(word: testWord, points: testPoints)
        return result.isHot
    }
    
    private func isColdStreak() -> Bool {
        let testWord = "TEST"
        let testPoints = 500
        let result = tileManager.processWordSubmissionForStreak(word: testWord, points: testPoints)
        return result.isCold
    }
    
    // Update the fire tile interval based on player performance and level
    private func updateFireTileInterval() {
        // Base interval decreases as level increases (faster drops at higher levels)
        let levelFactor = max(0.5, 1.0 - (Double(gameState.level) * 0.02))
        
        // Adjust based on current performance state (not changing during interval)
        let performanceFactor: Double
        if isHotStreak() {
            performanceFactor = 0.8  // 20% faster during hot streaks
        } else if isColdStreak() {
            performanceFactor = 1.2  // 20% slower during cold streaks
        } else {
            performanceFactor = 1.0  // Normal speed
        }
        
        // Calculate new interval and clamp to min/max values
        fireTileInterval = min(maxInterval, max(minInterval, baseInterval * levelFactor * performanceFactor))
        
        // Log the new interval for debugging
        print("New fire tile interval: \(fireTileInterval)s (Level factor: \(levelFactor), Performance factor: \(performanceFactor))")
    }
    
    // Drop a fire tile at a random column in the top row
    private func dropFireTile() {
        // Find an available column in the top row
        let columns = tileManager.grid[0].count
        let randomColumn = Int.random(in: 0..<columns)
        
        // Create a fire tile
        let position = Position(row: 0, column: randomColumn)
        var fireTile = tileManager.getTile(at: position) ?? Tile(letter: "A", type: .regular, points: 100, position: position, isPlaceholder: false)
        fireTile.type = .fire
        
        // Update the grid
        tileManager.updateTile(at: position, with: fireTile)
        
        // Play sound effect
        AudioManager.shared.playSoundEffect(named: "tile_falling")
        
        // Check if this causes game over
        tileManager.checkFireTiles()
        
        // Calculate the next interval AFTER dropping the tile
        updateFireTileInterval()
    }
    
    // MARK: - Game Lifecycle
    
    override func startNewGame(userStatistics: UserStatistics) {
        super.startNewGame(userStatistics: userStatistics)
        gameState.gameMode = .arcade
        
        if gameplayState == .active && isInGameView {
            startFireTileTimer()
        }
    }
    
    // MARK: - Notification Handlers
    
    private func setupArcadeNotificationObservers() {
        // Register for app lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleArcadeAppDidBecomeActive),
            name: .appDidBecomeActive,
            object: nil
        )
        
        // Register for view transition notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleArcadeGameViewDidAppear),
            name: .gameViewDidAppear,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleArcadeGameViewDidDisappear),
            name: .gameViewDidDisappear,
            object: nil
        )
    }
    
    @objc private func handleArcadeAppDidBecomeActive() {
        // First let the parent handle its part
        // Note: We don't call super.handleAppDidBecomeActive() directly because it's private
        
        // Then handle our Arcade-specific logic
        if isInGameView && gameplayState == .active {
            resumeFireTileTimer()
        }
    }
    
    @objc private func handleArcadeGameViewDidAppear() {
        // Note: We don't call super.handleGameViewDidAppear() directly because it's private
        
        // Then handle our Arcade-specific logic
        if gameplayState == .active {
            startFireTileTimer()
        }
    }
    
    @objc private func handleArcadeGameViewDidDisappear(_ notification: Notification) {
        // Note: We don't call super.handleGameViewDidDisappear() directly because it's private
        
        // Then handle our Arcade-specific logic
        pauseFireTileTimer()
    }
    
    // MARK: - State Management Overrides
    
    override func saveGame() {
        // Ensure gameMode is set to arcade
        gameState.gameMode = .arcade
        super.saveGame()
    }
    
    // MARK: - Observe gameplayState changes
    
    // We'll monitor the gameplayState changes via a notification instead of direct override
    // This avoids issues with Observable properties
    func monitorGameplayState() {
        // Set up an observer to detect gameplayState changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleArcadeGameplayStateChanged),
            name: .gameplayStateChanged,
            object: nil
        )
    }
    
    @objc private func handleArcadeGameplayStateChanged(_ notification: Notification) {
        // Get the new and old state from the notification
        guard let userInfo = notification.userInfo,
              let newState = userInfo["newState"] as? GameplayState,
              let oldState = userInfo["oldState"] as? GameplayState else {
            return
        }
        
        // Only react if this notification is for our instance
        // This ensures we don't respond to classic mode state changes
        if notification.object as? ArcadeGameManager === self {
            handleGameplayStateTransition(from: oldState, to: newState)
        }
    }
    
    private func handleGameplayStateTransition(from oldState: GameplayState, to newState: GameplayState) {
        switch newState {
        case .active:
            if oldState != .active && isInGameView {
                resumeFireTileTimer()
            }
        case .paused, .levelTransition, .gameOver:
            if oldState == .active {
                pauseFireTileTimer()
            }
        }
    }
}
