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
    var averageWordLength: Double = 0.0 // Running average for lifetime word length
    var highestLevel: Int = 1 // Highest level the player has reached
    var timePlayed: TimeInterval = 0.0 // In seconds

    // Track the last processed session for difference calculations
    private var lastProcessedSession: SessionStatistics? = nil
    
    private enum CodingKeys: String, CodingKey {
        case longestWord, highestScoringWord, totalWordsSubmitted, totalGamesPlayed, averageWordLength, highestLevel, timePlayed, lastProcessedSession
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
        highestLevel = try container.decode(Int.self, forKey: .highestLevel)
        timePlayed = try container.decode(TimeInterval.self, forKey: .timePlayed)
        lastProcessedSession = try container.decode(SessionStatistics.self, forKey: .lastProcessedSession)
    }

    // Codable conformance for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(longestWord, forKey: .longestWord)
        try container.encode(highestScoringWord, forKey: .highestScoringWord)
        try container.encode(totalWordsSubmitted, forKey: .totalWordsSubmitted)
        try container.encode(totalGamesPlayed, forKey: .totalGamesPlayed)
        try container.encode(averageWordLength, forKey: .averageWordLength)
        try container.encode(highestLevel, forKey: .highestLevel)
        try container.encode(timePlayed, forKey: .timePlayed)
        try container.encode(lastProcessedSession, forKey: .lastProcessedSession)
    }

    // Update user statistics based on new session statistics
    func updateFromSession(_ newSession: SessionStatistics) {
        // Ensure that no update happens if there are no words or games played
        guard newSession.totalWordsSubmitted > 0 else {
            print("No words submitted in the session, skipping update.")
            return
        }
        
        // If this is the first time processing this session, use all the new data
        guard let lastSession = lastProcessedSession else {
            applyNewSessionStatistics(newSession)
            lastProcessedSession = newSession
            return
        }

        // Check if the new session is the same as the last processed session
        if newSession.id != lastSession.id {
            applyNewSessionStatistics(newSession)
            lastProcessedSession = newSession
            return
        }

        // Process only the difference (new data in the same session)
        let difference = calculateSessionDifference(newSession: newSession, lastSession: lastSession)

        // Ensure there's something to update
        if difference.totalWordsSubmitted > 0 {
            let totalPreviousWords = Double(totalWordsSubmitted)
            let totalNewWords = Double(difference.totalWordsSubmitted)

            // Avoid division by zero
            if totalPreviousWords + totalNewWords > 0 {
                let newWeightedAverage = ((averageWordLength * totalPreviousWords) + (difference.averageWordLength * totalNewWords)) / (totalPreviousWords + totalNewWords)

                // Ensure we don't assign NaN values
                if !newWeightedAverage.isNaN {
                    averageWordLength = newWeightedAverage
                } else {
                    print("Warning: Computed NaN for average word length. Keeping previous average.")
                }
            }

            // Update total words submitted
            totalWordsSubmitted += difference.totalWordsSubmitted
            // Update longest and highest scoring words
            updateLongestWord(newWord: difference.longestWord)
            updateHighestScoringWord(newWord: difference.highestScoringWord)
            
            // Update timePlayed
            let newTime = difference.timePlayed
            if newTime > 0 {
                timePlayed += newTime
            }
        }

        // Mark this session as processed up to the new point
        lastProcessedSession = newSession
    }

    private func applyNewSessionStatistics(_ session: SessionStatistics) {
        // Ensure no updates are applied if there are no valid words
        guard session.totalWordsSubmitted > 0 else {
            print("No words submitted in the session, skipping new session statistics.")
            return
        }

        // Calculate Average Word Length
        let weightedSum = ((session.averageWordLength * Double(session.totalWordsSubmitted)) + (averageWordLength * Double(totalWordsSubmitted)))
        let totalWords = Double(session.totalWordsSubmitted + totalWordsSubmitted)

        // Avoid division by zero
        if totalWords > 0 {
            averageWordLength = weightedSum / totalWords
        } else {
            print("Warning: Division by zero in applyNewSessionStatistics, skipping update.")
        }

        // Update best words if possible
        updateLongestWord(newWord: session.longestWord)
        updateHighestScoringWord(newWord: session.highestScoringWord)
        // Update total words and games played
        totalWordsSubmitted += session.totalWordsSubmitted
        
        // Update timePlayed
        timePlayed += session.timePlayed
    }


private func calculateSessionDifference(newSession: SessionStatistics, lastSession: SessionStatistics) -> SessionStatistics {
        var difference = SessionStatistics()
        
        // Calculate the difference in total words submitted
        difference.totalWordsSubmitted = newSession.totalWordsSubmitted - lastSession.totalWordsSubmitted
        
        // Safely calculate average word length for the difference, if words have been submitted
        if difference.totalWordsSubmitted > 0 {
            difference.averageWordLength = newSession.averageWordLength
        } else {
            difference.averageWordLength = 0.0 // No new words submitted
        }
        
        // Update the longest word if it's changed
        if newSession.longestWord.count > lastSession.longestWord.count {
            difference.longestWord = newSession.longestWord
        }
        
        // Update the highest scoring word if it's changed
        if newSession.highestScoringWord.count > lastSession.highestScoringWord.count {
            difference.highestScoringWord = newSession.highestScoringWord
        }
        
        // Calculate time difference
        difference.timePlayed = newSession.timePlayed - lastSession.timePlayed
        
        return difference
    }

    
    private func updateLongestWord(newWord: String) {
        if newWord.count > longestWord.count {
            longestWord = newWord
        }
    }

    private func updateHighestScoringWord(newWord: String) {
        if newWord.count > highestScoringWord.count {
            highestScoringWord = newWord
        }
    }
    
    func updateHighestlevel(level: Int) {
        if level > highestLevel {
            highestLevel = level
        }
    }

    func resetStats() {
        // Resetting all the properties to their initial values
        longestWord = ""
        highestScoringWord = ""
        totalWordsSubmitted = 0
        totalGamesPlayed = 0
        averageWordLength = 0.0
        lastProcessedSession = nil
        
        // Optionally, you can add a message or log to indicate the reset
        print("User statistics have been reset.")
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
