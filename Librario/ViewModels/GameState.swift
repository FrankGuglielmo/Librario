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

    init() {
        let letterGenerator = LetterGenerator()
        let tileTypeGenerator = TileTypeGenerator()
        let tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator)
        let tileConverter = TileConverter()
        let wordChecker = WordChecker(wordStore: WordStore())
        
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

    // Other game state methods...

    func selectTile(position: Position) {
        tileManager.selectTile(at: position)
    }

    func deselectTile(position: Position) {
        tileManager.deselectTile(at: position)
    }

    func toggleTileSelection(position: Position) {
        tileManager.toggleTileSelection(at: position)
    }
    
    
    func submitWord() -> Bool {
        if tileManager.validateWord() {
            return tileManager.submitWord()
        } else {
            return false
        }
    }
}


