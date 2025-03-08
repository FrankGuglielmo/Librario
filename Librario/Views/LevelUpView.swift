//
//  LevelUpView.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/10/24.
//

import SwiftUI

struct LevelUpView: View {
    @Bindable var gameManager: GameManager
    @Bindable var userData: UserData
    @Binding var navigationPath: NavigationPath
    var onDismiss: () -> Void // Callback for when the user presses continue
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        let levelUpCard = Card(
            title: "Level Up!",
            subtitle: "Congratulations on completing level \(gameManager.gameState.level)!",
            cardColor: .crimson,
            isCloseDisabled: true,
            buttons: [
                CardButton(
                    title: "Continue",
                    cardColor: .crimson,
                    action: {
                        gameManager.handleLevelCompletion()
                        gameManager.resetLevelStatistics()
                        // Set gameplay state back to active
                        gameManager.gameplayState = .active
                        // Resume the game timer
                        gameManager.resumeGameTimer()
                        onDismiss() // Call the dismiss action to hide the view
                    }
                )
            ]
        ) {
            VStack(spacing: 16) {
                // Longest Word Display
                VStack(spacing: 5) {
                    Text("Longest Word:")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(gameManager.levelData.longestWord.isEmpty ? "N/A" : gameManager.levelData.longestWord.uppercased())
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("(\(gameManager.levelData.longestWordPoints))")
                        .font(.subheadline)
                        .foregroundColor(CardColor.crimson.complementaryColor)
                }
                
                // Highest Scoring Word Display
                VStack(spacing: 5) {
                    Text("Highest Scoring Word:")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(gameManager.levelData.highestScoringWord.isEmpty ? "N/A" : gameManager.levelData.highestScoringWord.uppercased())
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("(\(gameManager.levelData.highestScoringWordPoints))")
                        .font(.subheadline)
                        .foregroundColor(CardColor.crimson.complementaryColor)
                }
                
                // Words Submitted Display
                Text("Words Submitted: \(gameManager.levelData.wordsSubmitted)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
            }
        }
        
        CardView(cards: [levelUpCard])
            .onAppear {
                // Set gameplay state to level transition
                gameManager.gameplayState = .levelTransition
                // Pause the game timer
                gameManager.pauseGameTimer()
                // Update user statistics directly with the current userData
                gameManager.updateUserLifetimeStatistics(userData: userData)
            }
    }
}

struct LevelUpView_Previews: PreviewProvider {
    static var previews: some View {
        LevelUpView(
            gameManager: mockGameManager(),
            userData: UserData(),
            navigationPath: .constant(NavigationPath()),
            onDismiss: {}
        )
        .previewLayout(.sizeThatFits)
        .environment(\.horizontalSizeClass, .compact) // You can toggle between compact and regular here
    }

    // Mock GameManager for preview purposes
    static func mockGameManager() -> GameManager {
        let gameManager = GameManager(dictionaryManager: DictionaryManager()) // Adjust with your initializer
        gameManager.levelData = LevelStatistics()
        return gameManager
    }
}
