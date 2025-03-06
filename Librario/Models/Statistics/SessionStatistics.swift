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
    var longestWordPoints: Int = 0 // Score for the longest word
    var highestScoringWord: String = ""
    var highestScoringWordPoints: Int = 0 // Score for the highest scoring word
    var totalWordsSubmitted: Int = 0 // Total number of words across all levels
    var averageWordLength: Double = 0.0 // Running average for the session
    var highestScore: Int = 0 // Highest score achieved in the session
    var timePlayed: TimeInterval = 0.0 // Time played in seconds
    private var levelTimeTracker: [UUID: TimeInterval] = [:]
    
    // Get the current elapsed time (including stored time and current level time)
    func currentElapsedTime(currentLevel: LevelStatistics) -> TimeInterval {
        // Add the current level's elapsed time to the stored session time
        return timePlayed + (currentLevel.currentElapsedTime - (lastProcessedLevel?.timePlayed ?? 0.0))
    }
    
    // Track the last processed level for difference calculations
    private var lastProcessedLevel: LevelStatistics? = nil

    private enum CodingKeys: String, CodingKey {
        case id, longestWord, longestWordPoints, highestScoringWord, highestScoringWordPoints,
             totalWordsSubmitted, averageWordLength, highestScore, timePlayed, lastProcessedLevel,
             levelTimeTracker
    }

    
    // Initialize the struct
    init() {
        self.id = UUID()
    }

    // Codable conformance for custom decoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(longestWord, forKey: .longestWord)
        try container.encode(longestWordPoints, forKey: .longestWordPoints)
        try container.encode(highestScoringWord, forKey: .highestScoringWord)
        try container.encode(highestScoringWordPoints, forKey: .highestScoringWordPoints)
        try container.encode(totalWordsSubmitted, forKey: .totalWordsSubmitted)
        try container.encode(averageWordLength, forKey: .averageWordLength)
        try container.encode(highestScore, forKey: .highestScore)
        try container.encode(timePlayed, forKey: .timePlayed)
        try container.encode(lastProcessedLevel, forKey: .lastProcessedLevel)
        try container.encode(levelTimeTracker, forKey: .levelTimeTracker)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        longestWord = try container.decode(String.self, forKey: .longestWord)
        longestWordPoints = try container.decode(Int.self, forKey: .longestWordPoints)
        highestScoringWord = try container.decode(String.self, forKey: .highestScoringWord)
        highestScoringWordPoints = try container.decode(Int.self, forKey: .highestScoringWordPoints)
        totalWordsSubmitted = try container.decode(Int.self, forKey: .totalWordsSubmitted)
        averageWordLength = try container.decode(Double.self, forKey: .averageWordLength)
        highestScore = try container.decode(Int.self, forKey: .highestScore)
        timePlayed = try container.decode(TimeInterval.self, forKey: .timePlayed)
        lastProcessedLevel = try container.decodeIfPresent(LevelStatistics.self, forKey: .lastProcessedLevel)
        levelTimeTracker = try container.decodeIfPresent([UUID: TimeInterval].self, forKey: .levelTimeTracker) ?? [:]
    }
    
    // Update session statistics based on new level statistics
    mutating func updateFromLevel(_ newLevel: LevelStatistics) {
        // If this is the first time processing this level, store its current time
        if levelTimeTracker[newLevel.id] == nil {
            levelTimeTracker[newLevel.id] = 0
        }
        
        // Calculate the time difference since last update for this level
        let previousTimeForLevel = levelTimeTracker[newLevel.id] ?? 0
        let currentLevelTime = newLevel.timePlayed
        let timeToAdd = currentLevelTime - previousTimeForLevel
        
        // Only add positive time differences
        if timeToAdd > 0 {
            print("Adding time from level \(newLevel.id): \(timeToAdd.formattedCompact)")
            print("  Level time: \(currentLevelTime.formattedCompact)")
            print("  Previous tracked time: \(previousTimeForLevel.formattedCompact)")
            timePlayed += timeToAdd
            
            // Update the tracked time for this level
            levelTimeTracker[newLevel.id] = currentLevelTime
        } else {
            print("No new time to add from level \(newLevel.id)")
        }
        
        // Update the rest of the statistics
        // Ensure there is level data to submit
        guard newLevel.averageWordLength > 0 && newLevel.wordsSubmitted > 0 else {
            print("No new word data from Level to submit")
            return
        }
        
        // If it's not the same level as before or we haven't processed a level yet
        if lastProcessedLevel == nil || newLevel.id != lastProcessedLevel!.id {
            // This is a new level, so we process all its data
            // Calculate new averageWordLength
            let weightedSum = ((averageWordLength * Double(totalWordsSubmitted)) +
                              (newLevel.averageWordLength * Double(newLevel.wordsSubmitted)))
            let totalWords = totalWordsSubmitted + newLevel.wordsSubmitted
            if totalWords > 0 {
                averageWordLength = weightedSum / Double(totalWords)
            }
            
            totalWordsSubmitted += newLevel.wordsSubmitted
            updateLongestWord(newWord: newLevel.longestWord, score: newLevel.longestWordPoints)
            updateHighestScoringWord(newWord: newLevel.highestScoringWord, score: newLevel.highestScoringWordPoints)
            
            // Update highest score
            highestScore = max(highestScore, newLevel.highestScore)
        } else {
            // This is the same level as before, so we only process new data
            let difference = calculateLevelDifference(newLevel: newLevel, lastLevel: lastProcessedLevel!)
            
            // Only apply the difference if there's new data
            if difference.wordsSubmitted > 0 {
                totalWordsSubmitted += difference.wordsSubmitted
                updateLongestWord(newWord: difference.longestWord, score: difference.longestWordPoints)
                updateHighestScoringWord(newWord: difference.highestScoringWord, score: difference.highestScoringWordPoints)

                // Update the running average word length
                let levelWords = difference.wordsSubmitted
                let totalPreviousWords = totalWordsSubmitted - levelWords
                if totalPreviousWords + levelWords > 0 {
                    averageWordLength = ((averageWordLength * Double(totalPreviousWords)) +
                                         (newLevel.averageWordLength * Double(levelWords))) /
                                        Double(totalPreviousWords + levelWords)
                }

                // Update highest score if the new level has a higher score
                highestScore = max(highestScore, newLevel.highestScore)
            }
        }
        
        // Mark this level as processed up to the new point
        lastProcessedLevel = newLevel
    }

    private mutating func applyLevelStatistics(_ level: LevelStatistics) {
        // Ensure there is level data to submit
        guard level.averageWordLength > 0 && level.wordsSubmitted > 0 else {
            print("No new data from Level to submit")
            return
        }
        
        // Calculate new averageWordLength
        let weightedSum = ((averageWordLength * Double(totalWordsSubmitted)) + (level.averageWordLength * Double(level.wordsSubmitted)))
        let totalWords = totalWordsSubmitted + level.wordsSubmitted
        averageWordLength = weightedSum / Double(totalWords)
        
        totalWordsSubmitted += level.wordsSubmitted
        updateLongestWord(newWord: level.longestWord, score: level.longestWordPoints)
        updateHighestScoringWord(newWord: level.highestScoringWord, score: level.highestScoringWordPoints)
        
        // Update highest score
        highestScore = max(highestScore, level.highestScore)
        
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
            difference.longestWordPoints = newLevel.longestWordPoints
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

    
    private mutating func updateLongestWord(newWord: String, score: Int) {
        if newWord.count > longestWord.count {
            longestWord = newWord
            longestWordPoints = score
        }
    }

    private mutating func updateHighestScoringWord(newWord: String, score: Int) {
        if score > highestScoringWordPoints {
            highestScoringWord = newWord
            highestScoringWordPoints = score
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
