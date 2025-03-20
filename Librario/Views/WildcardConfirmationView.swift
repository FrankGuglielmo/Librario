//
//  WildcardConfirmationView.swift
//  Librario
//
//  Created on 3/19/2025.
//

import SwiftUI

struct WildcardConfirmationView: View {
    @Bindable var gameManager: GameManager
    
    var body: some View {
        if let fromTile = gameManager.selectedWildcardTile,
           let toLetter = gameManager.targetWildcardLetter {
            
            // Create a representation of what the new tile will look like
            let toTileImageName = "\(fromTile.type.rawValue)-tile-\(toLetter)"
            
            CardView(cards: [
                Card(
                    title: "Confirm Change",
                    subtitle: "Change this tile's letter?",
                    cardColor: .sapphire,
                    tabIcon: "sparkles",
                    isCloseDisabled: true,
                    buttons: [
                        CardButton(
                            title: "Confirm",
                            cardColor: .sapphire,
                            action: {
                                gameManager.confirmWildcardChange()
                            }
                        ),
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
                        HStack(spacing: 40) {
                            VStack {
                                Text("From")
                                    .foregroundColor(.white)
                                Image(fromTile.imageName)
                                    .resizable()
                                    .frame(width: 60, height: 60)
                            }
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            
                            VStack {
                                Text("To")
                                    .foregroundColor(.white)
                                Image(toTileImageName)
                                    .resizable()
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
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
    gameManager.targetWildcardLetter = "B"
    
    return WildcardConfirmationView(gameManager: gameManager)
}
