//
//  GameManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/10/24.
//

import Foundation
import SwiftUI
import Observation

@Observable class GameManager: Codable {
    // Game state enum to track the current state of gameplay
    enum GameplayState {
        case active
        case paused
        case levelTransition
        case gameOver
    }
    
    var gameOver: Bool = false {
        didSet {
            if gameOver {
                gameplayState = .gameOver
            }
        }
    }
    var gameState: GameState
    var levelData: LevelStatistics
    var sessionData: SessionStatistics
    var tileManager: TileManager
    
    // Timer-related properties
    private var gameTimer: Timer?
    private var gameStartTime: Date?
    private var accumulatedGameTime: TimeInterval = 0.0
    
    // Current elapsed time for the active game session
    var currentGameTime: TimeInterval {
        if let startTime = gameStartTime {
            return accumulatedGameTime + Date().timeIntervalSince(startTime)
        } else {
            return accumulatedGameTime
        }
    }
    
    // Track if the user is currently in the GameView
    var isInGameView: Bool = false
    
    // Track the current gameplay state
    var gameplayState: GameplayState = .active {
        didSet {
            if oldValue != gameplayState {
                handleGameplayStateChange(from: oldValue, to: gameplayState)
            }
        }
    }

    var levelSystem: [Int: Int] = [:]
    private let dictionaryManager: DictionaryManager
    
    // Closure to trigger sprite changes in the GameView
    var spriteChangeHandler: ((String, TimeInterval) -> Void)?

    enum CodingKeys: String, CodingKey {
        case gameState, levelData, sessionData, levelSystem, tileManager
    }

    /**
     * Initializes a new `GameManager` with the provided `DictionaryManager`.
     *
     * @param dictionaryManager The `DictionaryManager` instance used to manage dictionary data.
     */
    init(dictionaryManager: DictionaryManager) {
        self.dictionaryManager = dictionaryManager
        
        // Load GameState from disk if available, otherwise initialize a new GameState
        self.gameState = GameState.loadGameState() ?? GameState()
        
        // Initialize level and session data
        self.levelData = LevelStatistics.loadLevelData()
        self.sessionData = SessionStatistics.loadSessionData()
        
        // Load TileManager from disk if available, otherwise initialize a new TileManager
        self.tileManager = TileManager.loadTileManager(dictionaryManager: dictionaryManager) ?? {
            let performanceEvaluator = PerformanceEvaluator()
            let letterGenerator = LetterGenerator(performanceEvaluator: performanceEvaluator)
            let tileTypeGenerator = TileTypeGenerator(performanceEvaluator: performanceEvaluator)
            let tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator, performanceEvaluator: performanceEvaluator)
            let tileConverter = TileConverter()
            let wordChecker = WordChecker(wordStore: dictionaryManager.wordDictionary)
            return TileManager(tileGenerator: tileGenerator, tileConverter: tileConverter, wordChecker: wordChecker, performanceEvaluator: performanceEvaluator)
        }()

        setupLevelSystem()
        setupGameOverHandler()
        setupNotificationObservers()
    }

    /**
     * Decodes a `GameManager` instance from the given decoder.
     *
     * @param decoder The decoder to read data from.
     * @throws DecodingError If decoding fails.
     */
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gameState = try container.decode(GameState.self, forKey: .gameState)
        levelData = try container.decode(LevelStatistics.self, forKey: .levelData)
        sessionData = try container.decode(SessionStatistics.self, forKey: .sessionData)
        levelSystem = try container.decode([Int: Int].self, forKey: .levelSystem)
        tileManager = try container.decode(TileManager.self, forKey: .tileManager)

        self.dictionaryManager = DictionaryManager() // Reinitialize dictionary manager if needed

        setupGameOverHandler()
    }

    /**
     * Encodes the `GameManager` instance into the given encoder.
     *
     * @param encoder The encoder to write data to.
     * @throws EncodingError If encoding fails.
     */
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameState, forKey: .gameState)
        try container.encode(levelData, forKey: .levelData)
        try container.encode(sessionData, forKey: .sessionData)
        try container.encode(levelSystem, forKey: .levelSystem)
        try container.encode(tileManager, forKey: .tileManager)
    }

    /**
     * Sets up the level system by initializing the experience required for each level.
     */
    private func setupLevelSystem() {
        let experienceScale = 2250.0
        for level in 1...999 {
            let requiredExperience = Double(level) * experienceScale
            levelSystem[level] = level == 1 ? Int(requiredExperience) : levelSystem[level - 1]! + Int(requiredExperience)
        }
    }

    /**
     * Starts a new game session, resetting necessary game data and updating user statistics.
     *
     * @param userStatistics The `UserStatistics` instance to update with the new game data.
     */
    func startNewGame(userStatistics: UserStatistics) {
        // If there was a meaningful game that was being played before, (score > 0), reset everything
        if gameState.score != 0 {
            gameOver = false
            handleSessionCompletion(userStatistics: userStatistics)
            userStatistics.totalGamesPlayed += 1
            gameState.reset()
            levelData = LevelStatistics()
            sessionData = SessionStatistics()
            tileManager.scrambleLock = false
            tileManager.generateInitialGrid()
        }
        // Otherwise, keep the board and gameState as is
        
    }

    /**
     * Submits the currently selected word, updates scores, and processes word validation and tile submission.
     */
    func submitWord() {
        if self.gameOver || !tileManager.validateWord() {
            return
        }

        // Array of sound effects to choose from
        let soundEffects = ["bite_sound", "word_submit_swoosh"]

        // Randomly select a sound effect
        if let selectedSound = soundEffects.randomElement() {
            AudioManager.shared.playSoundEffect(named: selectedSound)
        }
        
        changeSprite(to: "happy_sprite", for: 1.0)

        let word = tileManager.getWord()
        let points = tileManager.getScore()
        gameState.score += points
        levelData.trackWord(word, score: points)
        tileManager.processWordSubmission(word: word, points: points, level: gameState.level)
    }


    /**
     * Checks if the player has progressed to the next level based on the current score.
     *
     * @return `true` if the player has advanced to the next level; otherwise, `false`.
     */
    func checkLevelProgression() -> Bool{
        if gameState.level < 999 && gameState.score >= levelSystem[gameState.level]! {
            gameState.level += 1
            print("Level progressed to: \(gameState.level)")
            return true
        }
        return false
    }

    /**
     * Updates the session statistics based on the current level statistics upon level completion.
     */
    func handleLevelCompletion() {
        // Update statistics with current game time before completing level
        updateStatisticsWithGameTime()
        
        // Update the session statistics with the level statistics
        sessionData.updateFromLevel(levelData)
        sessionData.saveSessionData()
    }
    
    /**
     * Updates the session statistics and user statistics upon game session completion.
     *
     * @param userStatistics The `UserStatistics` instance to update with session data.
     */
    func handleSessionCompletion(userStatistics: UserStatistics) {
        // Update statistics with current game time before completing session
        updateStatisticsWithGameTime()
        
        handleLevelCompletion() // Update the session with the current level statistics
        userStatistics.updateFromSession(sessionData)
        userStatistics.saveUserStatistics()
    }
    
    /**
     * Resets the level statistics to their initial state.
     */
    func resetLevelStatistics() {
        levelData = LevelStatistics()
    }

    /**
     * Completes the current level, updating session data accordingly.
     */
    func completeLevel() {
        // Update statistics with current game time before completing level
        updateStatisticsWithGameTime()
        
        sessionData.updateFromLevel(levelData)
        levelData = LevelStatistics()
    }

    /**
     * Saves the current game state, level data, session data, and tile manager to persistent storage.
     */
    func saveGame() {
        // Update statistics with current game time before saving
        updateStatisticsWithGameTime()
        
        gameState.saveGameState()
        levelData.saveLevelData(levelData)
        sessionData.saveSessionData()
        tileManager.saveTileManager()
    }

    /**
     * Updates the user's statistics with the latest session data.
     *
     * @param userStatistics The `UserStatistics` instance to update.
     */
    func updateUserStatistics(_ userStatistics: UserStatistics) {
        // Update statistics with current game time before updating user statistics
        updateStatisticsWithGameTime()
        
        sessionData.updateFromLevel(levelData)
        userStatistics.updateFromSession(sessionData)
        userStatistics.updateHighestLevel(level: gameState.level, score: gameState.score)
        userStatistics.saveUserStatistics()
    }

    /**
     * Handles the game over state by playing the game over sound and updating the game state.
     */
    func handleGameOver() {
        DispatchQueue.main.async {
            AudioManager.shared.playSoundEffect(named: "game_over_sound")
            self.gameOver = true
            // gameplayState will be updated via the didSet on gameOver
        }
    }
    
    /**
     * Handles changes in gameplay state.
     */
    private func handleGameplayStateChange(from oldState: GameplayState, to newState: GameplayState) {
        print("Gameplay state changed from \(oldState) to \(newState)")
        
        switch newState {
        case .active:
            if oldState != .active && isInGameView {
                resumeGameTimer()
            }
        case .paused, .levelTransition, .gameOver:
            if oldState == .active {
                pauseGameTimer()
            }
        }
    }
    
    /**
     * Sets up the game over handler by assigning a closure to handle game over events from the `TileManager`.
     */
    private func setupGameOverHandler() {
        tileManager.gameOverHandler = { [weak self] in
            self?.handleGameOver()
        }
    }
    
    /**
     * Checks if there are any fire tiles present on the game board.
     *
     * @return `true` if there is at least one fire tile; otherwise, `false`.
     */
    func hasFireTile() -> Bool {
        // Assuming tileManager.tiles is a 2D array of tiles representing the grid
        for row in tileManager.grid {
            for tile in row {
                if tile.type == .fire { // Assuming fire tiles have a `TileType` of .fire
                    return true
                }
            }
        }
        return false
    }
    
    /**
     * Handles the presence of fire tiles by changing the sprite based on fire tile detection.
     */
    func handleFireTile() {
        if hasFireTile() {
            changeSprite(to: "nervous_sprite") // Change to nervous sprite
        } else {
            changeSprite(to: "normal_sprite") // Revert to normal if no fire tiles
        }
    }
    
    /**
     * Changes the current sprite to the specified sprite for a given duration.
     *
     * @param sprite The name of the sprite to change to.
     * @param duration The duration for which the sprite should be displayed. Defaults to 1.0 seconds.
     */
    func changeSprite(to sprite: String, for duration: TimeInterval = 1.0) {
        // Call the spriteChangeHandler closure to update the sprite
        spriteChangeHandler?(sprite, duration)
    }
    
    /**
     * Sets up notification observers for app lifecycle and view transitions.
     */
    private func setupNotificationObservers() {
        // App lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: .appDidBecomeActive,
            object: nil
        )
        
        // View transition notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGameViewDidAppear),
            name: .gameViewDidAppear,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGameViewDidDisappear),
            name: .gameViewDidDisappear,
            object: nil
        )
    }
    
    /**
     * Handles the app becoming active again after being in the background.
     */
    @objc private func handleAppDidBecomeActive() {
        print("App became active")
        // Only restart timer if we're in GameView and gameplay is active
        if isInGameView && gameplayState == .active {
            resumeGameTimer()
        }
    }
    
    /**
     * Handles the GameView appearing.
     */
    @objc private func handleGameViewDidAppear() {
        print("GameView appeared")
        isInGameView = true
        // Only start timer if gameplay is active
        if gameplayState == .active {
            startGameTimer()
        }
    }
    
    /**
     * Handles the GameView disappearing.
     */
    @objc private func handleGameViewDidDisappear(_ notification: Notification) {
        print("GameView disappeared")
        isInGameView = false
        pauseGameTimer()
        
        // Get userData from notification if available
        if let userInfo = notification.userInfo,
           let userData = userInfo["userData"] as? UserData {
            // Update user statistics with the provided userData
            updateUserLifetimeStatistics(userData: userData)
            print("Updated user statistics with provided userData from notification")
        } else {
            // Fall back to loading userData from disk
            updateUserLifetimeStatistics()
            print("Updated user statistics with userData loaded from disk")
        }
    }

    /**
     * Updates the user's lifetime statistics with the current session data.
     * This is called when leaving the game view to ensure lifetime stats are current.
     */
    func updateUserLifetimeStatistics(userData: UserData? = nil) {
        print("--- Starting updateUserLifetimeStatistics ---")
        
        // First update statistics with any current game time
        updateStatisticsWithGameTime()
        
        // Then ensure that session data is up to date with the latest level data
        sessionData.updateFromLevel(levelData)
        sessionData.saveSessionData()
        
        print("Session time to be added to user stats: \(sessionData.timePlayed.formattedCompact)")
        
        // Work with either provided userData or load from disk
        let userDataToUpdate = userData ?? UserData.loadUserData()
        
        // Capture the time before update for logging
        let beforeUpdateTime = userDataToUpdate.userStatistics.timePlayed
        print("User lifetime time before update: \(beforeUpdateTime.formattedCompact)")
        
        // Update user statistics with session data
        userDataToUpdate.userStatistics.updateFromSession(sessionData)
        
        // Log time after update
        let afterUpdateTime = userDataToUpdate.userStatistics.timePlayed
        let timeDifference = afterUpdateTime - beforeUpdateTime
        print("User lifetime time after update: \(afterUpdateTime.formattedCompact)")
        print("Time difference added: \(timeDifference.formattedCompact)")
        
        // Save updated user statistics
        userDataToUpdate.userStatistics.saveUserStatistics()
        
        // Reset session time to prevent double counting in future updates
        let originalTime = sessionData.timePlayed
        sessionData.timePlayed = 0
        sessionData.saveSessionData()
        print("Reset session time (was: \(originalTime.formattedCompact))")
        
        print("--- Finished updateUserLifetimeStatistics ---")
    }

    /**
     * Updates statistics with the current game time.
     */
    func updateStatisticsWithGameTime() {
        // Calculate the current game time if timer is still running
        var timeToAdd: TimeInterval = 0.0
        
        if let startTime = gameStartTime {
            let currentRunningTime = Date().timeIntervalSince(startTime)
            timeToAdd = currentRunningTime
            // Reset the start time to now to avoid double counting
            gameStartTime = Date()
            print("Added current running time: \(currentRunningTime.formattedCompact)")
        }
        
        // Add accumulated time if any
        if accumulatedGameTime > 0 {
            timeToAdd += accumulatedGameTime
            // Reset accumulated time
            accumulatedGameTime = 0.0
        }
        
        if timeToAdd > 0 {
            // Update level statistics with new time
            levelData.updateTimePlayed(additionalTime: timeToAdd)
            
            print("Statistics updated with game time: \(timeToAdd.formattedCompact)")
            print("Current level time played: \(levelData.timePlayed.formattedCompact)")
            
            // Don't update session statistics here - that will happen when updateFromLevel is called
            
            // Save level data immediately
            levelData.saveLevelData(levelData)
        }
    }
    
    // Start the game timer
    func startGameTimer() {
        // Avoid multiple timers
        guard gameStartTime == nil else { return }
        gameStartTime = Date()
        print("Game timer started.")
    }
    
    // Pause the game timer
    func pauseGameTimer() {
        if let startTime = gameStartTime {
            // Add elapsed time to accumulated time
            accumulatedGameTime += Date().timeIntervalSince(startTime)
            gameStartTime = nil
            print("Game timer paused. Accumulated time: \(accumulatedGameTime.formattedCompact)")
        }
    }
    
    // Resume the game timer
    func resumeGameTimer() {
        if gameStartTime == nil {
            gameStartTime = Date()
            print("Game timer resumed. Accumulated time: \(accumulatedGameTime.formattedCompact)")
        }
    }
    
    // Stop the game timer and update statistics
    func stopGameTimer() {
        pauseGameTimer() // Pause first to accumulate time
        updateStatisticsWithGameTime()
        // Reset the timer
        accumulatedGameTime = 0.0
        print("Game timer stopped and reset.")
    }
    
    // For backward compatibility
    func startLevelTimer() {
        startGameTimer()
    }
    
    func pauseLevelTimer() {
        pauseGameTimer()
    }
    
    func resumeLevelTimer() {
        resumeGameTimer()
    }
    
    func stopLevelTimer() {
        stopGameTimer()
    }
}
