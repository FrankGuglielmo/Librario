//
//  UserData.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/16/24.
//

import Foundation

class UserData: ObservableObject, Codable {

    // User data components
    @Published var userStatistics: UserStatistics
    @Published var settings: Settings

    // Key for UserDefaults
    private let userDataKey = "userData"

    // Coding keys for encoding/decoding
    private enum CodingKeys: String, CodingKey {
        case userStatistics, settings
    }

    // Initializer with default values
    init(userStatistics: UserStatistics = UserStatistics(), settings: Settings = Settings.defaultSettings) {
        self.userStatistics = userStatistics
        self.settings = settings
    }

    // Codable conformance for decoding
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userStatistics = try container.decode(UserStatistics.self, forKey: .userStatistics)
        settings = try container.decode(Settings.self, forKey: .settings)
    }

    // Codable conformance for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userStatistics, forKey: .userStatistics)
        try container.encode(settings, forKey: .settings)
    }

    // Save UserData to UserDefaults
    func saveUserData() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: userDataKey)
            print("User data saved to UserDefaults.")
        } catch {
            print("Failed to save user data to UserDefaults: \(error)")
        }
    }

    // Load UserData from UserDefaults
    static func loadUserData() -> UserData {
        guard let data = UserDefaults.standard.data(forKey: "userData") else {
            // Return a default instance if loading fails or data doesn't exist
            return UserData()
        }
        do {
            return try JSONDecoder().decode(UserData.self, from: data)
        } catch {
            print("Failed to load user data from UserDefaults: \(error)")
            return UserData() // Return a default instance if loading fails
        }
    }
}
