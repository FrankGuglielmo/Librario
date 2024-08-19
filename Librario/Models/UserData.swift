//
//  UserData.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/16/24.
//

import Foundation
import SwiftUI

class UserData: ObservableObject {
    
    @Published var highScore: Int
    @Published var settings: GameSettings

    // Initializer
    init() {
        // Load saved data, or use defaults
        self.highScore = UserDefaults.standard.integer(forKey: "highScore")
        self.settings = GameSettings.load() ?? GameSettings.defaultSettings()
    }

    // Save high score if it's higher than the current one
    func saveHighScore(_ score: Int) {
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
    }
}

struct GameSettings: Codable {
    var soundOn: Bool
    var musicOn: Bool

    // Load settings from UserDefaults
    static func load() -> GameSettings? {
        if let data = UserDefaults.standard.data(forKey: "gameSettings"),
           let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            return settings
        }
        return nil
    }

    // Save settings to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "gameSettings")
        }
    }

    // Default settings
    static func defaultSettings() -> GameSettings {
        return GameSettings(soundOn: true, musicOn: true)
    }
}
