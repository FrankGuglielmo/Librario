//
//  TileTypeGenerator.swift
//  Librario
//
//  This class generates the TileType for the next tile based
//  on the player's current performance. Performance is rated
//  based on the word complexity of recent words submitted and
//  the current level. The TileTypeGenerator can only generate
//  fire, neutral, or green tiles. Gold and diamond tiles are
//  handled by the TileConverter as they modify an existing tile
//  on the board rather than adding a new one to the board
//
//  Created by Frank Guglielmo on 8/17/24.
//

import Foundation

class TileTypeGenerator {
    
    var greenTileProbability: Double = 0.0
    var fireTileProbability: Double = 0.0
    
    // Based on the most recent word submitted, generate n number of TileTypes for the Tiles to be generated
    func generateTileTypes(word: String, points: Int, level: Int, shortWordStreak: Int, tilesToGenerate:Int) -> [TileType] {
        var generatedTiles: [TileType] = []
        
        // Adjust initial probabilities based on word submission
        adjustInitialProbabilities(wordLength: word.count, points: points, level: level, shortWordStreak: shortWordStreak)
        
        var greenTileGenerated = false
        var fireTileGenerated = false
        
        for _ in 0..<tilesToGenerate {
            let nextTileType = decideNextTileType(greenTileGenerated: greenTileGenerated, fireTileGenerated: fireTileGenerated)
            generatedTiles.append(nextTileType)
            adjustProbabilitiesAfterGeneration(tileType: nextTileType, level: level)
            
            if nextTileType == .green {
                greenTileGenerated = true
            } else if nextTileType == .fire {
                fireTileGenerated = true
            }
        }
        
        // Ensure no more than 3 consecutive green or fire tiles
        return validateGeneratedTiles(tiles: generatedTiles)
    }
    
    private func adjustInitialProbabilities(wordLength: Int, points: Int, level: Int, shortWordStreak: Int) {
        // Set initial green probability based on word quality
        if wordLength >= 4 && points >= 500 {
            greenTileProbability = 1.0 // Ensure at least one green tile
        } else {
            greenTileProbability = 0.0
        }
        
        // Set initial fire probability based on short word streak and level
        fireTileProbability = calculateInitialFireTileProbability(level: level, shortWordStreak: shortWordStreak)
    }
    
    private func decideNextTileType(greenTileGenerated: Bool, fireTileGenerated: Bool) -> TileType {
        let randomValue = Double.random(in: 0...1)
        
        print("Fire tile probability: ", fireTileProbability)
        
        if !greenTileGenerated && greenTileProbability >= 1.0 {
            return .green
        } else if !fireTileGenerated && fireTileProbability >= 1.0 {
            return .fire
        } else if randomValue < greenTileProbability {
            return .green
        } else if randomValue < fireTileProbability {
            return .fire
        } else {
            return .regular
        }
    }
    
    private func adjustProbabilitiesAfterGeneration(tileType: TileType, level: Int) {
        // Reduce probabilities after each generation
        switch tileType {
        case .green:
            greenTileProbability *= 0.2 // Reduce by 80%
        case .fire:
            fireTileProbability *= 0.2
        default:
            break
        }
    }
    
    private func validateGeneratedTiles(tiles: [TileType]) -> [TileType] {
        var validTiles = tiles
        var greenCount = 0
        var fireCount = 0
        
        for i in 0..<validTiles.count {
            if validTiles[i] == .green {
                greenCount += 1
                fireCount = 0
            } else if validTiles[i] == .fire {
                fireCount += 1
                greenCount = 0
            } else {
                greenCount = 0
                fireCount = 0
            }
            
            // Ensure no more than 3 consecutive green or fire tiles
            if greenCount > 3 {
                validTiles[i] = .regular
                greenCount = 0
            } else if fireCount > 3 {
                validTiles[i] = .regular
                fireCount = 0
            }
        }
        
        return validTiles
    }
    
    private func calculateInitialFireTileProbability(level: Int, shortWordStreak: Int) -> Double {
        let baseProbability = 0.9 // Base probability for generating the first fire tile
        let levelPenalty = Double(level) * 0.02
        return min(1.0, baseProbability + levelPenalty)
    }
    
    private func fireTileReductionFactor(level: Int) -> Double {
        // Calculate the reduction factor based on the level
        print("fire tile probability reduction factor: ", 1.0 - min(0.8, 0.8 * (Double(level) / 50.0)))
        
        return 1.0 - min(0.8, 0.8 * (Double(level) / 50.0))
    }
        
}
