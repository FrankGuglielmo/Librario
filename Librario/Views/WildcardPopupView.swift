//
//  WildcardPopupView.swift
//  Librario
//
//  Created on 3/19/2025.
//

import SwiftUI

struct WildcardPopupView: View {
    @Bindable var gameManager: GameManager
    // Including "Qu" and all other letters
    let allLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
                      "N", "O", "P", "Q", "Qu", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    var body: some View {
        if let selectedTile = gameManager.selectedWildcardTile {
            CardView(cards: [
                Card(
                    title: "Choose a Letter",
                    subtitle: "Select a new letter for this tile",
                    cardColor: .sapphire,
                    tabIcon: "sparkles",
                    isCloseDisabled: true,
                    buttons: [
                        CardButton(
                            title: "Cancel",
                            cardColor: .sapphire,
                            action: {
                                gameManager.exitWildcardMode()
                            }
                        )
                    ]
                ) {
                    VStack(spacing: 20) {
                        // Show the selected tile
                        VStack {
                            Text("Selected Tile")
                                .foregroundColor(.white)
                            Image(selectedTile.imageName)
                                .resizable()
                                .frame(width: 60, height: 60)
                        }
                        
                        // Grid of letter tiles (5 columns)
                        let tileType = selectedTile.type
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            // Filter out the current letter
                            ForEach(allLetters.filter { $0 != selectedTile.letter }, id: \.self) { letter in
                                Button(action: {
                                    gameManager.selectWildcardLetter(letter: letter)
                                }) {
                                    // Create a tile image with the same type but different letter
                                    Image("\(tileType.rawValue)-tile-\(letter)")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                }
                            }
                        }
                        .padding()
                        
                        Text("This will use 1 Wildcard powerup")
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                }
            ])
        }
    }
}

#Preview {
    let gameManager = GameManager(dictionaryManager: DictionaryManager())
    gameManager.isInWildcardMode = true
    
    // Create a mock tile for preview
    var tile = Tile(letter: "A", type: .regular, points: 1, position: Position(row: 0, column: 0), isPlaceholder: false)
    gameManager.selectedWildcardTile = tile
    
    return WildcardPopupView(gameManager: gameManager)
}
