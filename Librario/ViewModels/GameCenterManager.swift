//
//  GameCenterManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 10/9/24.
//

import GameKit
import SwiftUI
import Observation

@Observable
class GameCenterManager {
    static let shared = GameCenterManager()
    
    var userStatistics: UserStatistics? // Reference to UserStatistics to update score when authenticated

    // This automatically behaves like a @Published property
    var isAuthenticated = false

    private init() {
        authenticateUser()
    }

    func authenticateUser() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { gcAuthVC, error in
            if let vc = gcAuthVC {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true, completion: nil)
                }
            } else if localPlayer.isAuthenticated {
                self.isAuthenticated = true
                print("Game Center authentication successful.")
                
                // Submit high score after authentication
                if let highScore = self.userStatistics?.highestScore {
                    self.submitScore(highScore, for: ["allTimeHighScoreLeaderboard", "recurringHighScoreLeaderboard"])
                }
            } else {
                self.isAuthenticated = false
                if let error = error {
                    print("Game Center authentication failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // Submit a score to a leaderboard
    func submitScore(_ score: Int, for leaderboardIDs: [String]) {
        guard isAuthenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: leaderboardIDs) { error in
            if let error = error {
                print("Error submitting score: \(error.localizedDescription)")
            } else {
                print("Score submitted successfully.")
            }
        }
    }

    // Report an achievement
    func reportAchievement(identifier: String, percentComplete: Double) {
        guard isAuthenticated else { return }

        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true

        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Error reporting achievement: \(error.localizedDescription)")
            } else {
                print("Achievement reported to Game Center.")
            }
        }
    }
    
    func fetchLeaderboards() async {
        do {
            // Fetch leaderboards by IDs
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: ["all_time_high_score_leaderboard", "recurringHighScoreLeaderboard"])
            
            for leaderboard in leaderboards {
                let result = try await leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSMakeRange(1, 10))
                
                print("Leaderboard: \(String(describing: leaderboard.title))")
                for entry in result.1 { // result.1 is the leaderboard entries
                    print("Player: \(entry.player.alias), Score: \(entry.score)")
                }
            }
        } catch {
            print("Error fetching leaderboards: \(error.localizedDescription)")
        }
    }


}
