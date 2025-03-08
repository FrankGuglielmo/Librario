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
        let gameOverCard = Card(
            title: "Game Over!",
            subtitle: "Your game has ended. Here's how you did:",
            cardColor: .crimson,
            isCloseDisabled: true,
            buttons: [
                CardButton(
                    title: "Restart",
                    cardColor: .crimson,
                    action: {
                        // Reset game logic
                        gameManager.startNewGame(userStatistics: userData.userStatistics)
                        // Set gameplay state back to active
                        gameManager.gameplayState = .active
                        print("Game restarted")
                    }
                ),
                CardButton(
                    title: "Exit",
                    cardColor: .crimson,
                    action: {
                        if !navigationPath.isEmpty {
                            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                            gameManager.startNewGame(userStatistics: userData.userStatistics)
                            gameManager.gameplayState = .active
                            navigationPath.removeLast() // Simulate exit by removing the last item in the navigation path
                            print("Exit to main menu")
                        }
                    }
                )
            ]
        ) {
            VStack(spacing: 16) {
                // Score display
                VStack(spacing: 5) {
                    Text("Your score:")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(userData.userStatistics.highestScore)")
                        .font(.title)
                        .foregroundColor(CardColor.crimson.complementaryColor)
                }
                
                // Best Word display
                VStack(spacing: 5) {
                    Text("Best Word:")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(gameManager.sessionData.highestScoringWord.isEmpty ? "N/A" : gameManager.sessionData.highestScoringWord.uppercased())
                        .font(.title2)
                        .foregroundColor(CardColor.crimson.complementaryColor)
                }
                
                // Longest Word display
                VStack(spacing: 5) {
                    Text("Longest Word:")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(gameManager.sessionData.longestWord.isEmpty ? "N/A" : gameManager.sessionData.longestWord.uppercased())
                        .font(.title2)
                        .foregroundColor(CardColor.crimson.complementaryColor)
                }
            }
        }
        
        CardView(cards: [gameOverCard])
            .onAppear {
                // Set gameplay state to game over
                gameManager.gameplayState = .gameOver
                // Stop the game timer and update statistics
                gameManager.stopGameTimer()
                // Update user statistics directly with the current userData
                gameManager.updateUserLifetimeStatistics(userData: userData)
            }
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
