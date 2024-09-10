//
//  UserStatistics.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/9/24.
//

import Foundation

class UserStatistics: Codable {
    
    // Stats to track lifetime user statistics
    var longestWord: String = ""
    var highestScoringWord: String = ""
    var totalWordsSubmitted: Int = 0 // Total number of words across all sessions
    var totalGamesPlayed: Int = 0 // Total number of games played
    private var averageWordLength: Double = 0.0 // Running average for lifetime word length

    // Expose the lifetime average word length
    var lifetimeAverageWordLength: Double {
        return averageWordLength
    }

    private enum CodingKeys: String, CodingKey {
        case longestWord, highestScoringWord, totalWordsSubmitted, totalGamesPlayed, averageWordLength
    }

    // Default initializer
    init() {}

    // Codable conformance for decoding
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        longestWord = try container.decode(String.self, forKey: .longestWord)
        highestScoringWord = try container.decode(String.self, forKey: .highestScoringWord)
        totalWordsSubmitted = try container.decode(Int.self, forKey: .totalWordsSubmitted)
        totalGamesPlayed = try container.decode(Int.self, forKey: .totalGamesPlayed)
        averageWordLength = try container.decode(Double.self, forKey: .averageWordLength)
    }

    // Codable conformance for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(longestWord, forKey: .longestWord)
        try container.encode(highestScoringWord, forKey: .highestScoringWord)
        try container.encode(totalWordsSubmitted, forKey: .totalWordsSubmitted)
        try container.encode(totalGamesPlayed, forKey: .totalGamesPlayed)
        try container.encode(averageWordLength, forKey: .averageWordLength)
    }

    // Function to update user stats from a session
    func updateFromSession(_ sessionData: SessionStatistics) {
        let sessionWords = sessionData.totalWordsSubmitted
        let totalPreviousWords = totalWordsSubmitted

        // Only update if there were words submitted in the session
        if sessionWords > 0 {
            // Update running average word length using the session's average word length
            averageWordLength = ((averageWordLength * Double(totalPreviousWords)) +
                                 (sessionData.sessionAverageWordLength * Double(sessionWords))) /
                                Double(totalPreviousWords + sessionWords)

            totalWordsSubmitted += sessionWords
        }

        // Update longest word if needed
        if sessionData.longestWord.count > longestWord.count {
            longestWord = sessionData.longestWord
        }

        // Update highest scoring word if needed
        if sessionData.highestScoringWord.count > highestScoringWord.count {
            highestScoringWord = sessionData.highestScoringWord
        }

        totalGamesPlayed += 1
    }

    // Save UserStatistics to file
    func saveUserStatistics() {
        let fileURL = UserStatistics.getDocumentsDirectory().appendingPathComponent("userStatistics.json")
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: fileURL)
            print("User statistics saved.")
        } catch {
            print("Failed to save user statistics: \(error)")
        }
    }

    // Load UserStatistics from file
    static func loadUserStatistics() -> UserStatistics {
        let fileURL = getDocumentsDirectory().appendingPathComponent("userStatistics.json")
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(UserStatistics.self, from: data)
        } catch {
            print("Failed to load user statistics: \(error)")
            return UserStatistics() // Return a default instance if loading fails
        }
    }

    // Helper function to get the documents directory
    static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
