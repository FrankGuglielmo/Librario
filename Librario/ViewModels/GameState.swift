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
    
    private var levelThreshold: Int = 2500 // Initial threshold to reach level 2
    private let thresholdMultiplier: Double = 1.2 // Increase the threshold by 20% each level

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
        // Check if the current score exceeds the level threshold
        if score >= levelThreshold {
            level += 1
            // Increase the threshold for the next level
            levelThreshold = level + Int(Double(levelThreshold) * thresholdMultiplier)
        }
    }
}


