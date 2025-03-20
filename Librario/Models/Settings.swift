//
//  Settings.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/8/24.
//

import Foundation
import Observation

@Observable class Settings: Codable {
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

    var musicVolume: Float {
        didSet {
            save()
            //Notify AudioManager
            AudioManager.shared.settingsDidChange()
        }
    }

    var soundEffectsVolume: Float {
        didSet {
            save()
            //Notify AudioManager
            AudioManager.shared.settingsDidChange()
        }
    }
    
    var showDebugTimer: Bool {
        didSet {
            save()
        }
    }

    // Default settings
    static let defaultSettings = Settings(musicVolume: 1.0, soundEffectsVolume: 1.0, showDebugTimer: false)

    // Coding Keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case musicVolume
        case soundEffectsVolume
        case showDebugTimer
    }

    // Initializer
    init(musicVolume: Float, soundEffectsVolume: Float, showDebugTimer: Bool) {
        self.musicVolume = musicVolume
        self.soundEffectsVolume = soundEffectsVolume
        self.showDebugTimer = showDebugTimer
    }

    // Decodable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        musicVolume = try container.decode(Float.self, forKey: .musicVolume)
        soundEffectsVolume = try container.decode(Float.self, forKey: .soundEffectsVolume)
        // If showDebugTimer doesn't exist in older saved settings, default to false
        showDebugTimer = try container.decodeIfPresent(Bool.self, forKey: .showDebugTimer) ?? false
    }

    // Encodable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(musicVolume, forKey: .musicVolume)
        try container.encode(soundEffectsVolume, forKey: .soundEffectsVolume)
        try container.encode(showDebugTimer, forKey: .showDebugTimer)
    }

    // Method to save the settings to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
        }
    }
}
