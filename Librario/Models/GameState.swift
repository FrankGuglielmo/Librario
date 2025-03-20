//
//  GameState.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import Foundation
import Observation

@Observable class GameState: Codable {
    var score: Int = 0
    var level: Int = 1
    var gameMode: GameMode = .classic
    
    enum GameMode: String, Codable {
        case classic
        case arcade
    }
    
    private enum CodingKeys: String, CodingKey {
        case score, level, gameMode
    }
    
    init() {}

    // Codable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Int.self, forKey: .score)
        level = try container.decode(Int.self, forKey: .level)
        gameMode = try container.decodeIfPresent(GameMode.self, forKey: .gameMode) ?? .classic
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(score, forKey: .score)
        try container.encode(level, forKey: .level)
        try container.encode(gameMode, forKey: .gameMode)
    }

    // Reset the state for a new game
    func reset() {
        score = 0
        level = 1
    }

    // MARK: - Persistence Methods

    func saveGameState() {
        let filename = gameMode == .classic ? "gameState.json" : "arcadeGameState.json"
        let fileURL = GameState.getDocumentsDirectory().appendingPathComponent(filename)
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: fileURL)
            print("\(gameMode) game state saved successfully.")
        } catch {
            print("Failed to save \(gameMode) game state: \(error)")
        }
    }

    static func loadGameState(gameMode: GameMode = .classic) -> GameState? {
        let filename = gameMode == .classic ? "gameState.json" : "arcadeGameState.json"
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            // The file doesn't exist, this is expected for first run
            print("GameState file not found. Creating a new GameState.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let gameState = try JSONDecoder().decode(GameState.self, from: data)
            return gameState
        } catch {
            print("Failed to load game state: \(error)")
            return nil
        }
    }


    // Helper function to get the documents directory
    static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
