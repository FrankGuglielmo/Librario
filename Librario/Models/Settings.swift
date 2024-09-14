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

    @Published var musicEnabled: Bool {
        didSet {
            save()
        }
    }

    @Published var soundEffectsEnabled: Bool {
        didSet {
            save()
        }
    }

    // Default settings
    static let defaultSettings = Settings(musicEnabled: true, soundEffectsEnabled: true)

    // Coding Keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case musicEnabled
        case soundEffectsEnabled
    }

    // Initializer
    init(musicEnabled: Bool, soundEffectsEnabled: Bool) {
        self.musicEnabled = musicEnabled
        self.soundEffectsEnabled = soundEffectsEnabled
    }

    // Decodable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Manually decode the properties
        musicEnabled = try container.decode(Bool.self, forKey: .musicEnabled)
        soundEffectsEnabled = try container.decode(Bool.self, forKey: .soundEffectsEnabled)
    }

    // Encodable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Manually encode the properties
        try container.encode(musicEnabled, forKey: .musicEnabled)
        try container.encode(soundEffectsEnabled, forKey: .soundEffectsEnabled)
    }

    // Method to save the settings to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
        }
    }
}

