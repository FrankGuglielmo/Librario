//
//  TileGenerator.swift
//  Librario
//
//  This class is responsible for creting new tiles to fill the board
//  at the start of a game and when words have been submmitted.
//
//  Created by Frank Guglielmo on 8/18/24.
//

import Foundation

class TileGenerator {
    
    private let letterToPointValue: [String: Int] = [
            "A": 100, "B": 150, "C": 150, "D": 100, "E": 100,
            "F": 150, "G": 150, "H": 150, "I": 100, "J": 200,
            "K": 150, "L": 100, "M": 150, "N": 100, "O": 100,
            "P": 150, "Qu": 300, "Q": 200, "R": 100, "S": 100,
            "T": 100, "U": 100, "V": 200, "W": 150, "X": 200,
            "Y": 150, "Z": 200
        ]
        
        private let letterGenerator: LetterGenerator
        private let tileTypeGenerator: TileTypeGenerator
        
        init(letterGenerator: LetterGenerator, tileTypeGenerator: TileTypeGenerator) {
            self.letterGenerator = letterGenerator
            self.tileTypeGenerator = tileTypeGenerator
        }
        
        // Create a new Tile object based on current game state
    func generateTile(position:Position, word: String, points: Int, level: Int, shortWordStreak: Int) -> Tile {
        // Generate the letter for the tile
        let letter = letterGenerator.generateLetter()
        
        // Map the letter to its point value
        let tilePoints = letterToPointValue[letter] ?? 100 // Default to 100 if not found
        
        // Generate the type of the tile
        let tileType = tileTypeGenerator.generateTileTypes(word: word, points: points, level: level, shortWordStreak: shortWordStreak, tilesToGenerate: 1).first ?? .regular
        
        // Return the generated tile
        return Tile(letter: letter, type: tileType, isSelected: false, points: tilePoints, position: position)
    }
    
    // Generate a regular tile, mostly meant for initial game Tile Generation
    func generateTile(at position: Position) -> Tile {
        let letter = letterGenerator.generateLetter()
        let tileType = TileType.regular  // Default to a neutral/regular TileType
        let tilePoints = letterToPointValue[letter] ?? 100 // Default to 100 if not found
        return Tile(letter: letter, type: tileType, isSelected: false, points: tilePoints, position: position)
    }
    
        
}

