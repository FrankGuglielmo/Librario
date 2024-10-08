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
    var id: UUID = UUID()
    
    // Stats to track for each level
    var longestWord: String = ""
    var longestWordPoints: Int = 0 // Points for the longest word
    var highestScoringWord: String = ""
    var highestScoringWordPoints: Int = 0 // Points for the highest-scoring word
    var wordsSubmitted: Int = 0 // Number of words made this level
    var totalCharacterCount: Int = 0 // Total number of characters across submitted words
    var averageWordLength: Double = 0.0 // Store the average word length
    var highestScore: Int = 0 // Highest total score achieved in this level
    
    var timePlayed: TimeInterval = 0.0 // Time in seconds
        
    // Transient Properties (not encoded)
    private var levelStartTime: Date? = nil
    
    private enum CodingKeys: String, CodingKey {
        case id, longestWord, longestWordPoints, highestScoringWord, highestScoringWordPoints, wordsSubmitted, totalCharacterCount, averageWordLength, highestScore, timePlayed
    }

    // Initialize the struct (using default values)
    init() {
        self.id = UUID()
    }

    // Codable conformance for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id) // Decode UUID
        longestWord = try container.decode(String.self, forKey: .longestWord)
        longestWordPoints = try container.decode(Int.self, forKey: .longestWordPoints)
        highestScoringWord = try container.decode(String.self, forKey: .highestScoringWord)
        highestScoringWordPoints = try container.decode(Int.self, forKey: .highestScoringWordPoints)
        wordsSubmitted = try container.decode(Int.self, forKey: .wordsSubmitted)
        totalCharacterCount = try container.decode(Int.self, forKey: .totalCharacterCount)
        averageWordLength = try container.decode(Double.self, forKey: .averageWordLength)
        highestScore = try container.decode(Int.self, forKey: .highestScore)
        timePlayed = try container.decode(TimeInterval.self, forKey: .timePlayed)
    }

    // Codable conformance for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(longestWord, forKey: .longestWord)
        try container.encode(longestWordPoints, forKey: .longestWordPoints)
        try container.encode(highestScoringWord, forKey: .highestScoringWord)
        try container.encode(highestScoringWordPoints, forKey: .highestScoringWordPoints)
        try container.encode(wordsSubmitted, forKey: .wordsSubmitted)
        try container.encode(totalCharacterCount, forKey: .totalCharacterCount)
        try container.encode(averageWordLength, forKey: .averageWordLength)
        try container.encode(highestScore, forKey: .highestScore)
        try container.encode(timePlayed, forKey: .timePlayed)
    }
    
    // Start timing the level
    mutating func startLevel() {
        levelStartTime = Date()
    }
    
    // Stop timing the level and update timePlayed
    mutating func endGameplay() {
        if let startTime = levelStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            timePlayed += elapsed
            levelStartTime = nil
        } else {
            print("Level was not started.")
        }
    }

    // Function to track a new word submission
    mutating func trackWord(_ word: String, score: Int) {
        wordsSubmitted += 1
        totalCharacterCount += word.count
        
        // Recalculate average word length
        averageWordLength = Double(totalCharacterCount) / Double(wordsSubmitted)

        // Update longest word if applicable
        if word.count > longestWord.count {
            longestWord = word
            longestWordPoints = score
        }

        // Update highest scoring word if applicable
        if score > highestScoringWordPoints {
            highestScoringWord = word
            highestScoringWordPoints = score
        }

        // Update the highest score
        highestScore += score
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
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Level data file not found. Creating new LevelStatistics.")
            return LevelStatistics() // Return a default instance
        }
        
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
