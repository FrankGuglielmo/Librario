//
//  GameManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/10/24.
//

import Foundation
import SwiftUI

class GameManager: ObservableObject, Codable {
    @Published var gameOver: Bool = false
    @Published var gameState: GameState
    @Published var levelData: LevelStatistics
    @Published var sessionData: SessionStatistics
    @Published var tileManager: TileManager
    
    // Timer-related properties
    private var levelTimer: Timer?

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
        //Update the session statistics with the level statistics
        sessionData.updateFromLevel(levelData)
        sessionData.saveSessionData()
    }
    
    /**
     * Updates the session statistics and user statistics upon game session completion.
     *
     * @param userStatistics The `UserStatistics` instance to update with session data.
     */
    func handleSessionCompletion(userStatistics: UserStatistics) {
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
        sessionData.updateFromLevel(levelData)
        levelData = LevelStatistics()
    }

    /**
     * Saves the current game state, level data, session data, and tile manager to persistent storage.
     */
    func saveGame() {
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
        sessionData.updateFromLevel(levelData)
        userStatistics.updateFromSession(sessionData)
        userStatistics.updateHighestlevel(level: gameState.level)
        userStatistics.saveUserStatistics()
    }

    /**
     * Handles the game over state by playing the game over sound and updating the game state.
     */
    func handleGameOver() {
        DispatchQueue.main.async {
            AudioManager.shared.playSoundEffect(named: "game_over_sound")
            self.gameOver = true
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
    
    // Start the level timer
    func startLevelTimer() {
        // Avoid multiple timers
        guard levelTimer == nil else { return }
        // Start timing in LevelStatistics
        levelData.startLevel()
        print("Level timer started.")
    }
    
    // Stop the level timer
    func stopLevelTimer() {
        // Invalidate and nil the timer
        levelTimer?.invalidate()
        levelTimer = nil
        // Update SessionStatistics with the updated LevelStatistics
        sessionData.updateFromLevel(levelData)
        sessionData.saveSessionData()
        print("Level timer stopped.")
    }
    
    
}
