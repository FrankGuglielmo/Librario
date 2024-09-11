//
//  ContentView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import SwiftUI

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var navigationPath: NavigationPath

        var body: some View {
            ZStack {
                // Background color filling the entire safe area
                Image("red_curtain")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0)
                    .edgesIgnoringSafeArea(.all)

                GeometryReader { geometry in
                    VStack {
                        HStack {
                            Image("normal_sprite")
                                .resizable()
                                .frame(width: 142, height: 150)

                            SubmitWordView(tileManager: gameManager.tileManager, gameManager: gameManager)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .padding()
                        .fixedSize(horizontal: false, vertical: true)

                        GameGridView(tileManager: gameManager.tileManager)

                        Button(action: {
                            gameManager.tileManager.scramble() // Trigger the scramble function
                        }) {
                            Text("Scramble Tiles")
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        GameStatusView(gameManager: gameManager, navigationPath: $navigationPath)
                        
                    }
                    .frame(maxHeight: .infinity)
                }

                if gameManager.checkLevelProgression() {
                    LevelUpView(gameManager: gameManager, navigationPath: $navigationPath)
                        .zIndex(1)
                }
                
                
                // Show GameOverView directly based on gameState.gameOver
                if gameManager.gameState.gameOver {
                    GameOverView(gameManager: gameManager, navigationPath: $navigationPath)
                        .zIndex(1) // Ensure the GameOverView appears on top
                }
            }
        }
    
    // Determines the top padding based on the device type
        private func topPaddingForDevice() -> CGFloat {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                return 60 // Less padding for iPhone
            case .pad:
                return 0 // More padding for iPad
            default:
                return 0 // Default padding for other devices or future devices
            }
        }
}

#Preview {
    let mockDictionaryManager = DictionaryManager()
    let mockGameManager = GameManager(dictionaryManager: mockDictionaryManager)
    
    // Set up some sample tiles based on the provided Tile structure
    let sampleTiles = [
        Tile(letter: "A", type: .regular, points: 1, position: Position(row: 0, column: 0), isPlaceholder: false),
        Tile(letter: "B", type: .green, points: 2, position: Position(row: 0, column: 1), isPlaceholder: false),
        Tile(letter: "C", type: .gold, points: 3, position: Position(row: 0, column: 2), isPlaceholder: false)
    ]
    mockGameManager.tileManager.selectedTiles = sampleTiles // Add some sample selected tiles
    
    return GameView(navigationPath: .constant(NavigationPath()))
        .environmentObject(mockGameManager) // Inject GameManager into the environment
}



