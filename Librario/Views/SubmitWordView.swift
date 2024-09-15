//
//  SubmitWordView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/26/24.
//


import SwiftUI
import Foundation

struct SubmitWordView: View {
    @ObservedObject var tileManager: TileManager
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        // Conditionally show and make clickable the submit word bubble
        Button(action: {
            // Handle word submission
            if gameManager.submitWord() {
                print("Good Word!")
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(radius: 5)
                    .opacity(!tileManager.selectedTiles.isEmpty ? 1 : 0) // Visible when there are selected tiles
                
                VStack(spacing: 8) {
                    // Display the selected tiles or the combined word if validated
                    HStack {
                        if tileManager.validateWord() {
                            // Combine letters into a single word, handling "Qu" properly
                            Text(formatSelectedTilesForWord(tiles: tileManager.selectedTiles))
                                .font(.title)
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)
                        } else {
                            // Show individual letters as separate tiles
                            ForEach(tileManager.selectedTiles, id: \.id) { tile in
                                if tile.letter.uppercased() == "QU" {
                                    // Handle the "Qu" tile separately as "Q" and "U"
                                    Text("Q")
                                        .font(.title)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 2)
                                    Text("U")
                                        .font(.title)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 2)
                                } else {
                                    Text(tile.letter.uppercased())
                                        .font(.title)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 4)
                                }
                            }
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
        .disabled(gameManager.gameState.gameOver || tileManager.selectedTiles.isEmpty) // Disable button if no tiles are selected
        .buttonStyle(PlainButtonStyle()) // Ensure the button doesn't have default styling
    }
    
    // Helper function to format the selected tiles into a combined word with correct handling of "Qu"
    func formatSelectedTilesForWord(tiles: [Tile]) -> String {
        tiles.map { tile in
            if tile.letter.uppercased() == "QU" {
                return "Q U" // Treat "Qu" as "Q U" for display
            } else {
                return tile.letter.uppercased() // Default behavior for other tiles
            }
        }.joined(separator: " ") // Join with a space for better spacing in the word
    }
}



#Preview {
    // Mock data for preview
    let mockDictionaryManager = DictionaryManager()
    let mockGameManager = GameManager(dictionaryManager: mockDictionaryManager)
    
    // Set up some sample tiles based on the provided Tile structure
    let sampleTiles = [
        Tile(letter: "B", type: .regular, points: 1, position: Position(row: 0, column: 0), isPlaceholder: false),
        Tile(letter: "A", type: .green, points: 2, position: Position(row: 0, column: 1), isPlaceholder: false),
        Tile(letter: "D", type: .gold, points: 3, position: Position(row: 0, column: 2), isPlaceholder: false)
    ]
    mockGameManager.tileManager.selectedTiles = sampleTiles
    
    return SubmitWordView(tileManager: mockGameManager.tileManager, gameManager: mockGameManager)
}
