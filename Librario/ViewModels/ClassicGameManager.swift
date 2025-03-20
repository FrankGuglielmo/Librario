//
//  ClassicGameManager.swift
//  Librario
//
//  Created on 3/19/25.
//

import Foundation
import SwiftUI
import Observation

@Observable class ClassicGameManager: GameManagerProtocol {
    // Private properties for inventory management
    private var userData: UserData?
    private var userInventory: Inventory? // Reference to userData?.inventory for readability

    // Extra life properties
    private var extraLivesUsedInSession: Int = 0
    private var maxExtraLivesPerSession: Int = 3
    var showExtraLifePopup: Bool = false
    private var firePositionCausingGameOver: Position? = nil
    private var extraLifeTimer: Timer?
    private var extraLifeTimeRemaining: Double = 5.0
    private var extraLifeTotalTime: Double = 5.0

    // Swap mode properties
    var isInSwapMode: Bool = false
    var selectedSwapTile: Tile? = nil
    var adjacentTiles: [Position] = []
    var showSwapConfirmation: Bool = false
    var targetSwapTile: Tile? = nil
        
    // Wildcard mode properties
    var isInWildcardMode: Bool = false
    var selectedWildcardTile: Tile? = nil
    var showWildcardSelection: Bool = false
    var showWildcardConfirmation: Bool = false
    var targetWildcardLetter: String? = nil
        
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
    var gameplayState: GameManager.GameplayState = .active {
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
    
    // MARK: - Initializers
    
    init(dictionaryManager: DictionaryManager, userData: UserData? = nil) {
        self.userData = userData
        if let userData = userData {
            self.userInventory = userData.inventory
        }
        self.dictionaryManager = dictionaryManager
        
        // Load GameState from disk if available, otherwise initialize a new GameState
        self.gameState = GameState.loadGameState(gameMode: .classic) ?? GameState()
        self.gameState.gameMode = .classic // Ensure classic mode
        
        // Initialize level and session data
        self.levelData = LevelStatistics.loadLevelData()
        self.sessionData = SessionStatistics.loadSessionData()
        
        // Load TileManager from disk if available, otherwise initialize a new TileManager
        self.tileManager = TileManager.loadTileManager(dictionaryManager: dictionaryManager, for: .classic) ?? {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gameState, forKey: .gameState)
        try container.encode(levelData, forKey: .levelData)
        try container.encode(sessionData, forKey: .sessionData)
        try container.encode(levelSystem, forKey: .levelSystem)
        try container.encode(tileManager, forKey: .tileManager)
    }
    
    // MARK: - Inventory Methods
    
    func getCoins() -> Int {
        guard let userInventory = userInventory else { return 0 }
        return userInventory.coins
    }
    
    func getDiamonds() -> Int {
        guard let userInventory = userInventory else { return 0 }
        return userInventory.diamonds
    }
    
    // MARK: - Powerup Methods
    
    func useSwapPowerup() -> Bool {
        return usePowerup(.swap)
    }
    
    func useExtraLifePowerup() -> Bool {
        return usePowerup(.extraLife)
    }
    
    func useWildcardPowerup() -> Bool {
        return usePowerup(.wildcard)
    }
    
    func usePowerup(_ type: PowerupType) -> Bool {
        guard let userInventory = userInventory, let userData = userData else { return false }
        guard let count = userInventory.powerups[type], count > 0 else { return false }
        
        userInventory.powerups[type]! -= 1
        userData.saveUserData()
        return true
    }
    
    func getPowerupCount(_ type: PowerupType) -> Int {
        guard let userInventory = userInventory else { return 0 }
        return userInventory.powerups[type] ?? 0
    }
    
    // MARK: - Wildcard Mode Methods
    
    func enterWildcardMode() -> Bool {
        // Check if user has wildcard powerups
        if getPowerupCount(.wildcard) > 0 {
            isInWildcardMode = true
            tileManager.clearSelection() // Clear any selected tiles
            selectedWildcardTile = nil
            targetWildcardLetter = nil
            showWildcardSelection = false
            showWildcardConfirmation = false
            return true
        }
        return false
    }
    
    func exitWildcardMode() {
        isInWildcardMode = false
        selectedWildcardTile = nil
        targetWildcardLetter = nil
        showWildcardSelection = false
        showWildcardConfirmation = false
    }
    
    func selectTileForWildcard(at position: Position) -> Bool {
        guard isInWildcardMode else { return false }
        
        if selectedWildcardTile == nil {
            // First selection - store the tile and show letter selection
            if let tile = tileManager.getTile(at: position) {
                selectedWildcardTile = tile
                showWildcardSelection = true
                return true
            }
        } else if selectedWildcardTile!.position == position {
            // Tapped the same tile again - deselect it
            selectedWildcardTile = nil
            showWildcardSelection = false
            return true
        }
        
        return false
    }
    
    func selectWildcardLetter(letter: String) -> Bool {
        guard isInWildcardMode && selectedWildcardTile != nil else { return false }
        
        targetWildcardLetter = letter
        showWildcardSelection = false
        showWildcardConfirmation = true
        return true
    }
    
    func confirmWildcardChange() {
        guard let tile = selectedWildcardTile, let letter = targetWildcardLetter else { return }
        
        changeTileLetter(at: tile.position, to: letter)
        usePowerup(.wildcard) // Decrement the powerup count
        exitWildcardMode()
    }
    
    func changeTileLetter(at position: Position, to letter: String) {
        guard let tile = tileManager.getTile(at: position) else { return }
        
        // Create a new tile with the same properties but different letter
        var newTile = tile
        newTile.letter = letter
        
        // Update the grid
        tileManager.updateTile(at: position, with: newTile)
        
        // Play a sound effect for the change
        AudioManager.shared.playSoundEffect(named: "tile_click2")
    }
    
    // MARK: - Swap Mode Methods
    
    func enterSwapMode() -> Bool {
        // Check if user has swap powerups
        if getPowerupCount(.swap) > 0 {
            isInSwapMode = true
            tileManager.clearSelection() // Clear any selected tiles
            selectedSwapTile = nil
            targetSwapTile = nil
            adjacentTiles = []
            showSwapConfirmation = false
            return true
        }
        return false
    }
    
    func exitSwapMode() {
        isInSwapMode = false
        selectedSwapTile = nil
        targetSwapTile = nil
        adjacentTiles = []
        showSwapConfirmation = false
    }
    
    func selectTileForSwap(at position: Position) -> Bool {
        guard isInSwapMode else { return false }
        
        if selectedSwapTile == nil {
            // First selection - store the tile and calculate adjacent tiles
            if let tile = tileManager.getTile(at: position) {
                selectedSwapTile = tile
                adjacentTiles = getAdjacentTiles(to: position)
                return true
            }
        } else if selectedSwapTile!.position == position {
            // Tapped the same tile again - deselect it
            selectedSwapTile = nil
            adjacentTiles = []
            return true
        } else {
            // Second selection - check if it's adjacent
            if canSwapTiles(from: selectedSwapTile!.position, to: position) {
                // Store the target tile and show confirmation
                if let tile = tileManager.getTile(at: position) {
                    targetSwapTile = tile
                    showSwapConfirmation = true
                    return true
                }
            }
        }
        return false
    }
    
    func getAdjacentTiles(to position: Position) -> [Position] {
        let isEvenColumn = position.column % 2 == 0
        var adjacentPositions: [Position] = []
        
        // Same column
        adjacentPositions.append(Position(row: position.row - 1, column: position.column)) // Up
        adjacentPositions.append(Position(row: position.row + 1, column: position.column)) // Down
        
        // Adjacent columns
        if isEvenColumn {
            // Even column
            adjacentPositions.append(Position(row: position.row, column: position.column - 1)) // Left
            adjacentPositions.append(Position(row: position.row, column: position.column + 1)) // Right
            adjacentPositions.append(Position(row: position.row - 1, column: position.column - 1)) // Up-Left
            adjacentPositions.append(Position(row: position.row - 1, column: position.column + 1)) // Up-Right
        } else {
            // Odd column
            adjacentPositions.append(Position(row: position.row, column: position.column - 1)) // Left
            adjacentPositions.append(Position(row: position.row, column: position.column + 1)) // Right
            adjacentPositions.append(Position(row: position.row + 1, column: position.column - 1)) // Down-Left
            adjacentPositions.append(Position(row: position.row + 1, column: position.column + 1)) // Down-Right
        }
        
        // Filter out invalid positions
        return adjacentPositions.filter { 
            $0.row >= 0 && $0.row < tileManager.grid.count && 
            $0.column >= 0 && $0.column < tileManager.grid[0].count 
        }
    }
    
    func canSwapTiles(from: Position, to: Position) -> Bool {
        return adjacentTiles.contains(to)
    }
    
    func swapTiles(from: Position, to: Position) {
        guard let fromTile = tileManager.getTile(at: from),
              let toTile = tileManager.getTile(at: to) else { return }
        
        // Create copies with swapped positions
        var newFromTile = fromTile
        var newToTile = toTile
        
        newFromTile.position = to
        newToTile.position = from
        
        // Update the grid
        tileManager.updateTile(at: from, with: newToTile)
        tileManager.updateTile(at: to, with: newFromTile)
        
        // Play a sound effect for the swap
        AudioManager.shared.playSoundEffect(named: "tile_click2")
    }
    
    func confirmSwap(from: Position, to: Position) {
        swapTiles(from: from, to: to)
        usePowerup(.swap) // Decrement the powerup count
        exitSwapMode()
    }

    // MARK: - Game Management Methods
    
    private func setupLevelSystem() {
        let experienceScale = 2250.0
        for level in 1...999 {
            let requiredExperience = Double(level) * experienceScale
            levelSystem[level] = level == 1 ? Int(requiredExperience) : levelSystem[level - 1]! + Int(requiredExperience)
        }
    }

    func startNewGame(userStatistics: UserStatistics) {
        // If there was a meaningful game that was being played before, (score > 0), reset everything
        if gameState.score != 0 {
            gameOver = false
            handleSessionCompletion(userStatistics: userStatistics)
            userStatistics.totalGamesPlayed += 1
            gameState.reset()
            gameState.gameMode = .classic // Ensure classic mode
            levelData = LevelStatistics()
            sessionData = SessionStatistics()
            tileManager.scrambleLock = false
            tileManager.generateInitialGrid()
        }
        // Otherwise, keep the board and gameState as is
    }

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
        
        // Update user's inventory based on special tiles
        updateInventoryFromSubmittedWord(word: word)
        
        tileManager.processWordSubmission(word: word, points: points, level: gameState.level)
    }
    
    private func updateInventoryFromSubmittedWord(word: String) {
        guard let userInventory = userInventory, let userData = userData else { return }
        
        // Count diamond and gold tiles
        var diamondTileCount = 0
        var goldTileCount = 0
        
        for tile in tileManager.selectedTiles {
            if tile.type == .diamond {
                diamondTileCount += 1
            } else if tile.type == .gold {
                goldTileCount += 1
            }
        }
        
        // Add diamonds (1 per diamond tile)
        if diamondTileCount > 0 {
            let diamondsToAdd = diamondTileCount
            userInventory.diamonds += diamondsToAdd
            userData.saveUserData()
            print("Added \(diamondsToAdd) diamonds from diamond tiles")
        }
        
        // Add coins (word length × number of gold tiles)
        if goldTileCount > 0 {
            let coinsToAdd = word.count * goldTileCount
            userInventory.coins += coinsToAdd
            userData.saveUserData()
            print("Added \(coinsToAdd) coins from gold tiles (word length \(word.count) × \(goldTileCount) gold tiles)")
        }
    }

    func checkLevelProgression() -> Bool {
        if gameState.level < 999 && gameState.score >= levelSystem[gameState.level]! {
            gameState.level += 1
            print("Level progressed to: \(gameState.level)")
            return true
        }
        return false
    }

    func handleLevelCompletion() {
        // Update statistics with current game time before completing level
        updateStatisticsWithGameTime()
        
        // Update the session statistics with the level statistics
        sessionData.updateFromLevel(levelData)
        sessionData.saveSessionData()
    }
    
    func handleSessionCompletion(userStatistics: UserStatistics) {
        // Update statistics with current game time before completing session
        updateStatisticsWithGameTime()
        
        handleLevelCompletion() // Update the session with the current level statistics
        userStatistics.updateFromSession(sessionData)
        userStatistics.saveUserStatistics()
    }
    
    func resetLevelStatistics() {
        levelData = LevelStatistics()
    }

    func completeLevel() {
        // Update statistics with current game time before completing level
        updateStatisticsWithGameTime()
        
        sessionData.updateFromLevel(levelData)
        levelData = LevelStatistics()
    }

    func saveGame() {
        // Update statistics with current game time before saving
        updateStatisticsWithGameTime()
        
        // Ensure gameMode is set to classic
        gameState.gameMode = .classic
        
        // Save all game data
        gameState.saveGameState()
        levelData.saveLevelData(levelData)
        sessionData.saveSessionData()
        tileManager.saveTileManager(for: .classic)
    }

    func updateUserStatistics(_ userStatistics: UserStatistics) {
        // Update statistics with current game time before updating user statistics
        updateStatisticsWithGameTime()
        
        sessionData.updateFromLevel(levelData)
        userStatistics.updateFromSession(sessionData)
        userStatistics.updateHighestLevel(level: gameState.level, score: gameState.score)
        userStatistics.saveUserStatistics()
    }

    // MARK: - Extra Life Methods
    
    func canUseExtraLife() -> Bool {
        return getPowerupCount(.extraLife) > 0 && extraLivesUsedInSession < maxExtraLivesPerSession
    }
    
    func useExtraLifeAndContinue() -> Bool {
        if canUseExtraLife() {
            if useExtraLifePowerup() {
                // Update the extra life count first
                extraLivesUsedInSession += 1
                
                // First update UI state to dismiss popup immediately
                showExtraLifePopup = false
                firePositionCausingGameOver = nil
                
                // Reset game state
                gameOver = false
                gameplayState = .active
                
                // Use DispatchQueue.main.async to allow the UI to update before the potentially intensive scramble operation
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    // Generate a completely new board with only regular tiles
                    // This is done after UI updates to prevent blocking the main thread
                    self.tileManager.scramble(regularTilesOnly: true)
                }
                
                return true
            }
        }
        return false
    }
    
    func getExtraLivesUsedInSession() -> Int {
        return extraLivesUsedInSession
    }
    
    func getMaxExtraLivesPerSession() -> Int {
        return maxExtraLivesPerSession
    }
    
    func getExtraLifeTimerProgress() -> Double {
        return extraLifeTimeRemaining / extraLifeTotalTime
    }
    
    func startExtraLifeTimer() {
        // Reset the timer
        extraLifeTimeRemaining = extraLifeTotalTime
        
        // Cancel any existing timer
        extraLifeTimer?.invalidate()
        
        // Create a new timer that fires every 0.1 seconds
        extraLifeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.extraLifeTimeRemaining > 0 {
                self.extraLifeTimeRemaining -= 0.1
            } else {
                // Time's up, proceed with game over
                self.stopExtraLifeTimer()
                self.proceedWithGameOver()
            }
        }
    }
    
    func stopExtraLifeTimer() {
        extraLifeTimer?.invalidate()
        extraLifeTimer = nil
    }
    
    func showExtraLifePopupIfAvailable(firePosition: Position) -> Bool {
        if canUseExtraLife() {
            showExtraLifePopup = true
            firePositionCausingGameOver = firePosition
            startExtraLifeTimer()
            return true
        }
        return false
    }
    
    func proceedWithGameOver() {
        stopExtraLifeTimer()
        showExtraLifePopup = false
        firePositionCausingGameOver = nil
        handleGameOver()
    }

    func handleGameOver() {
        DispatchQueue.main.async {
            // First check if we can show the extra life popup
            if let firePosition = self.tileManager.findBottomRowFireTile(),
               self.showExtraLifePopupIfAvailable(firePosition: firePosition) {
                // If we can show the popup, don't trigger game over yet
                return
            }
            
            // Otherwise proceed with normal game over
            AudioManager.shared.playSoundEffect(named: "game_over_sound")
            self.gameOver = true
            // gameplayState will be updated via the didSet on gameOver
        }
    }
    
    // MARK: - State & Notification Management
    
    private func handleGameplayStateChange(from oldState: GameManager.GameplayState, to newState: GameManager.GameplayState) {
        print("Gameplay state changed from \(oldState) to \(newState)")
        
        // Post notification for state change that other components can observe
        NotificationCenter.default.post(
            name: .gameplayStateChanged, 
            object: self,
            userInfo: ["oldState": oldState, "newState": newState]
        )
        
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
    
    private func setupGameOverHandler() {
        tileManager.gameOverHandler = { [weak self] in
            self?.handleGameOver()
        }
    }
    
    func hasFireTile() -> Bool {
        // Check if there are any fire tiles on the board
        for row in tileManager.grid {
            for tile in row {
                if tile.type == .fire {
                    return true
                }
            }
        }
        return false
    }
    
    func handleFireTile() {
        if hasFireTile() {
            changeSprite(to: "nervous_sprite") // Change to nervous sprite
        } else {
            changeSprite(to: "normal_sprite") // Revert to normal if no fire tiles
        }
    }
    
    func changeSprite(to sprite: String, for duration: TimeInterval = 1.0) {
        // Call the spriteChangeHandler closure to update the sprite
        spriteChangeHandler?(sprite, duration)
    }
    
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
    
    @objc private func handleAppDidBecomeActive() {
        print("App became active")
        // Only restart timer if we're in GameView and gameplay is active
        if isInGameView && gameplayState == .active {
            resumeGameTimer()
        }
    }
    
    @objc private func handleGameViewDidAppear() {
        print("GameView appeared")
        isInGameView = true
        // Only start timer if gameplay is active
        if gameplayState == .active {
            startGameTimer()
        }
    }
    
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

    // MARK: - Timer Methods
    
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
    
    func startGameTimer() {
        // Avoid multiple timers
        guard gameStartTime == nil else { return }
        gameStartTime = Date()
        print("Game timer started.")
    }
    
    func pauseGameTimer() {
        if let startTime = gameStartTime {
            // Add elapsed time to accumulated time
            accumulatedGameTime += Date().timeIntervalSince(startTime)
            gameStartTime = nil
            print("Game timer paused. Accumulated time: \(accumulatedGameTime.formattedCompact)")
        }
    }
    
    func resumeGameTimer() {
        if gameStartTime == nil {
            gameStartTime = Date()
            print("Game timer resumed. Accumulated time: \(accumulatedGameTime.formattedCompact)")
        }
    }
    
    func stopGameTimer() {
