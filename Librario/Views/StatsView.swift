//
//  StatsView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/31/24.
//

import SwiftUI
import GameKit

struct StatsView: View {
    @Bindable var userData: UserData
    @Binding var navigationPath: NavigationPath
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var gameCenterManager = GameCenterManager.shared
    @State private var showGameCenter = false
    
    var body: some View {
        // Statistics Card
        let statsCard = Card(
            title: "Statistics",
            cardColor: .crimson,
            tabIcon: "chart.bar.fill"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Longest Word
                statView(
                    title: "Longest Word",
                    value: userData.userStatistics.longestWord.isEmpty ? "N/A" : userData.userStatistics.longestWord.uppercased(),
                    iconName: "textformat",
                    iconColor: .blue
                )

                // Highest Scoring Word
                statView(
                    title: "Highest Scoring Word",
                    value: userData.userStatistics.highestScoringWord.isEmpty ? "N/A" : userData.userStatistics.highestScoringWord.uppercased(),
                    iconName: "star.fill",
                    iconColor: .yellow
                )

                // Total Words Submitted
                statView(
                    title: "Total Words Submitted",
                    value: "\(userData.userStatistics.totalWordsSubmitted)",
                    iconName: "checkmark.circle.fill",
                    iconColor: .green
                )

                // Total Games Played
                statView(
                    title: "Total Games Played",
                    value: "\(userData.userStatistics.totalGamesPlayed)",
                    iconName: "gamecontroller.fill",
                    iconColor: .purple
                )

                // Highest Level
                statView(
                    title: "Highest Level",
                    value: "\(userData.userStatistics.highestLevel)",
                    iconName: "flag.fill",
                    iconColor: .red
                )

                // Highest Score
                statView(
                    title: "Highest Score",
                    value: "\(userData.userStatistics.highestScore)",
                    iconName: "rosette",
                    iconColor: .orange
                )

                // Total Time Played
                statView(
                    title: "Total Time Played",
                    value: userData.userStatistics.timePlayed.formattedCompact,
                    iconName: "clock",
                    iconColor: .gray
                )

                // Lifetime Average Word Length
                statView(
                    title: "Avg Word Length",
                    value: String(format: "%.2f", userData.userStatistics.averageWordLength),
                    iconName: "text.alignleft",
                    iconColor: .orange
                )
                
                // Last Played Date
                statView(
                    title: "Last Played",
                    value: userData.userStatistics.lastPlayedDate?.formatted(date: .abbreviated, time: .omitted) ?? "Today",
                    iconName: "calendar",
                    iconColor: .blue
                )
                
                // Login Streak
                statView(
                    title: "Login Streak",
                    value: "\(userData.userStatistics.loginStreak) day\(userData.userStatistics.loginStreak == 1 ? "" : "s")",
                    iconName: "flame.fill",
                    iconColor: .orange
                )
            }
            .padding(.horizontal)
        }
        
        // Game Center Leaderboards Card
        let leaderboardsCard = Card(
            title: "Game Center Leaderboards",
            subtitle: "Compare your scores with players worldwide",
            cardColor: .amethyst,
            tabIcon: "trophy.fill"
        ) {
            VStack(spacing: 20) {
                if gameCenterManager.isAuthenticated {
                    // User is authenticated with Game Center
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.yellow)
                        
                        Text("View your rankings and compare scores with players around the world!")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            presentGameCenterDashboard()
                        }) {
                            Text("Open Game Center")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(CardColor.amethyst.accentColor)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    // User is not authenticated with Game Center
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(CardColor.amethyst.accentColor)
                        
                        Text("Authenticate with Game Center to add your scores to the leaderboard!")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        
                        Text("Open Game Center in your device settings to sign in and enable leaderboards.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
            }
        }
        
        ZStack {
            // Background image filling the entire safe area
            Image("Background_Image_2")
                .resizable()
                .edgesIgnoringSafeArea(.all)

                CardView(cards: [statsCard, leaderboardsCard])
                
        }
        .sheet(isPresented: $showGameCenter) {
            GameCenterView(viewState: .leaderboards)
        }
    }

    // A reusable function to create a stat view with icons
    private func statView(title: String, value: String, iconName: String, iconColor: Color) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: iconName)
                .resizable()
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(title):")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(value)
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Function to present Game Center dashboard
    private func presentGameCenterDashboard() {
        // Get the active window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            // Initialize the Game Center dashboard view controller
            let gameCenterVC = GKGameCenterViewController(state: .leaderboards)
            gameCenterVC.gameCenterDelegate = rootVC as? GKGameCenterControllerDelegate
            
            // Present the Game Center dashboard
            rootVC.present(gameCenterVC, animated: true, completion: nil)
        } else {
            print("Failed to find the root view controller")
        }
    }
}

#Preview {
    let mockUserStatistics = UserStatistics()
    mockUserStatistics.longestWord = "Elephant"
    mockUserStatistics.highestScoringWord = "Zebra"
    mockUserStatistics.totalWordsSubmitted = 1234
    mockUserStatistics.totalGamesPlayed = 56
    mockUserStatistics.timePlayed = 3600
    mockUserStatistics.lastPlayedDate = Date()
    mockUserStatistics.loginStreak = 3

    let userData = UserData(userStatistics: mockUserStatistics)

    return StatsView(userData: userData, navigationPath: .constant(NavigationPath()))
}
