//
//  TileTypeGeneratorTests.swift
//  LibrarioTests
//
//  Created by Frank Guglielmo on 8/23/24.
//

import Foundation
import XCTest
@testable import Librario

final class TileTypeGeneratorTests: XCTestCase {
    
    var generator: TileTypeGenerator!

    override func setUp() {
        super.setUp()
        generator = TileTypeGenerator()
    }

    override func tearDown() {
        generator = nil
        super.tearDown()
    }

    func testGreenTileGenerationWithHighScoreAndLongWord() {
        let tiles = generator.generateTileTypes(word: "swift", points: 600, level: 10, shortWordStreak: 1, tilesToGenerate: 5)
        XCTAssertEqual(tiles.first, .green, "Expected the first tile to be green when word length >= 4 and points >= 500.")
    }

    func testNoGreenTileForShortWordAndLowScore() {
        let tiles = generator.generateTileTypes(word: "cat", points: 300, level: 10, shortWordStreak: 1, tilesToGenerate: 5)
        XCTAssertNotEqual(tiles.first, .green, "Expected no green tile for short word with low score.")
    }

    func testFireTileGenerationAtHighLevelAndHighStreak() {
        let tiles = generator.generateTileTypes(word: "swift", points: 400, level: 60, shortWordStreak: 10, tilesToGenerate: 5)
        XCTAssertTrue(tiles.contains(.fire), "Expected at least one fire tile at high level with high short word streak.")
    }

    func testNoFireTileGenerationAtLowLevelAndLowStreak() {
        let tiles = generator.generateTileTypes(word: "swift", points: 400, level: 10, shortWordStreak: 1, tilesToGenerate: 5)
        XCTAssertFalse(tiles.contains(.fire), "Expected no fire tile at low level and low short word streak.")
    }

    func testTileDistributionWithEqualChances() {
        let tiles = generator.generateTileTypes(word: "game", points: 500, level: 30, shortWordStreak: 5, tilesToGenerate: 10)
        XCTAssertEqual(tiles.count, 10, "Expected to generate exactly 10 tiles.")
    }

    func testLowProbabilityScenarios() {
        let tiles = generator.generateTileTypes(word: "cat", points: 200, level: 1, shortWordStreak: 1, tilesToGenerate: 5)
        XCTAssertTrue(tiles.allSatisfy { $0 == .regular }, "Expected only regular tiles in low probability scenarios.")
    }

    func testEdgeCaseForExactTileGeneration() {
        let tiles = generator.generateTileTypes(word: "swift", points: 600, level: 100, shortWordStreak: 20, tilesToGenerate: 1)
        XCTAssertEqual(tiles.count, 1, "Expected exactly 1 tile to be generated.")
    }

    func testExactProbabilityDistribution() {
        let tiles = generator.generateTileTypes(word: "swift", points: 600, level: 50, shortWordStreak: 2, tilesToGenerate: 3)
        XCTAssertEqual(tiles.count, 3, "Expected exactly 3 tiles to be generated.")
    }
    
    // Helper function to check max consecutive tiles
    private func maxConsecutiveTiles(of type: TileType, in tiles: [TileType]) -> Int {
        var maxCount = 0
        var currentCount = 0
        
        for tile in tiles {
            if tile == type {
                currentCount += 1
                maxCount = max(maxCount, currentCount)
            } else {
                currentCount = 0
            }
        }
        
        return maxCount
    }
}

