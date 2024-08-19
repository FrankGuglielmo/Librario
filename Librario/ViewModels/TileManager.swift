//
//  TileManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import Foundation
import SwiftUI

class TileManager: ObservableObject {
    @Published var grid: [[Tile]] = []
    // Stack to keep track of the order in which tiles were selected
    @Published var selectedTiles: [Tile] = []
    
    private var tileGenerator: TileGenerator
    private var tileConverter: TileConverter
    private var wordChecker: WordChecker
    
    
    
    
    private var tileMultiplier: [TileType:Double] = [
        TileType.fire: 1.0,
        TileType.regular: 1.0,
        TileType.green: 1.5,
        TileType.gold: 2.0,
        TileType.diamond: 3.0
        
    ]
    
    var wordStore: WordStore = WordStore() //TODO

    init(tileGenerator: TileGenerator, tileConverter: TileConverter, wordChecker: WordChecker) {
        self.tileGenerator = tileGenerator
        self.tileConverter = tileConverter
        self.wordChecker = wordChecker //TODO
        generateInitialGrid()
    }

    // MARK: - Grid and Tile Management

    /**
     Creates the initial grid of tiles.
     */
    func generateInitialGrid() {
        grid = (0..<7).map { row in
            (0..<7).map { column in
                tileGenerator.generateTile(at: Position(row: row, column: column))
            }
        }
    }

    /**
     Updates the tile position with a new tile.
     */
    func updateTile(at position: Position, with newTile: Tile) {
        guard position.row >= 0 && position.row < grid.count &&
              position.column >= 0 && position.column < grid[0].count else {
            return
        }
        //Ensure the new tile is at the same position of the one to be overridden
        if newTile.position == position {
            grid[position.row][position.column] = newTile
        }
    }

    // MARK: - Tile Selection and Validation

    /**
     Change the tile to it's selected version
     */
    func selectTile(at position: Position) {
        guard var tile = getTile(at: position) else { return }

        // Ensure the tile is selectable (it must be adjacent to the last selected tile if the stack is not empty)
        if let lastSelectedTile = selectedTiles.last, !isAdjacent(tile, to: lastSelectedTile) {
            return // Cannot select a non-adjacent tile
        }
        
        tile.isSelected = true  // Change to selected state
        updateTile(at: position, with: tile)  // Update the grid with the new state
        selectedTiles.append(tile)  // Push the selected tile onto the stack
        //selectedTiles = selectionStack  // Update the selectedTiles array
        print(selectedTiles)
    }

    /**
     Change the tile to it's unselected version. If there are subsequent tiles on the selection stack from the tile to be deselected, deselect those tiles and keep the selected version of the tile to be deseleceted. Update the selectedTiles with the new stack.
     */
    func deselectTile(at position: Position) {
        
        guard let tile = getTile(at: position) else { return }
        // Check if the tile is in the stack and remove it and all tiles above it
        if let index = selectedTiles.firstIndex(where: { $0.id == tile.id }) {
            
            // If this is the last tile in the stack, deselect it
            if selectedTiles.count == index + 1 {
                deselectTileWithoutUpdate(tile: tile)
                selectedTiles.removeLast()  // Remove the tile itself from the stack
            }
            
            // If there are tiles above this one in the stack, pop them off
            while selectedTiles.count > index + 1 { // Keep the tile selected, so only pop the ones above it
                let topTile = selectedTiles.removeLast()  // Pop off the stack
                deselectTileWithoutUpdate(tile: topTile)  // Deselect without triggering stack removal again
            }
        }
    }

    private func deselectTileWithoutUpdate(tile: Tile) {
        guard var tileToDeselect = getTile(at: tile.position) else { return }
        tileToDeselect.isSelected = false
        updateTile(at: tile.position, with: tileToDeselect)
    }


    func toggleTileSelection(at position: Position) {
        if let tile = getTile(at: position) {
            if tile.isSelected {
                deselectTile(at: position)
            } else {
                selectTile(at: position)
            }
        }
    }

    /**
     Update the grid, pop the selection stack, and clear the selectedTiles
     */
    func clearSelection() {
            for tile in selectedTiles {
                deselectTileWithoutUpdate(tile: tile)
            }
            selectedTiles.removeAll()
        }

    func validateWord() -> Bool {
        let word = selectedTiles.map { $0.letter }.joined()
        print(word.count)
        return !selectedTiles.isEmpty && word.count > 2 // Simple validation example
    }

    // MARK: - Word Submission Handling

    func submitWord() -> Bool {
        guard validateWord() else {
            clearSelection()
            return false
        }
        processWordSubmission()
        return true
    }

    private func processWordSubmission() {
        // 1. Remove the used tiles from the grid
        selectedTiles.forEach { tile in
            if let position = findTilePosition(tile) {
                grid[position.row][position.column] = Tile(letter: "", type: .regular, points: 100, position: position) //TODO
            }
        }

        // 2. Make tiles above fall to fill the gaps
        fillGridGaps()

        // 3. Generate new tiles and place them at the top of the grid
        generateNewTilesForTop()
        
        // Clear selection after processing
        clearSelection()
    }

    private func fillGridGaps() {
        for column in 0..<grid[0].count {
            var emptySpots = 0
            for row in (0..<grid.count).reversed() {
                if grid[row][column].letter.isEmpty {
                    emptySpots += 1
                } else if emptySpots > 0 {
                    grid[row + emptySpots][column] = grid[row][column]
                    grid[row][column] = Tile(letter: "", type: .regular, points: 100, position: Position(row: row, column: column)) //TODO
                }
            }
        }
    }

    private func generateNewTilesForTop() {
        for column in 0..<grid[0].count {
            for row in 0..<grid.count where grid[row][column].letter.isEmpty {
                let newTile = tileGenerator.generateTile(at: Position(row: row, column: column)) ///TODO: Use weighted generation function
                grid[row][column] = newTile
            }
        }
    }

    private func calculateScore(for tiles: [Tile]) -> Int {
        var score: Int = 0
        var multiplier: Double = 1.0
        
        for tile in tiles {
            score += tile.points
            if tileMultiplier[tile.type]! > multiplier {
                multiplier = tileMultiplier[tile.type]!
            }
        }
        
        var weightedScore = Double(score) * multiplier
        
        return Int(weightedScore)
    }

    private func shouldConvertTile(word: String, points: Int) -> Bool {
        return word.count >= 4 || points >= 1000 // Example conversion criteria
    }


    // MARK: - Tile Utility Methods

    private func isAdjacent(_ tile1: Tile, to tile2: Tile) -> Bool {
        let rowDiff = abs(tile1.position.row - tile2.position.row)
        let colDiff = abs(tile1.position.column - tile2.position.column)

        // Tiles must be in the same column, adjacent row, or adjacent columns with adjusted rows
        if colDiff > 1 {
            return false
        }

        if colDiff == 0 {
            // Same column, tiles are neighbors if they are directly above/below each other
            return rowDiff == 1
        } else if colDiff == 1 {
            // Adjacent columns
            if tile1.position.column % 2 == 0 {
                // Even column: can connect to the same row or the row above
                print(tile2.position.row - tile1.position.row)
                return rowDiff == 0 || rowDiff == 1 && (tile1.position.row - tile2.position.row == 1)
            } else {
                // Odd column: can connect to the same row or the row below
                print(tile2.position.row - tile1.position.row)
                return rowDiff == 0 || rowDiff == 1 && (tile2.position.row - tile1.position.row == 1)
            }
        }

        return false
    }



    private func findTilePosition(_ tile: Tile) -> Position? {
        for row in 0..<grid.count {
            for column in 0..<grid[row].count {
                if grid[row][column].id == tile.id {
                    return Position(row: row, column: column)
                }
            }
        }
        return nil
    }

    func getTile(at position: Position) -> Tile? {
        guard position.row >= 0 && position.row < grid.count &&
                position.column >= 0 && position.column < grid[0].count else {
            return nil
        }
        return grid[position.row][position.column]
    }
    
    
    
    
    
    
}

