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
    @Bindable var userData: UserData
    @Binding var navigationPath: NavigationPath
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let popupWidth = isCompact ? geometry.size.width * 0.9 : geometry.size.width * 0.8
            let popupHeight = isCompact ? geometry.size.height * 0.9 : geometry.size.height * 0.9

            ZStack {
                // Background image filling the entire safe area
                Image("red_curtain")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Stats popup container centered within the GeometryReader
                ZStack {
                    // Background Popup Image
                    Image("StatPopup")
                        .resizable()
                        .scaledToFit()
                        .frame(width: popupWidth, height: popupHeight)

                    VStack(spacing: popupWidth * 0.04) {

                        VStack(alignment: .leading, spacing: popupWidth * 0.025) {
                            // Longest Word
                            statView(
                                title: "Longest Word",
                                value: userData.userStatistics.longestWord.isEmpty ? "N/A" : userData.userStatistics.longestWord.uppercased(),
                                iconName: "textformat",
                                iconColor: .blue,
                                popupWidth: popupWidth
                            )

                            // Highest Scoring Word
                            statView(
                                title: "Highest Scoring Word",
                                value: userData.userStatistics.highestScoringWord.isEmpty ? "N/A" : userData.userStatistics.highestScoringWord.uppercased(),
                                iconName: "star.fill",
                                iconColor: .yellow,
                                popupWidth: popupWidth
                            )

                            // Total Words Submitted
                            statView(
                                title: "Total Words Submitted",
                                value: "\(userData.userStatistics.totalWordsSubmitted)",
                                iconName: "checkmark.circle.fill",
                                iconColor: .green,
                                popupWidth: popupWidth
                            )

                            // Total Games Played
                            statView(
                                title: "Total Games Played",
                                value: "\(userData.userStatistics.totalGamesPlayed)",
                                iconName: "gamecontroller.fill",
                                iconColor: .purple,
                                popupWidth: popupWidth
                            )
                            
                            statView(title: "Total Time Played", value: userData.userStatistics.timePlayed.formattedCompact, iconName: "clock", iconColor: .gray, popupWidth: popupWidth)

                            // Lifetime Average Word Length
                            statView(
                                title: "Avg Word Length",
                                value: String(format: "%.2f", userData.userStatistics.averageWordLength),
                                iconName: "text.alignleft",
                                iconColor: .orange,
                                popupWidth: popupWidth
                            )
                        }
                        .padding(.horizontal, popupWidth * 0.05)
                        .padding(.vertical, popupHeight * 0.02)

                        // Back button using the BackButton image
                        Button(action: {
                            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                            navigationPath.removeLast()
                        }) {
                            Image("BackButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: popupWidth * 0.5)
                                
                        }
                    }
                    .frame(width: popupWidth * 0.85, height: popupHeight * 0.85)
                }
                // Position the stats popup container at the center of the GeometryReader
                .frame(width: popupWidth, height: popupHeight)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    // A reusable function to create a stat view with icons
    private func statView(title: String, value: String, iconName: String, iconColor: Color, popupWidth: CGFloat) -> some View {
        HStack(alignment: .center, spacing: popupWidth * 0.025) {
            Image(systemName: iconName)
                .resizable()
                .foregroundColor(iconColor)
                .frame(width: popupWidth * 0.12, height: popupWidth * 0.12)

            VStack(alignment: .leading, spacing: popupWidth * 0.005) {
                Text("\(title):")
                    .font(.system(size: popupWidth * 0.045, weight: .semibold))
                    .foregroundColor(.white)
                Text(value)
                    .font(.system(size: popupWidth * 0.050))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, popupWidth * 0.015)
    }
}


//#Preview {
//    let mockUserStatistics = UserStatistics()
//    mockUserStatistics.longestWord = "Elephant"
//    mockUserStatistics.highestScoringWord = "Zebra"
//    mockUserStatistics.totalWordsSubmitted = 1234
//    mockUserStatistics.totalGamesPlayed = 56
//    
//    let userData = UserData(userStatistics: mockUserStatistics)
//    
//    return StatsView(navigationPath: .constant(NavigationPath()))
//        .environmentObject(userData)
//}
