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
                // Only show the bubble if there are selected tiles
                if true {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .frame(width: 300, height: 150)
                            .shadow(radius: 5)
                        
                        VStack(spacing: 8) {
                            // Display the selected tiles
                            HStack {
                                ForEach(tileManager.selectedTiles, id: \.id) { tile in
                                    Text(tile.letter)
                                        .font(.largeTitle)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 4)
                                }
                            }
                            
                            // Conditionally display the score and "TAP TO SUBMIT" if the word is valid
                            if tileManager.validateWord() {
                                HStack {
                                    Text("+")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                    Text("\(tileManager.getScore())")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                        .fontWeight(.bold)
                                }
                                
                                Text("TAP TO SUBMIT")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                }

                // Control buttons
                HStack {
                    if tileManager.validateWord() {
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
                .background(Color.blue)
                .padding()
            }
            .background(Color.red)
            .padding()
        }
}


#Preview {
    ControlPanelView(gameState: GameState(dictionaryManager: DictionaryManager()), tileManager: TileManager(tileGenerator: TileGenerator(letterGenerator: LetterGenerator(), tileTypeGenerator: TileTypeGenerator()), tileConverter: TileConverter(), wordChecker: WordChecker(wordStore: [:])))
}
