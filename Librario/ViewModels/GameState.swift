//
//  GameState.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/15/24.
//

import Foundation

class GameState: ObservableObject, Codable {
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var gameOver: Bool = false
    @Published var shortWordStreak: Int = 0
    
    private enum CodingKeys: String, CodingKey {
        case score, level, shortWordStreak, gameOver
    }
    
    init() {}

    // Codable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Int.self, forKey: .score)
        level = try container.decode(Int.self, forKey: .level)
        shortWordStreak = try container.decode(Int.self, forKey: .shortWordStreak)
        gameOver = try container.decode(Bool.self, forKey: .gameOver)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(score, forKey: .score)
        try container.encode(level, forKey: .level)
        try container.encode(shortWordStreak, forKey: .shortWordStreak)
        try container.encode(gameOver, forKey: .gameOver)
    }

    // Reset the state for a new game
    func reset() {
        score = 0
        level = 1
        shortWordStreak = 0
        gameOver = false
    }

    // Handle game over logic
    func handleGameOver() {
        gameOver = true
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
