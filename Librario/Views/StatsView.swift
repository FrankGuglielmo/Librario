//
//  StatsView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/31/24.
//

//
//  StatsView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/31/24.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var userData: UserData
    @Binding var navigationPath: NavigationPath

    var body: some View {
        ZStack {
            // Background color filling the entire safe area
            Image("red_curtain")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Player Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                VStack(alignment: .leading, spacing: 15) {
                    // Longest Word
                    statView(title: "Longest Word", value: userData.userStatistics.longestWord.isEmpty ? "N/A" : userData.userStatistics.longestWord, icon: "textformat")
                    
                    // Highest Scoring Word
                    statView(title: "Highest Scoring Word", value: userData.userStatistics.highestScoringWord.isEmpty ? "N/A" : userData.userStatistics.highestScoringWord, icon: "star.fill")
                    
                    // Total Words Submitted
                    statView(title: "Total Words Submitted", value: "\(userData.userStatistics.totalWordsSubmitted)", icon: "checkmark.circle.fill")
                    
                    // Total Games Played
                    statView(title: "Total Games Played", value: "\(userData.userStatistics.totalGamesPlayed)", icon: "gamecontroller.fill")
                    
                    // Lifetime Average Word Length
                    statView(title: "Avg Word Length", value: String(format: "%.2f", userData.userStatistics.averageWordLength), icon: "text.alignleft")
                }
                .padding()
                
                
                // Back Button
                Button(action: {
                    navigationPath.removeLast() // Navigate back to the previous view
                }, label: {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.title)
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundColor(.secondary)
                })
                .padding()
            }
            .padding()
            .background(Color(.systemBackground).cornerRadius(15))
            .shadow(radius: 10)
        }
    }
    
    // A reusable function to create a stat view with icons
    private func statView(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(Color.blue)
            
            VStack(alignment: .leading) {
                Text("\(title):")
                    .font(.headline)
                Text(value)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let mockUserStatistics = UserStatistics()
    mockUserStatistics.longestWord = "Elephant"
    mockUserStatistics.highestScoringWord = "Zebra"
    mockUserStatistics.totalWordsSubmitted = 1234
    mockUserStatistics.totalGamesPlayed = 56
    
    let userData = UserData(userStatistics: mockUserStatistics)
    
    return StatsView(navigationPath: .constant(NavigationPath()))
        .environmentObject(userData)
}
