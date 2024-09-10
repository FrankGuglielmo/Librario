//
//  GameOverView.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/8/24.
//

import SwiftUI

struct GameOverView: View {
    @ObservedObject var gameState: GameState
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack {
            Text("Game Over!")
                .foregroundStyle(Color.black)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text("Your score: \(gameState.score)")
                .foregroundStyle(Color.black)
                .font(.title)
                .padding()

            Button(action: {
                // Restart the game by resetting the gameState
                gameState.startNewGame() // This resets the game over flag and restarts the game
            }) {
                Text("Restart Game")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()

            Button(action: {
                // Exit the game and return to the home screen by clearing the navigation path
                if !navigationPath.isEmpty {
                    navigationPath.removeLast() // Pop the current view from the navigation path
                    gameState.startNewGame() // This resets the game over flag and
                }
                
            }) {
                Text("Exit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
        .frame(width: 300, height: 400)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
        .transition(.scale)
    }
}

#Preview {
    GameOverView(gameState: GameState(dictionaryManager: DictionaryManager()), navigationPath: .constant(NavigationPath()))
}

