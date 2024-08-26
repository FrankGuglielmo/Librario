//
//  GameGridView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import SwiftUI

struct GameGridView: View {
    @ObservedObject var tileManager: TileManager

    var body: some View {
        GeometryReader { geometry in
            let columns = 7
            let spacing: CGFloat = 1
            let totalSpacing = spacing * CGFloat(columns - 1)
            let availableWidth = geometry.size.width - totalSpacing
            let tileSize = availableWidth / CGFloat(columns)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    VStack(spacing: spacing) {
                        ForEach(0..<tileManager.grid.count, id: \.self) { rowIndex in
                            TileView(tile: tileManager.grid[rowIndex][columnIndex], tileSize: tileSize) {
                                tileManager.toggleTileSelection(at: Position(row: rowIndex, column: columnIndex))
                            }
                        }
                    }
                    .offset(y: columnIndex % 2 == 0 ? 0 : tileSize / 2)
                }
            }
        }
    }
}

