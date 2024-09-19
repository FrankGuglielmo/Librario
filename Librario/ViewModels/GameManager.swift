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

    var levelSystem: [Int: Int] = [:]
    private let dictionaryManager: DictionaryManager
    
    // Closure to trigger sprite changes in the GameView
    var spriteChangeHandler: ((String, TimeInterval) -> Void)?

    enum CodingKeys: String, CodingKey {
        case gameState, levelData, sessionData, levelSystem, tileManager
    }

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

    // Set up the level system (moved from GameState)
    private func setupLevelSystem() {
        let experienceScale = 2250.0
        for level in 1...999 {
            let requiredExperience = Double(level) * experienceScale
            levelSystem[level] = level == 1 ? Int(requiredExperience) : levelSystem[level - 1]! + Int(requiredExperience)
        }
    }

    // Method to start a new game
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

    // Submit a word and handle score/word streak updates
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


    // Check if the player should progress to the next level
    func checkLevelProgression() -> Bool{
        if gameState.level < 999 && gameState.score >= levelSystem[gameState.level]! {
            gameState.level += 1
            print("Level progressed to: \(gameState.level)")
            return true
        }
        return false
    }
    
    func handleLevelCompletion() {
        //Update the session statistics with the level statistics
        sessionData.updateFromLevel(levelData)
    }
    
    func handleSessionCompletion(userStatistics: UserStatistics) {
        handleLevelCompletion() // Update the session with the current level statistics
        userStatistics.updateFromSession(sessionData)
        userStatistics.saveUserStatistics()
    }
    
    func resetLevelStatistics() {
        levelData = LevelStatistics()
    }

    // Method to complete a level and update session data
    func completeLevel() {
        sessionData.updateFromLevel(levelData)
        levelData = LevelStatistics()
    }

    // Save the game state
    func saveGame() {
        gameState.saveGameState()
        levelData.saveLevelData(levelData)
        sessionData.saveSessionData()
        tileManager.saveTileManager()
    }

    // Update UserStatistics with session data at the end of a game
    func updateUserStatistics(_ userStatistics: UserStatistics) {
        sessionData.updateFromLevel(levelData)
        userStatistics.updateFromSession(sessionData)
        userStatistics.saveUserStatistics()
    }

    // Method to handle game over
    func handleGameOver() {
        DispatchQueue.main.async {
            AudioManager.shared.playSoundEffect(named: "game_over_sound")
            self.gameOver = true
        }
    }
    
    // Method to set up the game over handler
    private func setupGameOverHandler() {
        tileManager.gameOverHandler = { [weak self] in
            self?.handleGameOver()
        }
    }
    // Function to check for fire tiles on the board
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
    
    // Function to handle fire tile detection
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
}
