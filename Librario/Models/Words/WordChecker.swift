//
//  WordChecker.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/19/24.
//

import Foundation

class WordChecker: Codable {
    private let wordStore: [String:String?]

    init(wordStore: [String:String?]) {
        self.wordStore = wordStore
    }

    // Calculate the score of the selected tiles
    func calculateScore(for tiles: [Tile], tileMultiplier: [TileType: Double]) -> Int {
        var score: Int = 0
        var totalMultiplier: Double = 1.0
        
        for tile in tiles {
            score += tile.points
            
            // Stack multipliers for tiles that have equal or higher multipliers
            if let tileTypeMultiplier = tileMultiplier[tile.type] {
                if tileTypeMultiplier >= totalMultiplier {
                    totalMultiplier += tileTypeMultiplier - 1.0 // Add the additional multiplier value
                }
            }
        }
        
        // Multiply the base score by the cumulative multiplier
        let weightedScore = Double(score) * totalMultiplier
        return Int(weightedScore)
    }
    
    // References the wordStore to
    func isWord(tiles:[Tile]) -> Bool {
        let word = tiles.map { $0.letter }.joined()
        return isWord(word: word)
    }
    
    // Checks the wordStore to see if word is valid
    func isWord(word: String) -> Bool {
        return wordStore.keys.contains(word.lowercased())
    }
        
    
}

