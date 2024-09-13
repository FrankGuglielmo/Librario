//
//  TileManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import Foundation
import SwiftUI

class TileManager: ObservableObject, Codable {
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

    
    var gameOverHandler: (() -> Void)? // Closure to notify GameState when the game is over
    
    let animationDuration: Double = 0.5
    
    // Coding Keys
    private enum CodingKeys: String, CodingKey {
        case grid, selectedTiles, tileMultiplier
    }

    // Initializer
    init(tileGenerator: TileGenerator, tileConverter: TileConverter, wordChecker: WordChecker) {
        self.tileGenerator = tileGenerator
        self.tileConverter = tileConverter
        self.wordChecker = wordChecker
        generateInitialGrid()
    }

    // Codable Conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        grid = try container.decode([[Tile]].self, forKey: .grid)
        selectedTiles = try container.decode([Tile].self, forKey: .selectedTiles)
        tileMultiplier = try container.decode([TileType: Double].self, forKey: .tileMultiplier)
        
        // Reinitialize the non-Codable properties
        let letterGenerator = LetterGenerator()
        let tileTypeGenerator = TileTypeGenerator()
        self.tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator)
        self.tileConverter = TileConverter()
        self.wordChecker = WordChecker(wordStore: DictionaryManager().wordDictionary)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(grid, forKey: .grid)
        try container.encode(selectedTiles, forKey: .selectedTiles)
        try container.encode(tileMultiplier, forKey: .tileMultiplier)
    }

    // Method to re-initialize non-Codable properties
    func reinitializeNonCodableProperties(dictionaryManager: DictionaryManager) {
        let letterGenerator = LetterGenerator()
        let tileTypeGenerator = TileTypeGenerator()
        self.tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator)
        self.tileConverter = TileConverter()
        self.wordChecker = WordChecker(wordStore: dictionaryManager.wordDictionary)
    }
    
    
    // MARK: - Persistence Methods
    
    func saveTileManager() {
        let fileURL = TileManager.getDocumentsDirectory().appendingPathComponent("tileManager.json")
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: fileURL)
            print("TileManager saved successfully.")
        } catch {
            print("Failed to save TileManager: \(error)")
        }
    }
    
    static func loadTileManager(dictionaryManager: DictionaryManager) -> TileManager? {
            let fileURL = getDocumentsDirectory().appendingPathComponent("tileManager.json")
            do {
                let data = try Data(contentsOf: fileURL)
                let tileManager = try JSONDecoder().decode(TileManager.self, from: data)
                tileManager.reinitializeNonCodableProperties(dictionaryManager: dictionaryManager)
                print("TileManager loaded successfully.")
                return tileManager
            } catch {
                print("Failed to load TileManager: \(error)")
                return nil
            }
        }
    
    static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
        if let lastSelectedTile = selectedTiles.last, !isAdjacent(lastSelectedTile, to: tile) {
            return // Cannot select a non-adjacent tile
        }
        
        tile.isSelected = true  // Change to selected state
        updateTile(at: position, with: tile)  // Update the grid with the new state
        selectedTiles.append(tile)  // Push the selected tile onto the stack
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

    // MARK: - Word Submission Handling

    
    func validateWord() -> Bool {
        if wordChecker.isWord(tiles: selectedTiles) {
            return true
        } else {
            return false
        }
    }

    /**
     Remove the tiles that were used for word submission. If there are any tiles above the ones removed (meaning it is in the same column and a lower row number), move them down until there are no more empty gaps. Add new tiles for the top of the board to fill in.
     */
    func processWordSubmission(word: String, points: Int, level: Int, shortWordStreak: Int) {
        // 1. Mark tiles for removal
        selectedTiles.forEach { tile in
            if let position = findTilePosition(tile) {
                grid[position.row][position.column].isMarkedForRemoval = true
            }
        }
        
        // 2. Move tiles down to fill gaps
        withAnimation(.easeOut(duration: animationDuration / 2)) {
            moveTilesDown()
        }
        
        // 3. After the existing tiles have fallen, generate new tiles
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            withAnimation(.easeInOut(duration: self.animationDuration)) {
                self.generateNewTilesForTop(word: word, points: points, level: level, shortWordStreak: shortWordStreak)
            }
        }
        
        // 4. Upgrade random tile if necessary (after new tiles are in place)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2 * animationDuration) {
            self.tileConverter.upgradeRandomTile(word: word, pointValue: points, grid: &self.grid)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2 * animationDuration) {
            withAnimation(.easeInOut(duration: self.animationDuration)) {
                self.checkFireTiles()
            }
        }
        
        // 5. Clear the selection
        clearSelection()
    }


    func moveTilesDown() {
        let rows = grid.count
        let columns = grid[0].count

        for column in 0..<columns {
            var newColumn: [Tile] = []
            // Collect tiles not marked for removal
            for row in 0..<rows {
                let tile = grid[row][column]
                if !tile.isMarkedForRemoval {
                    newColumn.append(tile)
                }
            }

            // Determine how many empty spaces are at the top
            let missingTiles = rows - newColumn.count

            // Update positions of existing tiles
            for i in 0..<newColumn.count {
                newColumn[i].position = Position(row: i + missingTiles, column: column)
            }

            // Replace the column in the grid
            for i in 0..<newColumn.count {
                grid[i + missingTiles][column] = newColumn[i]
            }

            // Fill empty spaces at the top with placeholders
            for i in 0..<missingTiles {
                let position = Position(row: i, column: column)
                grid[i][column] = Tile.placeholder(at: position)
            }
        }
    }

    func generateNewTilesForTop(word: String, points: Int, level: Int, shortWordStreak: Int) {
        let rows = grid.count
        let columns = grid[0].count
        var placeholdersToReplace: [Position] = []

        // Collect positions of placeholders across all columns
        for column in 0..<columns {
            for row in 0..<rows {
                if grid[row][column].isPlaceholder {
                    placeholdersToReplace.append(Position(row: row, column: column))
                } else {
                    break
                }
            }
        }

        let numberOfNewTiles = placeholdersToReplace.count

        if numberOfNewTiles > 0 {
            // Generate the new tiles using the provided generateTiles function
            let newTiles = tileGenerator.generateTiles(
                positions: placeholdersToReplace,
                word: word,
                points: points,
                level: level,
                shortWordStreak: shortWordStreak
            )

            // Assign the new tiles starting above the grid
            for i in 0..<newTiles.count {
                let positionAboveGrid = Position(row: -numberOfNewTiles + i, column: placeholdersToReplace[i].column)
                var newTile = newTiles[i]
                newTile.position = positionAboveGrid // Start above the grid
                grid[placeholdersToReplace[i].row][placeholdersToReplace[i].column] = newTile
            }

            // Animate new tiles falling down to their correct positions
            for i in 0..<numberOfNewTiles {
                let targetPosition = placeholdersToReplace[i]
                let startingRow = -numberOfNewTiles + i
                _ = abs(startingRow - targetPosition.row)

                // Calculate duration based on the distance (inverse, so tiles further away move faster)
                let duration = animationDuration * (Double(targetPosition.row + 1) / Double(numberOfNewTiles))

                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    withAnimation(.easeInOut(duration: duration)) {
                        self.grid[targetPosition.row][targetPosition.column].position = targetPosition
                    }
                }
            }
        }
    }




    //Function the checks the board for any fire tiles. If a fire tile is still present, move it down one row and generate a tile for the top. If a fire tile cannot move down anymore, end the game.
    func checkFireTiles() {
            let rows = grid.count
            let columns = grid[0].count

            for column in 0..<columns {
                // Find the bottom-most fire tile
                for row in stride(from: rows - 1, through: 0, by: -1) {
                    let tile = grid[row][column]
                    
                    if tile.type == .fire {
                        // If the fire tile is at the bottom row, trigger game over
                        if row == rows - 1 {
                            print("Fire tile reached the bottom. Triggering game over.")
                            gameOverHandler?() // Notify GameState about game over
                            return
                        } else {
                            // Otherwise, move the fire tile down and consume the tile below
                            moveFireTileDown(from: Position(row: row, column: column))
                            break // Only move one fire tile per column
                        }
                    }
                }
            }
        }

    func moveFireTileDown(from position: Position) {
        let belowPosition = Position(row: position.row + 1, column: position.column)

        // Get the fire tile and the tile below it
        guard var fireTile = getTile(at: position),
              let belowTile = getTile(at: belowPosition) else { return }

        // Ensure the tile below is not a fire tile
        if belowTile.type == .fire {
            return
        }

        // Move all tiles above the fire tile down by one row
        for row in stride(from: position.row - 1, through: 0, by: -1) {
            let currentTile = grid[row][position.column]
            grid[row + 1][position.column] = currentTile
            grid[row + 1][position.column].position = Position(row: row + 1, column: position.column)
        }

        // Move the fire tile down to the consumed tile's position
        fireTile.position = belowPosition
        updateTile(at: belowPosition, with: fireTile)

        // Generate a new tile at the top of the column
        let topPosition = Position(row: 0, column: position.column)
        let newTile = tileGenerator.generateTile(at: topPosition)
        updateTile(at: topPosition, with: newTile)
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
                    return rowDiff == 0 || rowDiff == 1 && (tile1.position.row - tile2.position.row == 1)
                } else {
                    // Odd column: can connect to the same row or the row below
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
    
    /**
     Given the selected tiles, evaluate the score of the word.
     */
    func getScore() -> Int {
        return wordChecker.calculateScore(for: selectedTiles, tileMultiplier: tileMultiplier)
    }
    
    /**
     Get the current word that's selected
     */
    func getWord() -> String {
        return selectedTiles.map {$0.letter}.joined()
    }
    
    /**
     Function to generate a new board with a penalty.
     */
    func scramble() {
        // Clear current grid and selected tiles
        clearSelection()
        
        // Regenerate all tiles for a fresh grid
        grid = (0..<7).map { row in
            (0..<7).map { column in
                tileGenerator.generateTile(at: Position(row: row, column: column))
            }
        }
        
        // Convert some tiles in the top rows to fire tiles
        _ = grid.count
        let columns = grid[0].count
        let fireTileCount = Int.random(in: 3...5) // Number of fire tiles to generate, you can adjust this

        // Generate fire tiles in the top 3 rows (rows 0 to 2)
        for _ in 0..<fireTileCount {
            let randomRow = Int.random(in: 0..<3) // Restrict fire tiles to rows 0, 1, and 2
            let randomColumn = Int.random(in: 0..<columns)

            var tile = grid[randomRow][randomColumn]
            tile.type = .fire // Convert to fire tile
            grid[randomRow][randomColumn] = tile
        }

        // Notify that the grid has changed (optional)
        objectWillChange.send()
    }
    
    
}

