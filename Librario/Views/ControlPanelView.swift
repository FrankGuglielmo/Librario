//
//  ControlPanelView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import SwiftUI

struct ControlPanelView: View {
    @EnvironmentObject var dictionaryManager: DictionaryManager
    @ObservedObject var gameState: GameState
    @ObservedObject var tileManager: TileManager

    var body: some View {
        VStack {
            // Display the selected tiles
            HStack {
                ForEach(gameState.tileManager.selectedTiles, id: \.id) { tile in
                    Text(tile.letter)
                        .font(.largeTitle)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()

            // Control buttons
            HStack {
                Button(action: {
                    if gameState.submitWord() {
                        print("Good word!")
                    } else {
                        print("Bad word")
                    }
                }) {
                    Text("Submit Word")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()

                Button(action: {
                    gameState.startNewGame()
                }) {
                    Text("New Game")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}
