//
//  WordChecker.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/19/24.
//

import Foundation

class WordChecker {
    private let wordStore: WordStore

    init(wordStore: WordStore) {
        self.wordStore = wordStore
    }

    // Calculate the score of the selected tiles
    func calculateScore(for tiles:[Tile], tileMultiplier:[TileType:Double]) -> Int {
        var score: Int = 0
        var multiplier: Double = 1.0
        
        for tile in tiles {
            score += tile.points
            if tileMultiplier[tile.type]! > multiplier {
                multiplier = tileMultiplier[tile.type]!
            }
        }
        
        //Multiply the base score by the weight of the most significant TileType in the word
        var weightedScore = Double(score) * multiplier
        return Int(weightedScore)
    }
    
    // References the wordStore to
    func isWord(tiles:[Tile]) -> Bool {
        let word = tiles.map { $0.letter }.joined()
        return isWord(word: word)
    }
    
    // Checks the wordStore to see if word is valid
    func isWord(word: String) -> Bool {
        return wordStore.isWordValid(word)
    }
        
    
}

