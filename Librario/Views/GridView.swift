//
//  GridView.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/12/24.
//

// GridView.swift

import SwiftUI

struct GridView: View {
    @ObservedObject var viewModel: GameViewModel
    @Namespace var namespace

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let tileSize = width / CGFloat(7)
            ZStack {
                ForEach(viewModel.tiles) { tile in
                    TileView(tile: tile, tileSize: tileSize) {
                        withAnimation(.easeInOut) {
                            viewModel.removeTile(at: tile.position)
                        }
                    }
                    .position(
                        x: xPosition(for: tile, tileSize: tileSize),
                        y: yPosition(for: tile, tileSize: tileSize)
                    )
                    .matchedGeometryEffect(id: tile.id, in: namespace)
                }
            }
            .frame(width: width, height: geometry.size.height)
        }
    }

    // Calculate x position based on the column
    func xPosition(for tile: Tile, tileSize: CGFloat) -> CGFloat {
        return CGFloat(tile.position.column) * tileSize + tileSize / 2
    }

    // Calculate y position based on the row and apply offset to every other column
    func yPosition(for tile: Tile, tileSize: CGFloat) -> CGFloat {
        var y = CGFloat(tile.position.row) * tileSize + tileSize / 2
        if tile.position.column % 2 == 1 {
            y += tileSize / 2
        }
        return y
    }
}



#Preview {
    GridView(viewModel: GameViewModel())
}
