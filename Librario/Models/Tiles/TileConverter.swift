//
//  TileConverter.swift
//  Librario
//
//  This class converts a given tile on the board to a specified TileType
//  and "isSelected" variant
//
//  Created by Frank Guglielmo on 8/18/24.
//

import Foundation

class TileConverter {
    
    // If the previous word submitted is worth upgrading, decide the upgrade type. if unable to upgrade, return a regular tile.
    func decideUpgradeType(word:String, pointValue:Int) -> TileType {
        if word.count >= 6 && pointValue >= 2000 {
            return TileType.diamond
        } else if word.count >= 5 && pointValue >= 1000 {
            return TileType.gold
        } else{
            return TileType.regular
        }
    }
    
    //Randomly select a tile from the board for upgrade
    func selectTileIndexFromBoard(grid: [[Tile]]) -> (row: Int, column: Int)? {
        // Flatten the 2D grid into a 1D array with indices
        let flattenedGrid = grid.enumerated().flatMap { row, tiles in
            tiles.enumerated().map { column, tile in
                return (row: row, column: column, tile: tile)
            }
        }
        
        // Filter out tiles that are already gold, diamond, or green
        let availableTiles = flattenedGrid.filter {
            $0.tile.type != .gold && $0.tile.type != .diamond && $0.tile.type != .green
        }
        
        // Guard against an empty grid or no available tiles
        guard let selectedTile = availableTiles.randomElement() else {
            return nil
        }
        
        // Return the selected tile's row and column indices
        return (row: selectedTile.row, column: selectedTile.column)
    }

    
    // Function to change a given tile to a specfic TileType
    func upgradeTile(tile: inout Tile, type:TileType){
        tile.type = type
    }
    
    func upgradeRandomTile(word:String, pointValue:Int, grid: inout [[Tile]]){
        // Determine the upgrade type based on the word and point value
        let upgradeType = decideUpgradeType(word: word, pointValue: pointValue)
        print("word: ", word, ", points: ", pointValue)
        
        // If the upgrade type is regular, no upgrade is needed
        if upgradeType == .regular {
            print("No upgrade needed.")
            return
        }
        
        // Attempt to select a tile from the board for upgrading
        guard let selectedTileIndex = selectTileIndexFromBoard(grid: grid) else {
            print("No suitable tile found for upgrade.")
            return
        }
        
        // Upgrade the selected tile to the determined upgrade type
        upgradeTile(tile: &grid[selectedTileIndex.row][selectedTileIndex.column], type: upgradeType)
        print("Upgraded tile at row \(selectedTileIndex.row), column \(selectedTileIndex.column) to \(upgradeType).")
    }
    
    func selectTile(_ tile: Tile) -> Tile {
        var updatedTile = tile
        updatedTile.select()
        return updatedTile
    }

    func deselectTile(_ tile: Tile) -> Tile {
        var updatedTile = tile
        updatedTile.deselect()
        return updatedTile
    }
    
}
