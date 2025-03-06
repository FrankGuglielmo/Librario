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
    
    // Engagement statistics
    var lastPlayedDate: Date? = nil // Last day the user played the game
    var loginStreak: Int = 0 // Number of consecutive days played
    
    // Get the current elapsed time (including stored time and current session time)
    func currentElapsedTime(currentSession: SessionStatistics, currentLevel: LevelStatistics) -> TimeInterval {
        // Add the current session's elapsed time to the stored user time
        return timePlayed + (currentSession.currentElapsedTime(currentLevel: currentLevel) - (lastProcessedSession?.timePlayed ?? 0.0))
    }

    // Track the last processed session for difference calculations
    private var lastProcessedSession: SessionStatistics? = nil

    // Codable keys
    private enum CodingKeys: String, CodingKey {
        case longestWord, longestWordPoints, highestScoringWord, highestScoringWordPoints, totalWordsSubmitted, totalGamesPlayed, averageWordLength, highestLevel, highestScore, timePlayed, lastProcessedSession, lastPlayedDate, loginStreak
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
        lastPlayedDate = try container.decodeIfPresent(Date.self, forKey: .lastPlayedDate)
        loginStreak = try container.decodeIfPresent(Int.self, forKey: .loginStreak) ?? 0
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
        try container.encode(lastPlayedDate, forKey: .lastPlayedDate)
        try container.encode(loginStreak, forKey: .loginStreak)
    }

    // Update user statistics based on new session statistics
    /**
     * Updates the UserStatistics with data from a SessionStatistics object.
     * This method is called when updating lifetime statistics from a game session.
     *
     * @param sessionData The SessionStatistics containing data to update with.
     */
    func updateFromSession(_ sessionData: SessionStatistics) {
        // Get the session time before adding
        let sessionTime = sessionData.timePlayed
        
        // Only add positive time values
        if sessionTime > 0 {
            print("UserStatistics: Adding session time to lifetime stats: \(sessionTime.formattedCompact)")
            print("UserStatistics: Current total time played: \(self.timePlayed.formattedCompact)")
            
            // Add session time to lifetime total time
            self.timePlayed += sessionTime
            
            print("UserStatistics: Updated total time played: \(self.timePlayed.formattedCompact)")
        } else {
            print("UserStatistics: No session time to add (timePlayed = \(sessionTime.formattedCompact))")
        }
        
        // Update other statistics
        self.totalWordsSubmitted += sessionData.totalWordsSubmitted
        
        // Update highest scoring word if applicable
        if sessionData.highestScoringWordPoints > self.highestScoringWordPoints {
            self.highestScoringWord = sessionData.highestScoringWord
            self.highestScoringWordPoints = sessionData.highestScoringWordPoints
        }
        
        // Update longest word if applicable
        if sessionData.longestWord.count > self.longestWord.count {
            self.longestWord = sessionData.longestWord
            self.longestWordPoints = sessionData.longestWordPoints
        }
        
        // Save the updated statistics immediately
        saveUserStatistics()
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
                // Optionally report level-based achievements here
            }
            if score > highestScore {
                highestScore = score
                reportHighScoreToGameCenter(score: score)
            }
        }
    
    private func reportHighScoreToGameCenter(score: Int) {
        let leaderboards: [String] = ["allTimeHighScoreLeaderboard", "recurringHighScoreLeaderboard"]
        GameCenterManager.shared.submitScore(score, for: leaderboards)
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
        // Don't reset login streak or last played date when resetting game stats
        print("User statistics have been reset.")
    }
    
    /**
     * Updates the login streak based on the current date and last played date.
     * - If this is the first time playing, initializes values
     * - If playing on the same day, does nothing to the streak
     * - If playing on consecutive days, increments the streak
     * - If more than one day has passed, resets the streak to 1
     */
    func updateLoginStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        // If this is the first time playing, initialize values
        if lastPlayedDate == nil {
            lastPlayedDate = today
            loginStreak = 1
            print("First time playing, initialized login streak to 1")
            return
        }
        
        guard let lastPlayed = lastPlayedDate else { return }
        
        // Check if the last played date is from a different day
        if !calendar.isDate(lastPlayed, inSameDayAs: today) {
            // Calculate days between
            if let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastPlayed), 
                                                       to: calendar.startOfDay(for: today)).day {
                if daysBetween == 1 {
                    // Consecutive day, increment streak
                    loginStreak += 1
                    print("Consecutive day login! Streak increased to \(loginStreak)")
                } else {
                    // Not consecutive, reset streak
                    loginStreak = 1
                    print("Non-consecutive login after \(daysBetween) days. Streak reset to 1")
                }
            }
        } else {
            print("Already played today. Streak remains at \(loginStreak)")
        }
        
        // Always update the last played date
        lastPlayedDate = today
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
