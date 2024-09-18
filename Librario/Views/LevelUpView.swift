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

    var body: some View {
        VStack {
            Text("Level Complete!")
                .foregroundColor(.black)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            VStack {
                VStack {
                    Text("Longest Word:")
                        .foregroundStyle(.black)
                        .font(.title2)
                    Text(gameManager.levelData.longestWord)
                        .foregroundStyle(.blue)
                    Text("(\(gameManager.levelData.longestWordPoints))")
                        .foregroundStyle(.blue)
                }.padding()
                
                VStack {
                    Text("Highest Scoring Word:")
                        .foregroundStyle(.black)
                        .font(.title2)
                    Text(gameManager.levelData.highestScoringWord)
                        .foregroundStyle(.blue)
                    Text("(\(gameManager.levelData.highestScoringWordPoints))")
                        .foregroundStyle(.blue)
                }.padding()

                Text("Words Submitted: \(gameManager.levelData.wordsSubmitted)")
                    .foregroundColor(.black)
                    .font(.title2)
                    .padding()
            }
            .padding()
            


            Button(action: {
                gameManager.handleLevelCompletion()
                gameManager.resetLevelStatistics()
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .frame(width: 300, height: 500)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
        .transition(.scale)
    }
}

//#Preview {
//    let mockGameManager = GameManager(dictionaryManager: DictionaryManager())
//    let mockNavigationPath = NavigationPath()
//
//    // Mock level statistics
//    mockGameManager.levelData.wordsSubmitted = 3
//    mockGameManager.levelData.longestWord = "BOOKWORM"
//    mockGameManager.levelData.longestWordPoints = 750
//    mockGameManager.levelData.highestScoringWord = "ZEBRA"
//    mockGameManager.levelData.highestScoringWordPoints = 800
//    
//
//    return LevelUpView(gameManager: mockGameManager, navigationPath: .constant(mockNavigationPath))
//}
