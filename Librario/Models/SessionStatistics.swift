//
//  SessionData.swift
//  Librario
//
//  A Data Store for Session Level Player Statistics
//
//  Created by Frank Guglielmo on 9/9/24.
//

import Foundation

struct SessionStatistics: Codable {
    
    // Stats to track across the entire session
    var longestWord: String = ""
    var highestScoringWord: String = ""
    var totalWordsSubmitted: Int = 0 // Total number of words across all levels
    private var averageWordLength: Double = 0.0 // Running average for the session
    
    // Expose the average word length for the session
    var sessionAverageWordLength: Double {
        return averageWordLength
    }

    private enum CodingKeys: String, CodingKey {
        case longestWord, highestScoringWord, totalWordsSubmitted, averageWordLength
    }

    // Initialize the struct
    init() {}

    // Codable conformance for custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        longestWord = try container.decode(String.self, forKey: .longestWord)
        highestScoringWord = try container.decode(String.self, forKey: .highestScoringWord)
        totalWordsSubmitted = try container.decode(Int.self, forKey: .totalWordsSubmitted)
        averageWordLength = try container.decode(Double.self, forKey: .averageWordLength)
    }

    // Codable conformance for custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(longestWord, forKey: .longestWord)
        try container.encode(highestScoringWord, forKey: .highestScoringWord)
        try container.encode(totalWordsSubmitted, forKey: .totalWordsSubmitted)
        try container.encode(averageWordLength, forKey: .averageWordLength)
    }

    // Function to update session stats after a level is completed
    mutating func updateFromLevel(_ levelData: LevelStatistics) {
        let levelWords = levelData.wordsSubmitted
        let totalPreviousWords = totalWordsSubmitted

        // Only update if there were words submitted in the level
        if levelWords > 0 {
            // Update the running average word length
            averageWordLength = ((averageWordLength * Double(totalPreviousWords)) +
                                 (levelData.averageWordLength * Double(levelWords))) /
                                 Double(totalPreviousWords + levelWords)
            
            totalWordsSubmitted += levelWords
        }

        if levelData.longestWord.count > longestWord.count {
            longestWord = levelData.longestWord
        }

        if levelData.highestScoringWord.count > highestScoringWord.count {
            highestScoringWord = levelData.highestScoringWord
        }
    }
    
    // Save SessionData to file
    func saveSessionData() {
        let fileURL = SessionStatistics.getDocumentsDirectory().appendingPathComponent("sessionData.json")
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: fileURL)
            print("Session data saved.")
        } catch {
            print("Failed to save session data: \(error)")
        }
    }

    // Load SessionData from file
    static func loadSessionData() -> SessionStatistics {
        let fileURL = getDocumentsDirectory().appendingPathComponent("sessionData.json")
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(SessionStatistics.self, from: data)
        } catch {
            print("Failed to load session data: \(error)")
            return SessionStatistics() // Return a default instance if loading fails
        }
    }

    // Helper function to get the documents directory
    static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

