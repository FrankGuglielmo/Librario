//
//  Tile.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import Foundation

struct Tile: Identifiable, Codable, Hashable {
    
    var id = UUID()
    
    //The letter of the tile
    var letter: String
    
    //The type of the tile
    var type: TileType
    
    //Whether the tile has been selected by the user, default is unselected
    var isSelected: Bool = false
    
    var points: Int
    
    var isMarkedForRemoval:Bool = false
    
    // Position of the tile in the grid
    var position: Position
    
    var isPlaceholder: Bool
    
    // Computed property to get the image name based on the tile's state
    var imageName: String {
        let baseName = "\(type.rawValue)-tile-\(letter)"
        return isSelected ? "highlighted-\(baseName)" : baseName
    }
    
    //Computed property to represent the look of the tile
    var image: String {
        return imageName
    }
    
    mutating func select() {
        isSelected = true
    }

    mutating func deselect() {
        isSelected = false
    }
    
    static func placeholder(at position: Position) -> Tile {
        return Tile(letter: "", type: .regular, points: 0, position: position, isPlaceholder: true)
    }
    
    // Conform to Hashable
        static func == (lhs: Tile, rhs: Tile) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    
}

struct Position: Codable, Equatable {
    var row: Int
    var column: Int
}


//An enumerator for all the different types of tiles
enum TileType: String, Codable {
    case regular = "regular"
    case green = "green"
    case gold = "gold"
    case diamond = "diamond"
    case fire = "red"
}
