//
//  GameOverView.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/8/24.
//

import SwiftUI

struct GameOverView: View {
    @Bindable var gameManager: GameManager
    @Bindable var userData: UserData
    @Binding var navigationPath: NavigationPath

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let popupWidth = isCompact ? geometry.size.width * 0.8 : geometry.size.width * 0.5
            let popupHeight = isCompact ? geometry.size.height * 0.7 : geometry.size.height * 0.5
            let dynamicFontSize: CGFloat = isCompact ? popupWidth * 0.1 : popupWidth * 0.06

            ZStack {
                Image("GameOverPopup")
                    .resizable()
                    .scaledToFit()
                    .frame(width: popupWidth, height: popupHeight)

                VStack {
                    Spacer()

                    // Score display
                    VStack(spacing: 5) {
                        Text("Your score:")
                            .font(.system(size: dynamicFontSize * 0.9, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(userData.userStatistics.highestScore)")
                            .font(.system(size: dynamicFontSize * 0.9))
                            .foregroundColor(.blue)
                    }
                    .padding(.top)

                    Spacer()

                    // Best Word display
                    VStack(spacing: 5) {
                        Text("Best Word:")
                            .font(.system(size: dynamicFontSize * 0.9, weight: .bold))
                            .foregroundColor(.white)
                        Text(gameManager.sessionData.highestScoringWord.isEmpty ? "N/A" : gameManager.sessionData.highestScoringWord.uppercased())
                            .font(.system(size: dynamicFontSize * 0.9))
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    // Longest Word display
                    VStack(spacing: 5) {
                        Text("Longest Word:")
                            .font(.system(size: dynamicFontSize * 0.9, weight: .bold))
                            .foregroundColor(.white)
                        Text(gameManager.sessionData.longestWord.isEmpty ? "N/A" : gameManager.sessionData.longestWord.uppercased())
                            .font(.system(size: dynamicFontSize * 0.9))
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    // Custom Restart Game button image
                    Button(action: {
                        // Reset game logic
                        gameManager.startNewGame(userStatistics: userData.userStatistics)
                        print("Game restarted")
                    }) {
                        Image("RestartButton") // Replace with your custom image name
                            .resizable()
                            .scaledToFit()
                            .frame(width: popupWidth * 0.5) // Adjust size to fit your needs
                    }

                    // Custom Exit button image
                    Button(action: {
                        if !navigationPath.isEmpty {
                            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                            navigationPath.removeLast() // Simulate exit by removing the last item in the navigation path
                            print("Exit to main menu")
                        }
                    }) {
                        Image("ExitButton") // Replace with your custom image name
                            .resizable()
                            .scaledToFit()
                            .frame(width: popupWidth * 0.5) // Adjust size to fit your needs
                    }

                    Spacer()
                }
                .frame(width: popupWidth * 0.85, height: popupHeight * 0.85)
            }
            .frame(width: popupWidth, height: popupHeight)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    struct GameOverView_Previews: PreviewProvider {
        static var previews: some View {
            let gameManager = GameManager(dictionaryManager: DictionaryManager())
            let userData = UserData.loadUserData()
            let navigationPath = NavigationPath()
            GameOverView(gameManager: gameManager, userData: userData, navigationPath: .constant(navigationPath))
        }
    }
}
