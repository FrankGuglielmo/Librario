//
//  Settings.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/8/24.
//

import Foundation
import Combine

class Settings: ObservableObject, Codable {
    // Singleton instance
    static let shared: Settings = {
        if let savedData = UserDefaults.standard.data(forKey: "userSettings"),
           let decodedSettings = try? JSONDecoder().decode(Settings.self, from: savedData) {
            return decodedSettings
        } else {
            // If no settings are found, return the default settings
            return defaultSettings
        }
    }()

    @Published var musicVolume: Float { // New volume control for music
        didSet {
            save()
        }
    }

    @Published var soundEffectsVolume: Float { // New volume control for sound effects
        didSet {
            save()
        }
    }

    // Default settings
    static let defaultSettings = Settings(musicVolume: 1.0, soundEffectsVolume: 1.0)

    // Coding Keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case musicVolume
        case soundEffectsVolume
    }

    // Initializer
    init(musicVolume: Float, soundEffectsVolume: Float) {
        self.musicVolume = musicVolume
        self.soundEffectsVolume = soundEffectsVolume
    }

    // Decodable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        musicVolume = try container.decode(Float.self, forKey: .musicVolume)
        soundEffectsVolume = try container.decode(Float.self, forKey: .soundEffectsVolume)
    }

    // Encodable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(musicVolume, forKey: .musicVolume)
        try container.encode(soundEffectsVolume, forKey: .soundEffectsVolume)
    }

    // Method to save the settings to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
        }
    }
}
