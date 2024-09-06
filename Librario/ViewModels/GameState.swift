//
//  GameState.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import Foundation
import SwiftUI

class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var level: Int = 1
    
    var tileManager: TileManager
    var shortWordStreak: Int = 0
    
    // Define the level system dictionary
    var levelSystem: [Int: Int] = [:]

    init(dictionaryManager:DictionaryManager) {
        let letterGenerator = LetterGenerator()
        let tileTypeGenerator = TileTypeGenerator()
        let tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator)
        let tileConverter = TileConverter()
        //Initialize the WordChecker with the given wordDictioanry
        let wordChecker = WordChecker(wordStore: dictionaryManager.wordDictionary)
        
        self.tileManager = TileManager(
            tileGenerator: tileGenerator,
            tileConverter: tileConverter,
            wordChecker: wordChecker
        )
        
        setupLevelSystem()
        
        startNewGame()
    }

    func startNewGame() {
        score = 0
        level = 1
        tileManager.clearSelection()
        tileManager.generateInitialGrid()
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
        
        //Check if selected words is word
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
        
        let points = tileManager.getScore()
        
        tileManager.processWordSubmission(word: word, points: points, level: level, shortWordStreak: self.shortWordStreak)
        
        score += points
        
        //Check the current game score, update level if necessary
        checkLevelProgression()
        
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


