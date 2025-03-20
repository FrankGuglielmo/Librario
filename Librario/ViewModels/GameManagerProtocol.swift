//
//  GameManagerProtocol.swift
//  Librario
//
//  Created on 3/19/25.
//

import Foundation
import SwiftUI

protocol GameManagerProtocol: AnyObject, Observable, Codable {
    // Core game state properties
    var gameState: GameState { get set }
    var levelData: LevelStatistics { get set }
    var sessionData: SessionStatistics { get set }
    var tileManager: TileManager { get set }
    var gameOver: Bool { get set }
    var isInGameView: Bool { get set }
    var gameplayState: GameManager.GameplayState { get set }
    
    // Timer-related properties
    var currentGameTime: TimeInterval { get }
    
    // MARK: - Game Management Methods
    func startNewGame(userStatistics: UserStatistics)
    func saveGame()
    func updateUserStatistics(_ userStatistics: UserStatistics)
    func submitWord()
    func checkLevelProgression() -> Bool
    func handleLevelCompletion()
    func handleSessionCompletion(userStatistics: UserStatistics)
    func resetLevelStatistics()
    func completeLevel()
    
    // MARK: - Timer Methods
    func startGameTimer()
    func pauseGameTimer()
    func resumeGameTimer()
    func stopGameTimer()
    func updateStatisticsWithGameTime()
    
    // MARK: - Extra Life Methods
    func canUseExtraLife() -> Bool
    func useExtraLifeAndContinue() -> Bool
    func getExtraLivesUsedInSession() -> Int
    func getMaxExtraLivesPerSession() -> Int
    func getExtraLifeTimerProgress() -> Double
    func startExtraLifeTimer()
    func stopExtraLifeTimer()
    func showExtraLifePopupIfAvailable(firePosition: Position) -> Bool
    func proceedWithGameOver()
    func handleGameOver()
    
    // MARK: - Inventory Methods
    func getCoins() -> Int
    func getDiamonds() -> Int
    func getPowerupCount(_ type: PowerupType) -> Int
    func usePowerup(_ type: PowerupType) -> Bool
    func useExtraLifePowerup() -> Bool
    func useSwapPowerup() -> Bool
    func useWildcardPowerup() -> Bool
    
    // MARK: - Wildcard Mode Methods
    func enterWildcardMode() -> Bool
    func exitWildcardMode()
    func selectTileForWildcard(at position: Position) -> Bool
    func selectWildcardLetter(letter: String) -> Bool
    func confirmWildcardChange()
    func changeTileLetter(at position: Position, to letter: String)
    
    // MARK: - Swap Mode Methods
    func enterSwapMode() -> Bool
    func exitSwapMode()
    func selectTileForSwap(at position: Position) -> Bool
    func getAdjacentTiles(to position: Position) -> [Position]
    func canSwapTiles(from: Position, to: Position) -> Bool
    func swapTiles(from: Position, to: Position)
    func confirmSwap(from: Position, to: Position)
    
    // MARK: - Fire Tile Methods
    func hasFireTile() -> Bool
    func handleFireTile()
    func changeSprite(to sprite: String, for duration: TimeInterval)
    
    // MARK: - Game Lifecycle Management
    func updateUserLifetimeStatistics(userData: UserData?)
}

// Extension to provide default implementations for backward compatibility methods
extension GameManagerProtocol {
    func startLevelTimer() {
        startGameTimer()
    }
    
    func pauseLevelTimer() {
        pauseGameTimer()
    }
    
    func resumeLevelTimer() {
        resumeGameTimer()
    }
    
    func stopLevelTimer() {
        stopGameTimer()
    }
}
