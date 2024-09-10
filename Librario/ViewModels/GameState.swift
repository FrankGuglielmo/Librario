//
//  GameState.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import Foundation
import SwiftUI

class GameState: ObservableObject, Codable {
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var gameOver: Bool = false // Track if the game is over
    
    var tileManager: TileManager
    var shortWordStreak: Int = 0
    
    // Define the level system dictionary
    var levelSystem: [Int: Int] = [:]
    
    // Keys for UserDefaults
    private enum CodingKeys: String, CodingKey {
        case score, level, shortWordStreak, levelSystem, tileManager
    }

    // Initializer (with gameOverHandler setup)
    init(dictionaryManager: DictionaryManager) {
        let letterGenerator = LetterGenerator()
        let tileTypeGenerator = TileTypeGenerator()
        let tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator)
        let tileConverter = TileConverter()
        let wordChecker = WordChecker(wordStore: dictionaryManager.wordDictionary)
        
        self.tileManager = TileManager(
            tileGenerator: tileGenerator,
            tileConverter: tileConverter,
            wordChecker: wordChecker
        )
        
        // Set the game over handler
        setupGameOverHandler()

        setupLevelSystem()
    }

    // Decodable initializer
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Int.self, forKey: .score)
        level = try container.decode(Int.self, forKey: .level)
        shortWordStreak = try container.decode(Int.self, forKey: .shortWordStreak)
        tileManager = try container.decode(TileManager.self, forKey: .tileManager)

        // Re-initialize non-Codable properties
        let dictionaryManager = DictionaryManager()
        tileManager.reinitializeNonCodableProperties(dictionaryManager: dictionaryManager)
        
        // Set the game over handler after decoding
        setupGameOverHandler()

        setupLevelSystem()
    }

    // Method to set the gameOverHandler
    func setupGameOverHandler() {
        tileManager.gameOverHandler = { [weak self] in
            guard let self = self else {
                print("GameState is nil, cannot handle game over")
                return
            }
            print("Game over handler called")
            self.handleGameOver()
        }
    }

    // Encodable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(score, forKey: .score)
        try container.encode(level, forKey: .level)
        try container.encode(shortWordStreak, forKey: .shortWordStreak)
        try container.encode(tileManager, forKey: .tileManager)
    }

    // Function to handle game over
    func handleGameOver() {
        print("Game over triggered in GameState!")
        gameOver = true // Set game over flag
    }

    func startNewGame() {
        print("Starting new game: resetting score, level, and grid.")
        score = 0
        level = 1
        shortWordStreak = 0
        gameOver = false // Reset the game over flag
        tileManager.clearSelection()
        tileManager.generateInitialGrid()
    }
    
    // Save game state
    func saveGameState() {
        if let encodedData = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encodedData, forKey: "savedGameState")
        }
    }

    // Load game state and ensure the gameOverHandler is set
    static func loadGameState(dictionaryManager: DictionaryManager) -> GameState {
        if let savedData = UserDefaults.standard.data(forKey: "savedGameState"),
           let decodedGameState = try? JSONDecoder().decode(GameState.self, from: savedData) {
            // After decoding, reset the gameOverHandler
            decodedGameState.setupGameOverHandler()
            return decodedGameState
        } else {
            return GameState(dictionaryManager: dictionaryManager)
        }
    }

    func selectTile(position: Position) {
        tileManager.selectTile(at: position)
    }

    func deselectTile(position: Position) {
        tileManager.deselectTile(at: position)
    }

    func toggleTileSelection(position: Position) {
        tileManager.toggleTileSelection(at: position)
    }
    
    /**
     If able to submit word, update the game score and shortWordStreak 
     */
    func submitWord() -> Bool {
        // Prevent word submission if the game is over
        if gameOver {
            print("Cannot submit word, game is over.")
            return false
        }

        // Check if selected tiles form a valid word
        if !tileManager.validateWord() {
            return false
        }

        // Word is valid, update GameState
        let word = tileManager.getWord()
        if word.count == 3 {
            self.shortWordStreak += 1
        } else {
            self.shortWordStreak = 0
        }
        
        // Calculate points and update the score
        let points = tileManager.getScore()
        score += points
        print("Word submitted: \(word), points: \(points), score updated to \(score)")

        // Process word submission (clear tiles, move others down, etc.)
        tileManager.processWordSubmission(word: word, points: points, level: level, shortWordStreak: self.shortWordStreak)
        
        // Now, after processing the word, check for fire tiles and potential game-over conditions
        tileManager.checkFireTiles()

        // If the game is still running, check level progression
        if !gameOver {
            checkLevelProgression()
        }

        return true
    }
    
    private func checkLevelProgression() {
        // Check if the current score exceeds the required points for the next level
        if level < 999 && score >= levelSystem[level]! {
            level += 1
        }
    }
    
    private func setupLevelSystem() {
        let experienceScale = 2250.0 // Your experience scale
        
        for level in 1...999 {
            // Experience required to reach this level
            let requiredExperience = Double(level) * experienceScale
            
            // If it's the first level, just set it to the required experience
            if level == 1 {
                levelSystem[level] = Int(requiredExperience)
            } else {
                // For all subsequent levels, add the required experience to the previous level's total
                levelSystem[level] = levelSystem[level - 1]! + Int(requiredExperience)
            }
        }
        
        // Example output to see the first 10 levels
        for level in 1...10 {
            print("Level \(level): \(levelSystem[level]!) points")
        }

        print("...")
        print("Level 999: \(levelSystem[999]!) points")
    }

        
}


