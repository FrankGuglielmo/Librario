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
    
    var id: UUID = UUID()
    
    // Stats to track across the entire session
    var longestWord: String = ""
    var highestScoringWord: String = ""
    var totalWordsSubmitted: Int = 0 // Total number of words across all levels
    var averageWordLength: Double = 0.0 // Running average for the session
    var timePlayed: TimeInterval = 0.0
    
    // Track the last processed level for difference calculations
    private var lastProcessedLevel: LevelStatistics? = nil

    private enum CodingKeys: String, CodingKey {
        case id, longestWord, highestScoringWord, totalWordsSubmitted, averageWordLength, timePlayed, lastProcessedLevel
    }
    
    // Initialize the struct
    init() {
        self.id = UUID()
    }

    // Codable conformance for custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        longestWord = try container.decode(String.self, forKey: .longestWord)
        highestScoringWord = try container.decode(String.self, forKey: .highestScoringWord)
        totalWordsSubmitted = try container.decode(Int.self, forKey: .totalWordsSubmitted)
        averageWordLength = try container.decode(Double.self, forKey: .averageWordLength)
        timePlayed = try container.decode(TimeInterval.self, forKey: .timePlayed)
        lastProcessedLevel = try container.decode(LevelStatistics.self, forKey: .lastProcessedLevel)
    }

    // Codable conformance for custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(longestWord, forKey: .longestWord)
        try container.encode(highestScoringWord, forKey: .highestScoringWord)
        try container.encode(totalWordsSubmitted, forKey: .totalWordsSubmitted)
        try container.encode(averageWordLength, forKey: .averageWordLength)
        try container.encode(timePlayed, forKey: .timePlayed)
        try container.encode(lastProcessedLevel, forKey: .lastProcessedLevel)
    }
    
    // Update session statistics based on new level statistics
    mutating func updateFromLevel(_ newLevel: LevelStatistics) {
        // If this is the first time processing, use all the new data
        guard let lastLevel = lastProcessedLevel else {
            applyLevelStatistics(newLevel)
            lastProcessedLevel = newLevel
            return
        }

        // Check if there's new unprocessed data for the level
        if newLevel.id != lastLevel.id {
            // If it's a different level, treat it as a new level
            applyLevelStatistics(newLevel)
            lastProcessedLevel = newLevel
            return
        }

        // Now process only the difference (new data in the same level)
        let difference = calculateLevelDifference(newLevel: newLevel, lastLevel: lastLevel)

        // Only apply the difference if there's new data
        if difference.wordsSubmitted != 0 {
            totalWordsSubmitted += difference.wordsSubmitted
            updateLongestWord(newWord: difference.longestWord)
            updateHighestScoringWord(newWord: difference.highestScoringWord)

            // Update the running average word length
            let levelWords = difference.wordsSubmitted
            let totalPreviousWords = totalWordsSubmitted - levelWords
            if levelWords > 0 {
                averageWordLength = ((averageWordLength * Double(totalPreviousWords)) +
                                     (newLevel.averageWordLength * Double(levelWords))) /
                                    Double(totalPreviousWords + levelWords)
            }

            // Update timePlayed
            let newTime = newLevel.timePlayed
            let lastTime = lastLevel.timePlayed
            let differenceTime = newTime - lastTime
            if differenceTime > 0 {
                timePlayed += differenceTime
            }

            // Mark this level as processed up to the new point
            lastProcessedLevel = newLevel
        }
    }

    private mutating func applyLevelStatistics(_ level: LevelStatistics) {
        // Ensure there is levelData to submit
        guard level.averageWordLength > 0 && level.wordsSubmitted > 0 else {
            print("No new data from Level to submit")
            return
        }
        // Calculate new averageWordLength
        let weightedSum = ((averageWordLength * Double(totalWordsSubmitted)) + (level.averageWordLength * Double(level.wordsSubmitted)))
        let totalWords = totalWordsSubmitted + level.wordsSubmitted
        averageWordLength = weightedSum / Double(totalWords)
        
        totalWordsSubmitted += level.wordsSubmitted
        updateLongestWord(newWord: level.longestWord)
        updateHighestScoringWord(newWord: level.highestScoringWord)
        
        // Update timePlayed
        timePlayed += level.timePlayed
    }

    // Calculate the difference between the new level and the last processed level
    private func calculateLevelDifference(newLevel: LevelStatistics, lastLevel: LevelStatistics) -> LevelStatistics {
        var difference = LevelStatistics()
        
        // Calculate the difference in words and total characters submitted
        difference.wordsSubmitted = newLevel.wordsSubmitted - lastLevel.wordsSubmitted
        difference.totalCharacterCount = newLevel.totalCharacterCount - lastLevel.totalCharacterCount
        
        // Safely calculate average word length if words have been submitted
        if difference.wordsSubmitted > 0 {
            difference.averageWordLength = Double(difference.totalCharacterCount) / Double(difference.wordsSubmitted)
        } else {
            difference.averageWordLength = 0.0 // No new words submitted
        }
        
        // Update the longest word if it's changed
        if newLevel.longestWord.count > lastLevel.longestWord.count {
            difference.longestWord = newLevel.longestWord
        }

        // Update the highest scoring word if it's changed
        if newLevel.highestScoringWordPoints > lastLevel.highestScoringWordPoints {
            difference.highestScoringWord = newLevel.highestScoringWord
            difference.highestScoringWordPoints = newLevel.highestScoringWordPoints
        }
        
        // Calculate time difference
        difference.timePlayed = newLevel.timePlayed - lastLevel.timePlayed
        
        return difference
    }

    
    private mutating func updateLongestWord(newWord: String) {
        if newWord.count > longestWord.count {
            longestWord = newWord
        }
    }

    private mutating func updateHighestScoringWord(newWord: String) {
        if newWord.count > highestScoringWord.count {
            highestScoringWord = newWord
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
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Session data file not found. Creating new SessionStatistics.")
            return SessionStatistics() // Return a default instance
        }
        
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

