//
//  GameGridView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import SwiftUI

struct GameGridView: View {
    @ObservedObject var tileManager: TileManager
    @EnvironmentObject var gameState: GameState

    var body: some View {
        VStack {
            GeometryReader { geometry in
                let columns = 7
                let spacing: CGFloat = 1
                let availableWidth = geometry.size.width
                let tileSize = availableWidth / CGFloat(columns)

                // Set the actual grid height based on rows
                let gridHeight = tileSize * CGFloat(tileManager.grid.count) + tileSize / 2
                
                ZStack {
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { columnIndex in
                            VStack(spacing: spacing) {
                                ForEach(0..<tileManager.grid.count, id: \.self) { rowIndex in
                                    TileView(tile: tileManager.grid[rowIndex][columnIndex], tileSize: tileSize) {
                                        tileManager.toggleTileSelection(at: Position(row: rowIndex, column: columnIndex))
                                    }
                                }
                                .offset(y: columnIndex % 2 == 0 ? 0 : tileSize / 2)
                            }
                            .padding(.bottom, tileSize / 2)
                        }
                    }
                    .background(Color(red: 0.33, green: 0.29, blue: 0.21))
                    .border(Color(red: 0.68, green: 0.47, blue: 0.29), width: 3)
                    .frame(width: availableWidth, height: gridHeight)
                    
                    // Conditionally overlay the arrows only if selected tiles are more than one
                    if tileManager.selectedTiles.count > 1 {
                        drawArrows(tileSize: tileSize)
                            .frame(width: availableWidth, height: gridHeight)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Center the entire content
        }
    }

    private func drawArrows(tileSize: CGFloat) -> some View {
        ZStack {
            ForEach(0..<(tileManager.selectedTiles.count - 1), id: \.self) { index in
                let currentTile = tileManager.selectedTiles[index]
                let nextTile = tileManager.selectedTiles[index + 1]

                let direction = calculateDirection(from: currentTile.position, to: nextTile.position)

                // Calculate the start and end points based on the direction
                let start = calculatePoint(for: currentTile.position, tileSize: tileSize, direction: direction, isStart: true)
                let end = calculatePoint(for: nextTile.position, tileSize: tileSize, direction: direction, isStart: false)

                // Position the arrow between start and end points
                let adjustedMidPoint = CGPoint(
                    x: (start.x + end.x) / 2,
                    y: (start.y + end.y) / 2
                )

                Image(direction)
                    .resizable()
                    .frame(width: tileSize / 2.5, height: tileSize / 2.5) // Adjust the size as needed
                    .position(adjustedMidPoint)
                    .zIndex(-1) // Ensure it doesn't affect the grid's height
            }
        }
    }

    private func calculatePoint(for position: Position, tileSize: CGFloat, direction: String, isStart: Bool) -> CGPoint {
        let isEvenColumn = position.column % 2 == 0
        let xOffset = isEvenColumn ? 0 : tileSize / 2
        let baseX = tileSize * CGFloat(position.column) + xOffset
        let baseY = tileSize * CGFloat(position.row)
        
        // Small adjustments
        let xAdjustment: CGFloat = -15.0 // Adjust this value as needed
        let yAdjustment: CGFloat = 18.0 // Adjust this value as needed for diagonal arrows

        if isEvenColumn {
            // Logic for even columns
            switch direction {
            case "up_arrow":
                return isStart ? CGPoint(x: baseX + tileSize / 2 + xAdjustment + 27, y: baseY + tileSize / 2 + yAdjustment)
                               : CGPoint(x: baseX + tileSize / 2 + xAdjustment, y: baseY + yAdjustment) // Adjusted start and end points for up_arrow
            case "down_arrow":
                return isStart ? CGPoint(x: baseX + tileSize / 2 + xAdjustment + 27, y: baseY + yAdjustment + 27)
                               : CGPoint(x: baseX + tileSize / 2 + xAdjustment, y: baseY + tileSize / 2) // Adjusted start and end points for down_arrow
            case "up_left_arrow":
                return isStart ? CGPoint(x: baseX + xAdjustment, y: baseY + yAdjustment)
                               : CGPoint(x: baseX + tileSize + xAdjustment, y: baseY + tileSize + yAdjustment) // Start from bottom right, end at top left
            case "up_right_arrow":
                return isStart ? CGPoint(x: baseX + tileSize + xAdjustment, y: baseY + yAdjustment)
                               : CGPoint(x: baseX + xAdjustment, y: baseY + tileSize + yAdjustment) // Start from bottom left, end at top right
            case "down_left_arrow":
                return isStart ? CGPoint(x: baseX + xAdjustment, y: baseY + tileSize + yAdjustment)
                               : CGPoint(x: baseX + tileSize + xAdjustment, y: baseY + yAdjustment) // Start from top right, end at bottom left
            case "down_right_arrow":
                return isStart ? CGPoint(x: baseX + tileSize + xAdjustment, y: baseY + tileSize + yAdjustment)
                               : CGPoint(x: baseX + xAdjustment, y: baseY + yAdjustment) // Start from top left, end at bottom right
            default:
                return CGPoint(x: baseX + tileSize / 2 + xAdjustment, y: baseY + tileSize / 2) // Default center point
            }
        } else {
            // Logic for odd columns
            switch direction {
            case "up_arrow":
                return isStart ? CGPoint(x: baseX + xAdjustment - 15, y: baseY + yAdjustment + tileSize + 50)
                               : CGPoint(x: baseX + tileSize / 2, y: baseY) // Adjusted start and end points for up_arrow
            case "down_arrow":
                return isStart ? CGPoint(x: baseX + xAdjustment, y: baseY + tileSize + yAdjustment + 27)
                               : CGPoint(x: baseX + tileSize / 2 + xAdjustment, y: baseY + tileSize / 2) // Adjusted start and end points for down_arrow
            case "up_left_arrow":
                return isStart ? CGPoint(x: baseX + xAdjustment, y: baseY + yAdjustment)
                               : CGPoint(x: baseX + tileSize + xAdjustment, y: baseY + tileSize + yAdjustment) // Start from bottom right, end at top left
            case "up_right_arrow":
                return isStart ? CGPoint(x: baseX + tileSize + xAdjustment, y: baseY + yAdjustment)
                               : CGPoint(x: baseX + xAdjustment, y: baseY + tileSize + yAdjustment) // Start from bottom left, end at top right
            case "down_left_arrow":
                return isStart ? CGPoint(x: baseX + xAdjustment, y: baseY + tileSize + yAdjustment)
                               : CGPoint(x: baseX + tileSize + xAdjustment, y: baseY + yAdjustment) // Start from top right, end at bottom left
            case "down_right_arrow":
                return isStart ? CGPoint(x: baseX + tileSize + xAdjustment, y: baseY + tileSize + yAdjustment)
                               : CGPoint(x: baseX + xAdjustment, y: baseY + yAdjustment) // Start from top left, end at bottom right
            default:
                return CGPoint(x: baseX + tileSize / 2 + xAdjustment, y: baseY + tileSize / 2) // Default center point
            }
        }
    }


    private func calculateDirection(from: Position, to: Position) -> String {
        let dx = to.column - from.column
        let dy = to.row - from.row
        
        if from.column % 2 == 0 {
            // Even column
            if dx == 0 && dy < 0 {
                return "up_arrow"
            } else if dx == 0 && dy > 0 {
                return "down_arrow"
            } else if dx < 0 && dy == 0 {
                return "down_left_arrow"
            } else if dx > 0 && dy == 0 {
                return "down_right_arrow"
            } else if dx < 0 && dy < 0 {
                return "up_left_arrow"
            } else if dx > 0 && dy < 0 {
                return "up_right_arrow"
            }
        } else {
            // Odd column
            if dx == 0 && dy < 0 {
                return "up_arrow"
            } else if dx == 0 && dy > 0 {
                return "down_arrow"
            } else if dx < 0 && dy == 0 {
                return "up_left_arrow"
            } else if dx > 0 && dy == 0 {
                return "up_right_arrow"
            } else if dx < 0 && dy > 0 {
                return "down_left_arrow"
            } else if dx > 0 && dy > 0 {
                return "down_right_arrow"
            }
        }

        return "up_arrow" // Default case
    }
}

#Preview {
    GameGridView(tileManager: TileManager(tileGenerator: TileGenerator(letterGenerator: LetterGenerator(), tileTypeGenerator: TileTypeGenerator()), tileConverter: TileConverter(), wordChecker: WordChecker(wordStore: [:])))
}
