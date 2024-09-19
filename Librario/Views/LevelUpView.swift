//
//  LevelUpView.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/10/24.
//

import SwiftUI

struct LevelUpView: View {
    @ObservedObject var gameManager: GameManager
    @Binding var navigationPath: NavigationPath
    var onDismiss: () -> Void // Callback for when the user presses continue
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let popupWidth = isCompact ? geometry.size.width * 0.8 : geometry.size.width * 0.5
            let popupHeight = isCompact ? geometry.size.height * 0.7 : geometry.size.height * 0.6
            let dynamicFontSize: CGFloat = isCompact ? popupWidth * 0.07 : popupWidth * 0.06

                // LevelUp popup container centered within the GeometryReader
                ZStack {
                    // Background Popup Image for LevelUp
                    Image("LevelUpPopup")
                        .resizable()
                        .scaledToFit()
                        .frame(width: popupWidth, height: popupHeight)

                    VStack {
                        Spacer()

                        // Longest Word Display
                        VStack(spacing: 5) {
                            Text("Longest Word:")
                                .font(.system(size: dynamicFontSize, weight: .bold))
                                .foregroundColor(.white)
                            Text(gameManager.levelData.longestWord.isEmpty ? "N/A" : gameManager.levelData.longestWord.uppercased())
                                .font(.system(size: dynamicFontSize * 0.9))
                                .foregroundColor(.white)
                            Text("(\(gameManager.levelData.longestWordPoints))")
                                .font(.system(size: dynamicFontSize * 0.9))
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        // Highest Scoring Word Display
                        VStack(spacing: 5) {
                            Text("Highest Scoring Word:")
                                .font(.system(size: dynamicFontSize, weight: .bold))
                                .foregroundColor(.white)
                            Text(gameManager.levelData.highestScoringWord.isEmpty ? "N/A" : gameManager.levelData.highestScoringWord.uppercased())
                                .font(.system(size: dynamicFontSize * 0.9))
                                .foregroundColor(.white)
                            Text("(\(gameManager.levelData.highestScoringWordPoints))")
                                .font(.system(size: dynamicFontSize * 0.9))
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        // Words Submitted Display
                        Text("Words Submitted: \(gameManager.levelData.wordsSubmitted)")
                            .font(.system(size: dynamicFontSize))
                            .foregroundColor(.white)
                            .fontWeight(.bold)

                        Spacer()

                        // Custom Continue button image
                        Button(action: {
                            gameManager.handleLevelCompletion()
                            gameManager.resetLevelStatistics()
                            onDismiss() // Call the dismiss action to hide the view
                            print("Continue to next level")
                        }) {
                            Image("ContinueButton") // Replace with your custom continue button image
                                .resizable()
                                .scaledToFit()
                                .frame(width: popupWidth * 0.5) // Adjust size as needed
                        }

                        Spacer()
                    }
                    .frame(width: popupWidth * 0.85, height: popupHeight * 0.85)
                }
                // Position the LevelUp popup container at the center of the GeometryReader
                .frame(width: popupWidth, height: popupHeight)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

