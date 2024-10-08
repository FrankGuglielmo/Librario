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
    
    private enum CodingKeys: String, CodingKey {
        case score, level
    }
    
    init() {}

    // Codable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Int.self, forKey: .score)
        level = try container.decode(Int.self, forKey: .level)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(score, forKey: .score)
        try container.encode(level, forKey: .level)
    }

    // Reset the state for a new game
    func reset() {
        score = 0
        level = 1
    }

    // MARK: - Persistence Methods

    func saveGameState() {
        let fileURL = GameState.getDocumentsDirectory().appendingPathComponent("gameState.json")
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: fileURL)
            print("Game state saved successfully.")
        } catch {
            print("Failed to save game state: \(error)")
        }
    }

    static func loadGameState() -> GameState? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("gameState.json")
        
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
