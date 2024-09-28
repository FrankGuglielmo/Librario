//
//  TileManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import Foundation
import SwiftUI

class TileManager: ObservableObject, Codable {
    @Published var grid: [[Tile]] = [] // current grid being managed
    @Published var selectedTiles: [Tile] = []
    @Published var lastSelectedTile: Tile?
    
    private var tileGenerator: TileGenerator
    private var tileConverter: TileConverter
    private var wordChecker: WordChecker
    private var performanceEvaluator: PerformanceEvaluator

    private var tileMultiplier: [TileType:Double] = [
        TileType.fire: 1.0,
        TileType.regular: 1.0,
        TileType.green: 1.5,
        TileType.gold: 2.0,
        TileType.diamond: 3.0
    ]

    var gameOverHandler: (() -> Void)? // Closure to notify GameState when the game is over
    var fireTileChangeHandler: ((Bool) -> Void)? // Closure to notify a change in fire tile availability on the board
    let animationDuration: Double = 0.5
    var scrambleLock: Bool = false
    
    // Coding Keys
    private enum CodingKeys: String, CodingKey {
        case grid, selectedTiles, tileMultiplier, performanceEvaluator
    }

    /**
     * Initializes the `TileManager` with its dependencies and generates the initial grid.
     *
     * @param tileGenerator        The `TileGenerator` instance used to generate tiles.
     * @param tileConverter        The `TileConverter` instance used to convert tiles.
     * @param wordChecker          The `WordChecker` instance used to validate words.
     * @param performanceEvaluator The `PerformanceEvaluator` instance used to evaluate performance.
     */
    init(tileGenerator: TileGenerator, tileConverter: TileConverter, wordChecker: WordChecker, performanceEvaluator: PerformanceEvaluator) {
        self.tileGenerator = tileGenerator
        self.tileConverter = tileConverter
        self.wordChecker = wordChecker
        self.performanceEvaluator = performanceEvaluator
        generateInitialGrid()
    }

    /**
     * Decodes a new `TileManager` instance from the given decoder.
     *
     * @param decoder The decoder to read data from.
     * @throws DecodingError If decoding fails.
     */
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        grid = try container.decode([[Tile]].self, forKey: .grid)
        selectedTiles = try container.decode([Tile].self, forKey: .selectedTiles)
        tileMultiplier = try container.decode([TileType: Double].self, forKey: .tileMultiplier)
        
        // Attempt to decode performanceEvaluator; if not present, initialize a new one
        if let decodedPerformanceEvaluator = try? container.decode(PerformanceEvaluator.self, forKey: .performanceEvaluator) {
            performanceEvaluator = decodedPerformanceEvaluator
        } else {
            // Default initialization for old data without performanceEvaluator
            performanceEvaluator = PerformanceEvaluator()
        }
        // Reinitialize the non-Codable properties
        let letterGenerator = LetterGenerator(performanceEvaluator: performanceEvaluator)
        let tileTypeGenerator = TileTypeGenerator(performanceEvaluator: performanceEvaluator)
        self.tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator, performanceEvaluator: performanceEvaluator)
        self.tileConverter = TileConverter()
        self.wordChecker = WordChecker(wordStore: DictionaryManager().wordDictionary)
    }
    /**
     * Encodes this `TileManager` instance into the given encoder.
     *
     * @param encoder The encoder to write data to.
     * @throws EncodingError If encoding fails.
     */
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(grid, forKey: .grid)
        try container.encode(selectedTiles, forKey: .selectedTiles)
        try container.encode(tileMultiplier, forKey: .tileMultiplier)
        try container.encode(performanceEvaluator, forKey: .performanceEvaluator)
    }

    /**
     * Re-initializes non-Codable properties after decoding.
     *
     * @param dictionaryManager The `DictionaryManager` used to reinitialize `WordChecker`.
     */
    func reinitializeNonCodableProperties(dictionaryManager: DictionaryManager) {
        let letterGenerator = LetterGenerator(performanceEvaluator: performanceEvaluator)
        let tileTypeGenerator = TileTypeGenerator(performanceEvaluator: performanceEvaluator)
        self.tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator, performanceEvaluator: performanceEvaluator)
        self.tileConverter = TileConverter()
        self.wordChecker = WordChecker(wordStore: dictionaryManager.wordDictionary)
    }
    
    
    // MARK: - Persistence Methods
    /**
     * Saves the current state of the `TileManager` to disk.
     */
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
    
    /**
     * Loads a saved `TileManager` state from disk.
     *
     * @param dictionaryManager The `DictionaryManager` used to reinitialize `WordChecker`.
     * @return A `TileManager` instance if loading is successful; otherwise, `nil`.
     */
    static func loadTileManager(dictionaryManager: DictionaryManager) -> TileManager? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("tileManager.json")
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("TileManager file not found. Creating a new TileManager.")
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let tileManager = try JSONDecoder().decode(TileManager.self, from: data)
            tileManager.reinitializeNonCodableProperties(dictionaryManager: dictionaryManager)
            return tileManager
        } catch {
            print("Failed to load TileManager: \(error)")
            return nil
        }
    }

    /**
     * Returns the URL of the documents directory.
     *
     * @return The URL of the user's documents directory.
     */
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
     * Updates a tile at a specific position with a new tile.
     *
     * @param position The position of the tile to update.
     * @param newTile  The new `Tile` to place at the specified position.
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
     * Selects a tile at the given position, marking it as selected if valid.
     *
     * @param position The position of the tile to select.
     */
    func selectTile(at position: Position) {
        guard var tile = getTile(at: position) else { return }

        // Ensure the tile is selectable (it must be adjacent to the last selected tile if the stack is not empty)
        if let lastSelectedTile = selectedTiles.last, !isAdjacent(lastSelectedTile, to: tile) || selectedTiles.count == 16 {
            AudioManager.shared.playSoundEffect(named: "incorrect_selection")
            return
        }
        
        tile.isSelected = true  // Change to selected state
        updateTile(at: position, with: tile)  // Update the grid with the new state
        selectedTiles.append(tile)  // Push the selected tile onto the stack
        lastSelectedTile = tile
        
        // if tile is special, play special tile_click
        if validateWord() {
            AudioManager.shared.playSoundEffect(named: "valid_word_tile_click")
        } else if tile.type == TileType.regular && !selectedTiles.contains(where: { $0.type != .regular }) {
            AudioManager.shared.playSoundEffect(named: "regular_tile_click")
        } else {
            AudioManager.shared.playSoundEffect(named: "special_tile_click")
        }
    }

    /**
     * Deselects a tile at the given position and any tiles selected after it.
     *
     * @param position The position of the tile to deselect.
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
        lastSelectedTile = selectedTiles.last
    }

    private func deselectTileWithoutUpdate(tile: Tile) {
        guard var tileToDeselect = getTile(at: tile.position) else { return }
        tileToDeselect.isSelected = false
        updateTile(at: tile.position, with: tileToDeselect)
    }

    /**
     * Toggles the selection state of a tile at the given position.
     *
     * @param position The position of the tile to toggle.
     */
    func toggleTileSelection(at position: Position) {
        if let tile = getTile(at: position) {
            if tile.isSelected {
                AudioManager.shared.playSoundEffect(named: "regular_tile_click")
                deselectTile(at: position)
            } else {
                selectTile(at: position)
            }
        }
    }

    /**
     * Clears the current selection, deselecting all selected tiles.
     */
    func clearSelection() {
            for tile in selectedTiles {
                deselectTileWithoutUpdate(tile: tile)
            }
            selectedTiles.removeAll()
        }

    // MARK: - Word Submission Handling

    /**
     * Checks if the given tile is the last selected tile.
     *
     * @param tile The `Tile` to check.
     * @return `true` if the tile is the last selected; otherwise, `false`.
     */
    func isLastSelectedTile(tile: Tile) -> Bool {
        return selectedTiles.last == tile
    }
    
    /**
     * Validates whether the currently selected tiles form a valid word.
     *
     * @return `true` if the selected tiles form a valid word; otherwise, `false`.
     */
    func validateWord() -> Bool {
        if wordChecker.isWord(tiles: selectedTiles) {
            return true
        } else {
            return false
        }
    }

    /**
     * Processes the submission of a word, updating the grid and state accordingly.
     *
     * @param word   The word being submitted.
     * @param points The points awarded for the word.
     * @param level  The current game level.
     */
    func processWordSubmission(word: String, points: Int, level: Int) {
        performanceEvaluator.updatePerformance(lastWord: word, lastWordScore: points)
        // Mark tiles for removal
        selectedTiles.forEach { tile in
            if let position = findTilePosition(tile) {
                grid[position.row][position.column].isMarkedForRemoval = true
            }
        }
        // Move tiles down to fill gaps
        withAnimation(.easeOut(duration: animationDuration / 2)) {
            moveTilesDown()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2 * animationDuration) {
            withAnimation(.easeInOut(duration: self.animationDuration)) {
                self.checkFireTiles()
            }
        }
        // After the existing tiles have fallen, generate new tiles
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            withAnimation(.easeInOut(duration: self.animationDuration)) {
                self.generateNewTilesForTop(word: word, points: points, level: level)
            }
        }
        // Upgrade random tile if necessary (after new tiles are in place)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2 * animationDuration) {
            self.tileConverter.upgradeRandomTile(word: word, pointValue: points, grid: &self.grid)
        }
        // Clear the selection
        clearSelection()
    }

    /**
     * Moves tiles down to fill gaps after tile removal.
     */
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
    
    /**
     * Generates new tiles to fill the top of the grid after tiles have moved down.
     *
     * @param word   The word that was submitted.
     * @param points The points awarded for the word.
     * @param level  The current game level.
     */
    func generateNewTilesForTop(word: String, points: Int, level: Int) {
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
                for: grid
            )
            // Assign the new tiles starting above the grid
            for i in 0..<newTiles.count {
                let positionAboveGrid = Position(row: -numberOfNewTiles + i, column: placeholdersToReplace[i].column)
                var newTile = newTiles[i]
                newTile.position = positionAboveGrid // Start above the grid
                grid[placeholdersToReplace[i].row][placeholdersToReplace[i].column] = newTile
            }
            AudioManager.shared.playSoundEffect(named: "tile_drop")
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

    /**
     * Checks for fire tiles on the board and processes their movement or triggers game over.
     */
    func checkFireTiles() {
        let rows = grid.count
        let columns = grid[0].count
        var hasFireTile = false

        for column in 0..<columns {
            // Find the bottom-most fire tile
            for row in stride(from: rows - 1, through: 0, by: -1) {
                let tile = grid[row][column]
                if tile.type == .fire {
                    hasFireTile = true
                    // If the fire tile is at the bottom row, trigger game over
                    if row == rows - 1 {
                        gameOverHandler?() // Notify GameState about game over
                        return
                    } else {
                        // Otherwise, move the fire tile down
                        moveFireTileDown(from: Position(row: row, column: column))
                        break // Only move one fire tile per column
                    }
                }
            }
        }
        // Notify the handler about the fire tile state
        fireTileChangeHandler?(hasFireTile)
    }

    /**
     * Moves a fire tile down one position, consuming tiles as necessary.
     *
     * @param position The current position of the fire tile.
     */
    func moveFireTileDown(from position: Position) {
        let belowPosition = Position(row: position.row + 1, column: position.column)
        // Get the fire tile and the tile below it
        guard var fireTile = getTile(at: position),
              let belowTile = getTile(at: belowPosition) else { return }
        // Ensure the tile below is not a fire tile
        if belowTile.type == .fire {
            return
        }
        // Check the breakpoint for the tile type
        let breakpoints: [TileType: BreakPoint] = [
            .regular: BreakPoint.regular,
            .green: BreakPoint.green,
            .gold: BreakPoint.gold,
            .diamond: BreakPoint.diamond
        ]
        // Ensure the tile below can be consumed based on the breakpoint
        guard let belowTileBreakPoint = breakpoints[belowTile.type] else { return }
        // If the fire tile's burnCounter is less than the below tile's BreakPoint, increment burnCounter
        if fireTile.burnCounter < belowTileBreakPoint.rawValue {
            fireTile.burnCounter += 1
            updateTile(at: position, with: fireTile) // Update the fire tile to reflect the incremented burnCounter
            return
        }

        // If the fire tile meets the breakpoint, reset burnCounter and allow it to move
        fireTile.burnCounter = 0
        AudioManager.shared.playSoundEffect(named: "word_submit_swoosh3")

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
        let newTile = tileGenerator.generateTile(at: topPosition, for: grid)
        updateTile(at: topPosition, with: newTile)
    }



    private func shouldConvertTile(word: String, points: Int) -> Bool {
        return word.count >= 4 || points >= 1000 // Example conversion criteria
    }

    // MARK: - Tile Utility Methods

    /**
     Helper method to determine if two tiles are next to each other
     */
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

    /**
     * Retrieves the tile at a specific position, if it exists.
     *
     * @param position The position of the tile to retrieve.
     * @return The `Tile` at the specified position, or `nil` if out of bounds.
     */
    func getTile(at position: Position) -> Tile? {
        guard position.row >= 0 && position.row < grid.count &&
                position.column >= 0 && position.column < grid[0].count else {
            return nil
        }
        return grid[position.row][position.column]
    }
    
    /**
     * Calculates the score for the currently selected tiles.
     *
     * @return The total score for the selected tiles.
     */
    func getScore() -> Int {
        return wordChecker.calculateScore(for: selectedTiles, tileMultiplier: tileMultiplier)
    }
    
    /**
     * Retrieves the current word formed by the selected tiles.
     *
     * @return A `String` representing the current word.
     */
    func getWord() -> String {
        return selectedTiles.map {$0.letter}.joined()
    }
    
    /**
     * Scrambles the board, introducing a penalty by adding fire tiles.
     */
    func scramble() {
        // If the user spams the scramble lock, a lock will be applied as to not overuse the scramble button
        if scrambleLock {
            return
        }
        
        AudioManager.shared.playSoundEffect(named: "tile_drop")
        // Clear current grid and selected tiles
        clearSelection()

        // Step 1: Count existing fire tiles
        var fireTileCount = 0
        for row in grid {
            for tile in row {
                if tile.type == .fire {
                    fireTileCount += 1
                }
            }
        }

        // Step 2: Decide to add 1 to 3 fire tiles, regardless of level
        let additionalFireTilesToAdd = Int.random(in: 2...4)
        fireTileCount += additionalFireTilesToAdd
        
        // Apply the scramble lock if there are three rows worth of fire tiles
        if fireTileCount >= 21 {
            scrambleLock = true
        }
        
        

        // Regenerate all tiles for a fresh grid
        grid = (0..<7).map { row in
            (0..<7).map { column in
                tileGenerator.generateTile(at: Position(row: row, column: column), for: grid)
            }
        }

        // Step 3: Add fire tiles across the top 3 rows
        let columns = grid[0].count
        var firePositions: Set<Position> = [] // Track positions where fire tiles have been placed

        while firePositions.count < fireTileCount && firePositions.count < 3 * columns {
            let randomRow = Int.random(in: 0..<3) // Restrict fire tiles to rows 0, 1, and 2
            let randomColumn = Int.random(in: 0..<columns)
            
            let position = Position(row: randomRow, column: randomColumn)
            
            // Only add a fire tile if one hasn't been placed in that position already
            if !firePositions.contains(position) {
                firePositions.insert(position)
                var tile = grid[randomRow][randomColumn]
                tile.type = .fire // Convert to fire tile
                grid[randomRow][randomColumn] = tile
            }
        }

        fireTileChangeHandler?(true) // There will always be a fire tile after scrambling
        // Notify that the grid has changed (optional)
        objectWillChange.send()
    }


}

