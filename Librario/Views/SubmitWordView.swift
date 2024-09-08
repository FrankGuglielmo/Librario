//
//  SubmitWordView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/26/24.
//

import SwiftUI

struct SubmitWordView: View {
    @EnvironmentObject var dictionaryManager: DictionaryManager
    @ObservedObject var gameState: GameState
    @ObservedObject var tileManager: TileManager
    
    var body: some View {
        // Conditionally show and make clickable the submit word bubble
            Button(action: {
                // Handle word submission
                if gameState.submitWord() {
                    print("Good Word!")
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(radius: 5)
                        .opacity(!tileManager.selectedTiles.isEmpty ? 1 : 0) // Visible when there are selected tiles
                    
                    VStack(spacing: 8) {
                        // Display the selected tiles
                        HStack {
                            ForEach(tileManager.selectedTiles, id: \.id) { tile in
                                Text(tile.letter.uppercased())
                                    .font(.title)
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
            }
            .disabled(gameState.gameOver || tileManager.selectedTiles.isEmpty) // Disable button if no tiles are selected
            .buttonStyle(PlainButtonStyle()) // Ensure the button doesn't have default styling
        }
}


#Preview {
    SubmitWordView(gameState: GameState(dictionaryManager: DictionaryManager()), tileManager: TileManager(tileGenerator: TileGenerator(letterGenerator: LetterGenerator(), tileTypeGenerator: TileTypeGenerator()), tileConverter: TileConverter(), wordChecker: WordChecker(wordStore: [:])))
}
