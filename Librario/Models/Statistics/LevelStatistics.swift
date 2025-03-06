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
    private var accumulatedTime: TimeInterval = 0.0
    private var isPaused: Bool = false
    
    // Get the current elapsed time (including accumulated time and current running time)
    var currentElapsedTime: TimeInterval {
        if let startTime = levelStartTime {
            // Timer is running, add current elapsed time to accumulated time
            return accumulatedTime + Date().timeIntervalSince(startTime)
        } else if isPaused {
            // Timer is paused, return accumulated time
            return accumulatedTime
        } else {
            // Timer is not running and not paused, return stored time
            return timePlayed
        }
    }
    
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
    
    mutating func updateTimePlayed(additionalTime: TimeInterval) {
        if additionalTime > 0 {
            timePlayed += additionalTime
            print("LevelStatistics: Added \(additionalTime.formattedCompact) to timePlayed")
            print("LevelStatistics: Total timePlayed is now \(timePlayed.formattedCompact)")
        }
    }
    
    // Start timing the level
    mutating func startLevel() {
        if levelStartTime == nil && !isPaused {
            levelStartTime = Date()
            print("Level timer started.")
        }
    }
    
    // Pause timing without ending the gameplay session
    mutating func pauseGameplay() {
        if let startTime = levelStartTime, !isPaused {
            // Add elapsed time to accumulated time
            accumulatedTime += Date().timeIntervalSince(startTime)
            levelStartTime = nil
            isPaused = true
            print("Level timer paused. Accumulated time: \(accumulatedTime.formattedCompact)")
        }
    }
    
    // Resume timing from a paused state
    mutating func resumeGameplay() {
        if isPaused {
            levelStartTime = Date()
            isPaused = false
            print("Level timer resumed. Accumulated time: \(accumulatedTime.formattedCompact)")
        }
    }
    
    // Stop timing the level and update timePlayed
    mutating func endGameplay() {
        if let startTime = levelStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            timePlayed = accumulatedTime + elapsed
            levelStartTime = nil
            accumulatedTime = 0.0
            isPaused = false
            print("Level timer ended. Total time: \(timePlayed.formattedCompact)")
            
            // Save the level data
            saveLevelData(self)
        } else if isPaused {
            // If we're paused, just use the accumulated time
            timePlayed = accumulatedTime
            accumulatedTime = 0.0
            isPaused = false
            print("Level timer ended from paused state. Total time: \(timePlayed.formattedCompact)")
            
            // Save the level data
            saveLevelData(self)
        } else {
            print("Level timer was not started.")
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
    
    mutating func finalizeCurrentTime() {
        if let startTime = levelStartTime {
            // If timer is running, add current elapsed time to timePlayed
            let currentRunningTime = Date().timeIntervalSince(startTime)
            
            // Reset timer
            levelStartTime = Date()
            
            // Update timePlayed with accumulated and current time
            timePlayed += accumulatedTime + currentRunningTime
            
            // Reset accumulated time
            accumulatedTime = 0.0
            
            print("Finalized level time: Added \(currentRunningTime.formattedCompact) + \(accumulatedTime.formattedCompact)")
            print("Level total time is now: \(timePlayed.formattedCompact)")
        } else if isPaused {
            // If we're paused, add accumulated time
            timePlayed += accumulatedTime
            accumulatedTime = 0.0
            print("Finalized paused level time: Added \(accumulatedTime.formattedCompact)")
            print("Level total time is now: \(timePlayed.formattedCompact)")
        }
        
        // Save the level data
        saveLevelData(self)
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

