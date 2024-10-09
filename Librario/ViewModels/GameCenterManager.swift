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

    // This automatically behaves like a @Published property
    var isAuthenticated = false

    private init() {
        authenticateUser()
    }

    func authenticateUser() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { gcAuthVC, error in
            if let vc = gcAuthVC {
                // Present the authentication view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true, completion: nil)
                }

            } else if localPlayer.isAuthenticated {
                self.isAuthenticated = true
                print("Game Center authentication successful.")
            } else {
                self.isAuthenticated = false
                if let error = error {
                    print("Game Center authentication failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // Submit a score to a leaderboard
    func submitScore(_ score: Int, for leaderboardID: String) {
        guard isAuthenticated else { return }

        let scoreReporter = GKLeaderboardScore()
        scoreReporter.leaderboardID = leaderboardID
        scoreReporter.value = score

        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Error submitting score: \(error.localizedDescription)")
            } else {
                print("Submitted score of \(score) to Game Center.")
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
}
