//
//  GameGridView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import SwiftUI

struct GameGridView: View {
    @ObservedObject var gameManager: GameManager
    @ObservedObject var tileManager: TileManager
    @State private var selectedDuringDrag: Set<Position> = []
    @Namespace private var tileNamespace

    var body: some View {
        GeometryReader { geometry in
            let columns = 7
            let rows = 7
            let tileSize = geometry.size.width / CGFloat(columns)
            let gridWidth = geometry.size.width
            let gridHeight = calculateGridHeight(for: tileManager.grid, tileSize: tileSize)

            ZStack {
                // Display tiles
                ForEach(tileManager.grid.flatMap { $0 }) { tile in
                    TileView(tile: tile, tileSize: tileSize) {
                        tileManager.toggleTileSelection(at: tile.position)
                    }
    
                    .position(
                        x: xPosition(for: tile, tileSize: tileSize),
                        y: yPosition(for: tile, tileSize: tileSize)
                    )
                    .matchedGeometryEffect(id: tile.id, in: tileNamespace)
                }

                // Draw arrows between selected tiles
                if tileManager.selectedTiles.count > 1 {
                    drawArrows(tileSize: tileSize)
                }
            }
            .frame(width: gridWidth, height: gridHeight)
            .background(Color(red: 0.33, green: 0.29, blue: 0.21))
            .border(Color(red: 0.68, green: 0.47, blue: 0.29), width: 3)
            .gesture(dragGesture(tileSize: tileSize, columns: columns, rows: rows))
        }
        .frame(height: calculateGridHeight(for: tileManager.grid, tileSize: UIScreen.main.bounds.width / 7))
    }

    // MARK: - Helper Functions

    private func xPosition(for tile: Tile, tileSize: CGFloat) -> CGFloat {
        return CGFloat(tile.position.column) * tileSize + tileSize / 2
    }

    private func yPosition(for tile: Tile, tileSize: CGFloat) -> CGFloat {
        var y = CGFloat(tile.position.row) * tileSize + tileSize / 2
        if tile.position.column % 2 == 1 {
            y += tileSize / 2
        }
        return y
    }

    private func calculateGridHeight(for grid: [[Tile]], tileSize: CGFloat) -> CGFloat {
        let numberOfRows = CGFloat(grid.count)
        return numberOfRows * tileSize + tileSize / 2
    }

    private func dragGesture(tileSize: CGFloat, columns: Int, rows: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = value.location
                if let position = positionFrom(location: location, tileSize: tileSize, columns: columns, rows: rows) {
                    if !selectedDuringDrag.contains(position) {
                        selectedDuringDrag.insert(position)
                        tileManager.toggleTileSelection(at: position)
                    }
                }
            }
            .onEnded { _ in
                selectedDuringDrag.removeAll()
            }
    }

    private func positionFrom(location: CGPoint, tileSize: CGFloat, columns: Int, rows: Int) -> Position? {
        let columnIndex = Int(location.x / tileSize)
        guard columnIndex >= 0 && columnIndex < columns else { return nil }

        let columnOffsetY = columnIndex % 2 == 0 ? 0 : tileSize / 2
        let adjustedY = location.y - columnOffsetY

        let rowIndex = Int(adjustedY / tileSize)
        guard rowIndex >= 0 && rowIndex < rows else { return nil }

        return Position(row: rowIndex, column: columnIndex)
    }

    // Include your existing drawArrows function here...


    private func drawArrows(tileSize: CGFloat) -> some View {
        let selectedTiles = tileManager.selectedTiles

        return Group {
            if selectedTiles.count > 1 {
                // Create pairs of tiles using zip
                let tilePairs = zip(selectedTiles, selectedTiles.dropFirst())

                ZStack {
                    ForEach(Array(tilePairs.enumerated()), id: \.offset) { (index, pair) in
                        let (currentTile, nextTile) = pair
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
                            .frame(width: tileSize / 2.5, height: tileSize / 2.5)
                            .position(adjustedMidPoint)
                            .zIndex(-1)
                    }
                }
            } else {
                EmptyView()
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

//#Preview {
//    let performanceEvaluator = PerformanceEvaluator()
//    
//    let letterGenerator = LetterGenerator(performanceEvaluator: performanceEvaluator)
//    let tileTypeGenerator = TileTypeGenerator(performanceEvaluator: performanceEvaluator)
//    let tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator, performanceEvaluator: performanceEvaluator)
//    
//    let tileConverter = TileConverter()
//    let wordChecker = WordChecker(wordStore: [:]) // Assuming the wordStore is empty for the preview
//    
//    let tileManager = TileManager(tileGenerator: tileGenerator, tileConverter: tileConverter, wordChecker: wordChecker, performanceEvaluator: performanceEvaluator)
//    
//    let gameManager = GameManager(dictionaryManager: DictionaryManager())
//    
//    return GameGridView(gameManager: gameManager, tileManager: tileManager)
//}
