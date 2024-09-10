//
//  LevelData.swift
//  Librario
//
//  A Data Type to store information pertaining to a given level during a game.
//
//  Created by Frank Guglielmo on 9/9/24.
//

import Foundation

struct LevelStatistics: Codable {
    
    //Stats to track:
    var longestWord: String = ""
    var highestScoringWord: String = ""
    var wordsSubmitted: Int = 0 // Number of words made this level
    var totalCharacterCount: Int = 0 // Total number of characters across submitted words
    var averageWordLength: Double {
        return wordsSubmitted == 0 ? 0.0 : Double(totalCharacterCount) / Double(wordsSubmitted)
    }
    
    private enum CodingKeys: String, CodingKey {
        case longestWord, highestScoringWord, wordsSubmitted, totalCharacterCount
    }

    // Initialize the struct (using default values is optional since you already have defaults)
    init() {}

    // Codable conformance is automatically derived in this case, but you can override if needed
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        longestWord = try container.decode(String.self, forKey: .longestWord)
        highestScoringWord = try container.decode(String.self, forKey: .highestScoringWord)
        wordsSubmitted = try container.decode(Int.self, forKey: .wordsSubmitted)
        totalCharacterCount = try container.decode(Int.self, forKey: .totalCharacterCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(longestWord, forKey: .longestWord)
        try container.encode(highestScoringWord, forKey: .highestScoringWord)
        try container.encode(wordsSubmitted, forKey: .wordsSubmitted)
        try container.encode(totalCharacterCount, forKey: .totalCharacterCount)
    }

    // Function to track a new word submission
    mutating func trackWord(_ word: String, score: Int) {
        wordsSubmitted += 1
        totalCharacterCount += word.count

        if word.count > longestWord.count {
            longestWord = word
        }
        if score > highestScoringWord.count {
            highestScoringWord = word
        }
    }
    
    // Save LevelData to file
    func saveLevelData(_ levelData: LevelStatistics) {
        let fileURL = LevelStatistics.getDocumentsDirectory().appendingPathComponent("levelData.json")
        do {
            let data = try JSONEncoder().encode(levelData)
            try data.write(to: fileURL)
            print("Level data saved.")
        } catch {
            print("Failed to save level data: \(error)")
        }
    }

    // Load LevelData from file
    static func loadLevelData() -> LevelStatistics {
        let fileURL = getDocumentsDirectory().appendingPathComponent("levelData.json")
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(LevelStatistics.self, from: data)
        } catch {
            print("Failed to load level data: \(error)")
            return LevelStatistics() // Return a default instance if loading fails
        }
    }

    // Helper function to get the documents directory
    static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    
}
