//
//  GameManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/10/24.
//

import Foundation
import SwiftUI

class GameManager: ObservableObject, Codable {
    @Published var gameState: GameState
    @Published var levelData: LevelStatistics
    @Published var sessionData: SessionStatistics
    @Published var tileManager: TileManager // Now Codable

    var levelSystem: [Int: Int] = [:]
    private let dictionaryManager: DictionaryManager

    enum CodingKeys: String, CodingKey {
        case gameState, levelData, sessionData, levelSystem, tileManager
    }

    init(dictionaryManager: DictionaryManager) {
        self.dictionaryManager = dictionaryManager
        
        // Load GameState from disk if available, otherwise initialize a new GameState
        if let loadedGameState = GameState.loadGameState() {
            self.gameState = loadedGameState
        } else {
            self.gameState = GameState()
        }
        
        // Initialize level and session data
        
        self.levelData = LevelStatistics.loadLevelData()
        self.sessionData = SessionStatistics.loadSessionData()
        
        // Load TileManager from disk if available, otherwise initialize a new TileManager
        if let loadedTileManager = TileManager.loadTileManager(dictionaryManager: dictionaryManager) {
            self.tileManager = loadedTileManager
        } else {
            let letterGenerator = LetterGenerator()
            let tileTypeGenerator = TileTypeGenerator()
            let tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator)
            let tileConverter = TileConverter()
            let wordChecker = WordChecker(wordStore: dictionaryManager.wordDictionary)
            self.tileManager = TileManager(tileGenerator: tileGenerator, tileConverter: tileConverter, wordChecker: wordChecker)
        }
        
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
            handleSessionCompletion(userStatistics: userStatistics)
            userStatistics.totalGamesPlayed += 1
            gameState.reset()
            levelData = LevelStatistics()
            sessionData = SessionStatistics()
            tileManager.generateInitialGrid()
        }
        // Otherwise, keep the board and gameState as is
        
    }

    // Submit a word and handle score/word streak updates
    func submitWord() -> Bool {
        if gameState.gameOver || !tileManager.validateWord() {
            return false
        }

        let word = tileManager.getWord()
        gameState.shortWordStreak = word.count == 3 ? gameState.shortWordStreak + 1 : 0
        let points = tileManager.getScore()
        gameState.score += points
        levelData.trackWord(word, score: points)
        tileManager.processWordSubmission(word: word, points: points, level: gameState.level, shortWordStreak: gameState.shortWordStreak)

        return true
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

    // Method to set up the game over handler
    private func setupGameOverHandler() {
        tileManager.gameOverHandler = { [weak self] in
            self?.gameState.handleGameOver()
        }
    }
}
