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
    @Bindable var gameManager: GameManager
    
    var body: some View {
        Button(action: {
            // Handle word submission
            gameManager.submitWord()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(radius: 5)
                    .opacity(!tileManager.selectedTiles.isEmpty ? 1 : 0) // Visible when there are selected tiles
                
                VStack(spacing: 8) {
                    HStack {
                        if tileManager.validateWord() {
                            // Combine letters into a single word, handling "Qu" properly
                            Text(formatSelectedTilesForWord(tiles: tileManager.selectedTiles))
                                .font(.title)
                                .foregroundStyle(.black)
                                
                        } else {
                            // Show individual letters as separate tiles
                            ForEach(tileManager.selectedTiles, id: \.id) { tile in
                                if tile.letter.uppercased() == "QU" {
                                    // Handle the "Qu" tile separately as "Q" and "U"
                                    Text("Q")
                                        .font(dynamicFontSize(for: tileManager.selectedTiles.count))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, dynamicPadding(for: tileManager.selectedTiles.count))
                                    Text("U")
                                        .font(dynamicFontSize(for: tileManager.selectedTiles.count))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, dynamicPadding(for: tileManager.selectedTiles.count))
                                } else {
                                    Text(tile.letter.uppercased())
                                        .font(dynamicFontSize(for: tileManager.selectedTiles.count))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, dynamicPadding(for: tileManager.selectedTiles.count))
                                }
                            }
                        }
                    }
                    
                    if tileManager.validateWord() {
                        HStack {
                            Text("+")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text("\(tileManager.getScore())")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                                .fontWeight(.bold)
                        }
                        
                        Text("TAP TO SUBMIT")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .disabled(gameManager.gameOver || tileManager.selectedTiles.isEmpty) // Disable button if no tiles are selected
        .buttonStyle(PlainButtonStyle()) // Ensure the button doesn't have default styling
    }
    
    // Dynamically adjust font size based on the number of selected tiles
    func dynamicFontSize(for tileCount: Int) -> Font {
        switch tileCount {
        case 0...5:
            return .title
        case 6...10:
            return .title3
        default:
            return .body // Smaller font size for more than 15 tiles
        }
    }

    // Dynamically adjust padding based on the number of selected tiles
    func dynamicPadding(for tileCount: Int) -> CGFloat {
        switch tileCount {
        case 0...5:
            return 4
        case 6...10:
            return 2
        default:
            return 0 // No padding for more than 15 tiles
        }
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



