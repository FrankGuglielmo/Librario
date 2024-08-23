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
    
    var greenTileProbabilities: [Double] = []
        var fireTileProbabilities: [Double] = []
        
        // Main function to generate a set of TileTypes
        func generateTileTypes(word: String, points: Int, level: Int, shortWordStreak: Int, tilesToGenerate: Int) -> [TileType] {
            var generatedTileTypes: [TileType] = []
            
            // Adjust initial probabilities based on word submission
            adjustInitialProbabilities(wordLength: word.count, points: points, level: level, shortWordStreak: shortWordStreak, tilesToGenerate: tilesToGenerate)
            
            for i in 0..<tilesToGenerate {
                let nextTileType = decideNextTileType(greenTileProbability: greenTileProbabilities[i], fireTileProbability: fireTileProbabilities[i])
                generatedTileTypes.append(nextTileType)
            }
            
            // Ensure no more than 3 consecutive green or fire tiles
            return generatedTileTypes
        }
        
        // Adjust probabilities for green and fire tiles based on initial game state
        private func adjustInitialProbabilities(wordLength: Int, points: Int, level: Int, shortWordStreak: Int, tilesToGenerate: Int) {
            // Set green tile probabilities dynamically based on level and conditions
            greenTileProbabilities = calculateGreenTileProbabilities(wordLength: wordLength, points: points, level: level, tileCount: tilesToGenerate)
            
            // Set fire tile probabilities based on short word streak and level
            fireTileProbabilities = calculateFireTileProbabilities(level: level, shortWordStreak: shortWordStreak, tileCount: tilesToGenerate)
        }
        
        // Decide which TileType should be generated based on the given probabilities
        private func decideNextTileType(greenTileProbability: Double, fireTileProbability: Double) -> TileType {
            let randomValue = Double.random(in: 0...1)
            
            if randomValue < greenTileProbability {
                return .green
            } else if randomValue < fireTileProbability {
                return .fire
            } else {
                return .regular
            }
        }
        
        // Calculate dynamic fire tile probabilities based on level and shortWordStreak
        private func calculateFireTileProbabilities(level: Int, shortWordStreak: Int, tileCount: Int) -> [Double] {
            let baseProbability = min(Double(level) / 100.0, 0.5)
            let streakAdjustment = 1 + pow(Double(shortWordStreak) / 2.0, log(Double(level) + 1))
            let totalProbability = baseProbability * streakAdjustment
            
            return distributeProbabilities(totalProbability: totalProbability, tileCount: tileCount)
        }
        
        // Calculate dynamic green tile probabilities based on word properties and level
        private func calculateGreenTileProbabilities(wordLength: Int, points: Int, level: Int, tileCount: Int) -> [Double] {
            var baseProbability: Double = 0.0
            
            if wordLength >= 4 && points >= 500 {
                baseProbability = 1.0 // Ensure at least one green tile
            }
            
            // Dynamic adjustment based on level
            let levelAdjustment = 1 + pow(Double(level) / 50.0, 2.0)
            let totalProbability = baseProbability * levelAdjustment
            
            return distributeProbabilities(totalProbability: totalProbability, tileCount: tileCount)
        }
        
        // Helper function to distribute probabilities across tiles
        private func distributeProbabilities(totalProbability: Double, tileCount: Int) -> [Double] {
            var probabilities: [Double] = []
            var remainingProbability = totalProbability
            
            for _ in 0..<tileCount {
                let tileProbability = min(remainingProbability, 1.0)
                probabilities.append(tileProbability)
                remainingProbability -= tileProbability
                
                if remainingProbability <= 0 {
                    break
                }
            }
            
            while probabilities.count < tileCount {
                probabilities.append(0)
            }
            
            return probabilities
        }
    }

