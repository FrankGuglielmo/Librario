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
    
    // MARK: - Swap Mode Methods
    
    // MARK: - Wildcard Mode Methods
    
    /**
     * Enters wildcard mode if the user has wildcard powerups available.
     * 
     * @return `true` if wildcard mode was entered successfully; otherwise, `false`.
     */
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
    
    /**
     * Exits wildcard mode and resets all wildcard-related state.
     */
    func exitWildcardMode() {
        isInWildcardMode = false
        selectedWildcardTile = nil
        targetWildcardLetter = nil
        showWildcardSelection = false
        showWildcardConfirmation = false
    }
    
    /**
     * Selects a tile for wildcard letter change.
     * 
     * @param position The position of the tile to select.
     * @return `true` if the selection was valid; otherwise, `false`.
     */
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
    
    /**
     * Selects a letter for the wildcard change and shows confirmation.
     * 
     * @param letter The letter to change to.
     * @return `true` if the selection was valid; otherwise, `false`.
     */
    func selectWildcardLetter(letter: String) -> Bool {
        guard isInWildcardMode && selectedWildcardTile != nil else { return false }
        
        targetWildcardLetter = letter
        showWildcardSelection = false
        showWildcardConfirmation = true
        return true
    }
    
    /**
     * Confirms the wildcard letter change, performs the change operation, decrements the powerup count,
     * and exits wildcard mode.
     */
    func confirmWildcardChange() {
        guard let tile = selectedWildcardTile, let letter = targetWildcardLetter else { return }
        
        changeTileLetter(at: tile.position, to: letter)
        usePowerup(.wildcard) // Decrement the powerup count
        exitWildcardMode()
    }
    
    /**
     * Changes a tile's letter at the given position.
     * 
     * @param position The position of the tile to change.
     * @param letter The new letter for the tile.
     */
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
    
    /**
     * Enters swap mode if the user has swap powerups available.
     * 
     * @return `true` if swap mode was entered successfully; otherwise, `false`.
     */
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
    
    /**
     * Exits swap mode and resets all swap-related state.
     */
    func exitSwapMode() {
        isInSwapMode = false
        selectedSwapTile = nil
        targetSwapTile = nil
        adjacentTiles = []
        showSwapConfirmation = false
    }
    
    /**
     * Selects a tile for swapping. If this is the first tile selected,
     * it will calculate and store adjacent tiles. If this is the second tile,
     * it will check if it's adjacent and show the confirmation dialog.
     * If the selected tile is already selected, it will deselect it.
     * 
     * @param position The position of the tile to select.
     * @return `true` if the selection was valid; otherwise, `false`.
     */
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
    
    /**
     * Gets all valid adjacent tile positions for a given position.
     * 
     * @param position The position to get adjacent tiles for.
     * @return An array of adjacent positions.
     */
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
    
    /**
     * Checks if two tiles can be swapped.
     * 
     * @param from The position of the first tile.
     * @param to The position of the second tile.
     * @return `true` if the tiles can be swapped; otherwise, `false`.
     */
    func canSwapTiles(from: Position, to: Position) -> Bool {
        return adjacentTiles.contains(to)
    }
    
    /**
     * Swaps the tiles at the given positions.
     * 
     * @param from The position of the first tile.
     * @param to The position of the second tile.
     */
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
    
    /**
     * Confirms the swap, performs the swap operation, decrements the powerup count,
     * and exits swap mode.
     * 
     * @param from The position of the first tile.
     * @param to The position of the second tile.
     */
    func confirmSwap(from: Position, to: Position) {
        swapTiles(from: from, to: to)
        usePowerup(.swap) // Decrement the powerup count
        exitSwapMode()
    }

    /**
     * Initializes a new `GameManager` with the provided `DictionaryManager` and optional `UserData`.
     *
     * @param dictionaryManager The `DictionaryManager` instance used to manage dictionary data.
     * @param userData The optional `UserData` instance for accessing user's inventory and statistics.
     */
    init(dictionaryManager: DictionaryManager, userData: UserData? = nil) {
        self.userData = userData
        if let userData = userData {
            self.userInventory = userData.inventory
        }
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
     * Also updates the user's inventory of coins and diamonds based on special tiles used.
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
        
        // Update user's inventory based on special tiles
        updateInventoryFromSubmittedWord(word: word)
        
        tileManager.processWordSubmission(word: word, points: points, level: gameState.level)
    }
    
    /**
     * Updates the user's inventory based on the special tiles used in the submitted word.
     * - Diamond tiles: Add 1 diamond per diamond tile used
     * - Gold tiles: Add coins equal to the word length multiplied by the number of gold tiles used
     *
     * @param word The submitted word
     */
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

        // MARK: - Extra Life Methods
    
    /**
     * Checks if the player can use an extra life powerup.
     *
     * @return `true` if the player has an extra life available and has used fewer than 3 in the current session; otherwise, `false`.
     */
    func canUseExtraLife() -> Bool {
        return getPowerupCount(.extraLife) > 0 && extraLivesUsedInSession < maxExtraLivesPerSession
    }
    
    /**
     * Uses an extra life powerup and generates a new board without special tiles.
     *
     * @return `true` if the extra life was successfully used; otherwise, `false`.
     */
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
    
    /**
     * Gets the number of extra lives used in the current session.
     *
     * @return The number of extra lives used in the current session.
     */
    func getExtraLivesUsedInSession() -> Int {
        return extraLivesUsedInSession
    }
    
    /**
     * Gets the maximum number of extra lives allowed per session.
     *
     * @return The maximum number of extra lives allowed per session.
     */
    func getMaxExtraLivesPerSession() -> Int {
        return maxExtraLivesPerSession
    }
    
    /**
     * Gets the current extra life timer progress as a percentage (0.0 to 1.0).
     *
     * @return The current timer progress as a percentage.
     */
    func getExtraLifeTimerProgress() -> Double {
        return extraLifeTimeRemaining / extraLifeTotalTime
    }
    
    /**
     * Starts the extra life timer.
     */
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
    
    /**
     * Stops the extra life timer.
     */
    func stopExtraLifeTimer() {
        extraLifeTimer?.invalidate()
        extraLifeTimer = nil
    }
    
    /**
     * Shows the extra life popup if the player has extra lives available.
     *
     * @param firePosition The position of the fire tile that triggered the game over.
     * @return `true` if the popup was shown; otherwise, `false`.
     */
    func showExtraLifePopupIfAvailable(firePosition: Position) -> Bool {
        if canUseExtraLife() {
            showExtraLifePopup = true
            firePositionCausingGameOver = firePosition
            startExtraLifeTimer()
            return true
        }
        return false
    }
    
    /**
     * Proceeds with game over if the player chooses not to use an extra life or time expires.
     */
    func proceedWithGameOver() {
        stopExtraLifeTimer()
        showExtraLifePopup = false
        firePositionCausingGameOver = nil
        handleGameOver()
    }

    /**
     * Handles the game over state by playing the game over sound and updating the game state.
     */
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
