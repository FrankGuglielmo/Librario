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
    var longestWordPoints: Int = 0 // Score of the longest word
    var highestScoringWord: String = ""
    var highestScoringWordPoints: Int = 0 // Score of the highest scoring word
    var totalWordsSubmitted: Int = 0 // Total number of words across all sessions
    var totalGamesPlayed: Int = 0 // Total number of games played
    var averageWordLength: Double = 0.0 // Running average for lifetime word length
    var highestLevel: Int = 1 // Highest level the player has reached
    var highestScore: Int = 0 // Highest score achieved in a single game
    var timePlayed: TimeInterval = 0.0 // In seconds

    // Track the last processed session for difference calculations
    private var lastProcessedSession: SessionStatistics? = nil

    // Codable keys
    private enum CodingKeys: String, CodingKey {
        case longestWord, longestWordPoints, highestScoringWord, highestScoringWordPoints, totalWordsSubmitted, totalGamesPlayed, averageWordLength, highestLevel, highestScore, timePlayed, lastProcessedSession
    }

    // Default initializer
    init() {}

    // Codable conformance for decoding
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        longestWord = try container.decode(String.self, forKey: .longestWord)
        longestWordPoints = try container.decode(Int.self, forKey: .longestWordPoints)
        highestScoringWord = try container.decode(String.self, forKey: .highestScoringWord)
        highestScoringWordPoints = try container.decode(Int.self, forKey: .highestScoringWordPoints)
        totalWordsSubmitted = try container.decode(Int.self, forKey: .totalWordsSubmitted)
        totalGamesPlayed = try container.decode(Int.self, forKey: .totalGamesPlayed)
        averageWordLength = try container.decode(Double.self, forKey: .averageWordLength)
        highestLevel = try container.decode(Int.self, forKey: .highestLevel)
        highestScore = try container.decode(Int.self, forKey: .highestScore)
        timePlayed = try container.decode(TimeInterval.self, forKey: .timePlayed)
        lastProcessedSession = try container.decodeIfPresent(SessionStatistics.self, forKey: .lastProcessedSession)
    }

    // Codable conformance for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(longestWord, forKey: .longestWord)
        try container.encode(longestWordPoints, forKey: .longestWordPoints)
        try container.encode(highestScoringWord, forKey: .highestScoringWord)
        try container.encode(highestScoringWordPoints, forKey: .highestScoringWordPoints)
        try container.encode(totalWordsSubmitted, forKey: .totalWordsSubmitted)
        try container.encode(totalGamesPlayed, forKey: .totalGamesPlayed)
        try container.encode(averageWordLength, forKey: .averageWordLength)
        try container.encode(highestLevel, forKey: .highestLevel)
        try container.encode(highestScore, forKey: .highestScore)
        try container.encode(timePlayed, forKey: .timePlayed)
        try container.encode(lastProcessedSession, forKey: .lastProcessedSession)
    }

    // Update user statistics based on new session statistics
    func updateFromSession(_ newSession: SessionStatistics) {
        guard newSession.totalWordsSubmitted > 0 else {
            print("No words submitted in the session, skipping update.")
            return
        }
        
        guard let lastSession = lastProcessedSession else {
            applyNewSessionStatistics(newSession)
            lastProcessedSession = newSession
            return
        }

        if newSession.id != lastSession.id {
            applyNewSessionStatistics(newSession)
            lastProcessedSession = newSession
            return
        }

        let difference = calculateSessionDifference(newSession: newSession, lastSession: lastSession)

        if difference.totalWordsSubmitted > 0 {
            let totalPreviousWords = Double(totalWordsSubmitted)
            let totalNewWords = Double(difference.totalWordsSubmitted)

            if totalPreviousWords + totalNewWords > 0 {
                let newWeightedAverage = ((averageWordLength * totalPreviousWords) + (difference.averageWordLength * totalNewWords)) / (totalPreviousWords + totalNewWords)
                averageWordLength = !newWeightedAverage.isNaN ? newWeightedAverage : averageWordLength
            }

            totalWordsSubmitted += difference.totalWordsSubmitted

            updateLongestWord(newWord: difference.longestWord, score: difference.longestWordPoints)
            updateHighestScoringWord(newWord: difference.highestScoringWord, score: difference.highestScoringWordPoints)

            timePlayed += difference.timePlayed
        }

        lastProcessedSession = newSession
    }

    private func applyNewSessionStatistics(_ session: SessionStatistics) {
        guard session.totalWordsSubmitted > 0 else {
            print("No words submitted in the session, skipping update.")
            return
        }

        let totalWords = Double(session.totalWordsSubmitted + totalWordsSubmitted)
        let weightedSum = ((session.averageWordLength * Double(session.totalWordsSubmitted)) + (averageWordLength * Double(totalWordsSubmitted)))

        averageWordLength = totalWords > 0 ? weightedSum / totalWords : averageWordLength

        updateLongestWord(newWord: session.longestWord, score: session.longestWordPoints)
        updateHighestScoringWord(newWord: session.highestScoringWord, score: session.highestScoringWordPoints)

        totalWordsSubmitted += session.totalWordsSubmitted
        highestScore = max(highestScore, session.highestScore)
        timePlayed += session.timePlayed
    }

    private func calculateSessionDifference(newSession: SessionStatistics, lastSession: SessionStatistics) -> SessionStatistics {
        var difference = SessionStatistics()

        difference.totalWordsSubmitted = newSession.totalWordsSubmitted - lastSession.totalWordsSubmitted

        if difference.totalWordsSubmitted > 0 {
            difference.averageWordLength = newSession.averageWordLength
        }

        if newSession.longestWord.count > lastSession.longestWord.count {
            difference.longestWord = newSession.longestWord
            difference.longestWordPoints = newSession.longestWordPoints
        }

        if newSession.highestScoringWordPoints > lastSession.highestScoringWordPoints {
            difference.highestScoringWord = newSession.highestScoringWord
            difference.highestScoringWordPoints = newSession.highestScoringWordPoints
        }

        difference.timePlayed = newSession.timePlayed - lastSession.timePlayed

        return difference
    }

    private func updateLongestWord(newWord: String, score: Int) {
        if newWord.count > longestWord.count {
            longestWord = newWord
            longestWordPoints = score
        }
    }

    private func updateHighestScoringWord(newWord: String, score: Int) {
        if score > highestScoringWordPoints {
            highestScoringWord = newWord
            highestScoringWordPoints = score
        }
    }

    func updateHighestLevel(level: Int, score: Int) {
        if level > highestLevel {
            highestLevel = level
        }
        if score > highestScore {
            highestScore = score
        }
    }

    func resetStats() {
        longestWord = ""
        longestWordPoints = 0
        highestScoringWord = ""
        highestScoringWordPoints = 0
        totalWordsSubmitted = 0
        totalGamesPlayed = 0
        averageWordLength = 0.0
        highestLevel = 1
        highestScore = 0
        timePlayed = 0.0
        lastProcessedSession = nil
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

