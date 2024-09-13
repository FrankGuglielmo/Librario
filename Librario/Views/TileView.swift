//
//  TileView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import SwiftUI

struct TileView: View {
    let tile: Tile
    let tileSize: CGFloat
    let onTap: () -> Void

    var body: some View {
        Image(tile.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: tileSize, height: tileSize)
            .animation(.spring(), value: tile.isSelected)
    }
}

