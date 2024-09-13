//
//  GameViewModel.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/12/24.
//

import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var tiles: [Tile] = []

    init() {
        // Initialize a 7x7 grid of tiles
        let rows = 7
        let columns = 7
        for column in 0..<columns {
            for row in 0..<rows {
                let position = Position(row: row, column: column)
                let tile = Tile(
                    letter: LetterGenerator().generateLetter(isWeighted: false),
                    type: .regular,
                    points: Int.random(in: 1...5),
                    position: position,
                    isPlaceholder: false
                )
                tiles.append(tile)
            }
        }
    }

    func removeTile(at position: Position) {
        // Remove the tile at the given position
        if let index = tiles.firstIndex(where: { $0.position == position }) {
            tiles.remove(at: index)

            // Adjust the positions of the tiles above the removed one
            for i in 0..<tiles.count {
                var tile = tiles[i]
                if tile.position.column == position.column && tile.position.row < position.row {
                    tile.position.row += 1
                    tiles[i] = tile
                }
            }
        }
    }
}
