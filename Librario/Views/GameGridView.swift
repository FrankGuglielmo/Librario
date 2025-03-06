//
//  GameGridView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import SwiftUI

struct GameGridView: View {
    @Bindable var gameManager: GameManager
    @ObservedObject var tileManager: TileManager
    @State private var selectedDuringDrag: Set<Position> = []
    @State private var tilePositionCache: [Position: CGRect] = [:]
    @State private var arrowPositionCache: [String: (CGPoint, CGPoint)] = [:]
    @State private var lastDragLocation: CGPoint?
    @State private var dragVelocity: CGVector = .zero
    @State private var lastUpdateTime: Date = Date()
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
            .onAppear {
                buildPositionCache(tileSize: tileSize, columns: columns, rows: rows)
                cacheArrowPositions(tileSize: tileSize)
            }
            .onChange(of: geometry.size) { _, newSize in
                let newTileSize = newSize.width / CGFloat(columns)
                buildPositionCache(tileSize: newTileSize, columns: columns, rows: rows)
                cacheArrowPositions(tileSize: newTileSize)
            }
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

    // Build a cache of tile positions for faster hit testing
    private func buildPositionCache(tileSize: CGFloat, columns: Int, rows: Int) {
        tilePositionCache.removeAll()
        
        for row in 0..<rows {
            for column in 0..<columns {
                let position = Position(row: row, column: column)
                let isEvenColumn = column % 2 == 0
                let yOffset = isEvenColumn ? 0 : tileSize / 2
                
                let x = CGFloat(column) * tileSize
                let y = CGFloat(row) * tileSize + yOffset
                
                tilePositionCache[position] = CGRect(
                    x: x,
                    y: y,
                    width: tileSize,
                    height: tileSize
                )
            }
        }
    }
    
    // Optimized drag gesture with velocity tracking and predictive selection
    private func dragGesture(tileSize: CGFloat, columns: Int, rows: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = value.location
                updateDragVelocity(currentLocation: location)
                
                if let position = positionFrom(location: location, tileSize: tileSize, columns: columns, rows: rows) {
                    if !selectedDuringDrag.contains(position) {
                        selectedDuringDrag.insert(position)
                        
                        // Use a more efficient selection method
                        if let tile = tileManager.getTile(at: position), !tile.isSelected {
                            // Directly select the tile instead of toggling
                            DispatchQueue.main.async {
                                self.tileManager.selectTile(at: position)
                            }
                            
                            // Try to predict and pre-select the next tile
                            if let nextPosition = predictNextPosition(from: position),
                               !selectedDuringDrag.contains(nextPosition),
                               let nextTile = tileManager.getTile(at: nextPosition),
                               !nextTile.isSelected,
                               tileManager.canSelect(nextTile) {
                                // Don't actually select yet, but prepare for faster selection
                                // This is handled by the canSelect method in TileManager
                            }
                        }
                    }
                }
            }
            .onEnded { _ in
                selectedDuringDrag.removeAll()
                lastDragLocation = nil
                dragVelocity = .zero
            }
    }
    
    // Track drag velocity for predictive selection
    private func updateDragVelocity(currentLocation: CGPoint) {
        guard let lastLocation = lastDragLocation else {
            lastDragLocation = currentLocation
            lastUpdateTime = Date()
            return
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastUpdateTime)
        if timeInterval > 0 {
            let dx = currentLocation.x - lastLocation.x
            let dy = currentLocation.y - lastLocation.y
            
            // Calculate velocity (points per second)
            dragVelocity = CGVector(
                dx: dx / CGFloat(timeInterval),
                dy: dy / CGFloat(timeInterval)
            )
            
            lastDragLocation = currentLocation
            lastUpdateTime = now
        }
    }
    
    // Predict the next position based on drag velocity
    private func predictNextPosition(from currentPosition: Position) -> Position? {
        // Use velocity to predict the next tile the user is likely to select
        guard abs(dragVelocity.dx) > 50 || abs(dragVelocity.dy) > 50 else {
            return nil // Not moving fast enough for prediction
        }
        
        // Determine primary direction of movement
        let angle = atan2(dragVelocity.dy, dragVelocity.dx)
        
        // Convert angle to direction based on hexagonal grid layout
        let isEvenColumn = currentPosition.column % 2 == 0
        
        // Predict next position based on direction and current column parity
        if angle > -0.4 && angle < 0.4 {
            // Moving right
            return Position(row: currentPosition.row, column: currentPosition.column + 1)
        } else if angle > 0.4 && angle < 1.2 {
            // Moving down-right
            if isEvenColumn {
                return Position(row: currentPosition.row + 1, column: currentPosition.column + 1)
            } else {
                return Position(row: currentPosition.row, column: currentPosition.column + 1)
            }
        } else if angle > 1.2 && angle < 2.0 {
            // Moving down
            return Position(row: currentPosition.row + 1, column: currentPosition.column)
        } else if angle > 2.0 && angle < 2.8 {
            // Moving down-left
            if isEvenColumn {
                return Position(row: currentPosition.row + 1, column: currentPosition.column - 1)
            } else {
                return Position(row: currentPosition.row, column: currentPosition.column - 1)
            }
        } else if (angle > 2.8 && angle <= 3.14) || (angle < -2.8 && angle >= -3.14) {
            // Moving left
            return Position(row: currentPosition.row, column: currentPosition.column - 1)
        } else if angle > -2.8 && angle < -2.0 {
            // Moving up-left
            if isEvenColumn {
                return Position(row: currentPosition.row, column: currentPosition.column - 1)
            } else {
                return Position(row: currentPosition.row - 1, column: currentPosition.column - 1)
            }
        } else if angle > -2.0 && angle < -1.2 {
            // Moving up
            return Position(row: currentPosition.row - 1, column: currentPosition.column)
        } else if angle > -1.2 && angle < -0.4 {
            // Moving up-right
            if isEvenColumn {
                return Position(row: currentPosition.row, column: currentPosition.column + 1)
            } else {
                return Position(row: currentPosition.row - 1, column: currentPosition.column + 1)
            }
        }
        
        return nil
    }
    
    // Optimized position lookup using the position cache
    private func positionFrom(location: CGPoint, tileSize: CGFloat, columns: Int, rows: Int) -> Position? {
        // Fast path: use cached positions for lookup
        for (position, rect) in tilePositionCache {
            if rect.contains(location) {
                return position
            }
        }
        
        // Fallback to calculation if cache fails
        let columnIndex = Int(location.x / tileSize)
        guard columnIndex >= 0 && columnIndex < columns else { return nil }

        let columnOffsetY = columnIndex % 2 == 0 ? 0 : tileSize / 2
        let adjustedY = location.y - columnOffsetY

        let rowIndex = Int(adjustedY / tileSize)
        guard rowIndex >= 0 && rowIndex < rows else { return nil }

        return Position(row: rowIndex, column: columnIndex)
    }

    // Include your existing drawArrows function here...


    // Cache arrow positions for faster rendering
    private func cacheArrowPositions(tileSize: CGFloat) {
        arrowPositionCache.removeAll()
        
        // Pre-calculate all possible arrow positions for the current grid
        for row1 in 0..<7 {
            for col1 in 0..<7 {
                let pos1 = Position(row: row1, column: col1)
                
                // Calculate potential adjacent positions
                let adjacentPositions = getAdjacentPositions(for: pos1)
                
                for pos2 in adjacentPositions {
                    let direction = calculateDirection(from: pos1, to: pos2)
                    let key = "\(pos1.row),\(pos1.column)-\(pos2.row),\(pos2.column)"
                    
                    let start = calculatePoint(for: pos1, tileSize: tileSize, direction: direction, isStart: true)
                    let end = calculatePoint(for: pos2, tileSize: tileSize, direction: direction, isStart: false)
                    
                    arrowPositionCache[key] = (start, end)
                }
            }
        }
    }
    
    // Get all adjacent positions for a given position
    private func getAdjacentPositions(for position: Position) -> [Position] {
        let isEvenColumn = position.column % 2 == 0
        var adjacentPositions: [Position] = []
        
        // Same column
        adjacentPositions.append(Position(row: position.row - 1, column: position.column)) // Up
        adjacentPositions.append(Position(row: position.row + 1, column: position.column)) // Down
        
        // Adjacent columns
        if isEvenColumn {
            // Even column
            adjacentPositions.append(Position(row: position.row, column: position.column - 1)) // Left
            adjacentPositions.append(Position(row: position.row, column: position.column + 1)) // Right
            adjacentPositions.append(Position(row: position.row - 1, column: position.column - 1)) // Up-Left
            adjacentPositions.append(Position(row: position.row - 1, column: position.column + 1)) // Up-Right
        } else {
            // Odd column
            adjacentPositions.append(Position(row: position.row, column: position.column - 1)) // Left
            adjacentPositions.append(Position(row: position.row, column: position.column + 1)) // Right
            adjacentPositions.append(Position(row: position.row + 1, column: position.column - 1)) // Down-Left
            adjacentPositions.append(Position(row: position.row + 1, column: position.column + 1)) // Down-Right
        }
        
        return adjacentPositions.filter { $0.row >= 0 && $0.row < 7 && $0.column >= 0 && $0.column < 7 }
    }
    
    // Optimized arrow drawing using cached positions
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
                        
                        // Use cached positions if available
                        let key = "\(currentTile.position.row),\(currentTile.position.column)-\(nextTile.position.row),\(nextTile.position.column)"
                        
                        let (start, end) = arrowPositionCache[key] ?? (
                            calculatePoint(for: currentTile.position, tileSize: tileSize, direction: direction, isStart: true),
                            calculatePoint(for: nextTile.position, tileSize: tileSize, direction: direction, isStart: false)
                        )
                        
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
