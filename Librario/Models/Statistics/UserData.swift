//
//  UserData.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/16/24.
//

import Foundation
import Observation

@Observable class UserData: Codable {

    // New property for the user's unique identifier
    var userID: String

    // User data components
    var userStatistics: UserStatistics
    var settings: Settings
    var inventory: Inventory

    // Key for UserDefaults
    private let userDataKey = "userData"

    // Coding keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case userID, userStatistics, settings, inventory
    }

    // Initializer with default values (generates a new UUID if one doesn't exist)
    init(userID: String = UUID().uuidString,
         userStatistics: UserStatistics = UserStatistics(),
         settings: Settings = Settings.defaultSettings,
         inventory: Inventory = Inventory()) {
        self.userID = userID
        self.userStatistics = userStatistics
        self.settings = settings
        self.inventory = inventory
    }

    // Codable conformance for decoding (loads userID from saved data if present)
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(String.self, forKey: .userID)
        userStatistics = try container.decode(UserStatistics.self, forKey: .userStatistics)
        settings = try container.decode(Settings.self, forKey: .settings)
        
        // Try to decode inventory, or create a new one if it doesn't exist
        if let inventory = try? container.decode(Inventory.self, forKey: .inventory) {
            self.inventory = inventory
        } else {
            self.inventory = Inventory()
        }
    }

    // Codable conformance for encoding (saves userID along with other data)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(userStatistics, forKey: .userStatistics)
        try container.encode(settings, forKey: .settings)
        try container.encode(inventory, forKey: .inventory)
    }

    // Save UserData to UserDefaults (this includes saving the userID)
    func saveUserData() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: userDataKey)
            print("User data (including userID) saved to UserDefaults.")
        } catch {
            print("Failed to save user data to UserDefaults: \(error)")
        }
    }

    // Load UserData from UserDefaults (reuses existing userID if present, otherwise generates a new one)
    static func loadUserData() -> UserData {
        guard let data = UserDefaults.standard.data(forKey: "userData") else {
            // Return a new instance with a generated userID if data doesn't exist
            return UserData()
        }
        do {
            let userData = try JSONDecoder().decode(UserData.self, from: data)
            return userData
        } catch {
            print("Failed to load user data from UserDefaults: \(error)")
            // Return a new instance with a generated userID if decoding fails
            return UserData()
        }
    }

    // Convenience function to ensure userID is always initialized and saved
    static func ensureUserID() -> String {
        let userData = loadUserData()
        if userData.userID.isEmpty {
            userData.userID = UUID().uuidString
            userData.saveUserData()
        }
        return userData.userID
    }
}
