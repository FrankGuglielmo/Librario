//
//  HomeView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/29/24.
//

import SwiftUI

struct HomeView: View {
    @State private var pathStore = PathStore() // Create PathStore instance
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var userData: UserData
    @State private var showActionSheet = false

    var body: some View {
        NavigationStack(path: $pathStore.path) { // Use pathStore's path
            ZStack {
                // Background color filling the entire safe area
                Image("red_curtain")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    // Header
                    VStack {
                    
                        Text("Librario")
                            .font(Font.custom("NerkoOne-Regular", size: 70, relativeTo: .title))
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                        HStack {
                            Image("happy_sprite")
                        }
                    }

                    // Center with Navigation to various views
                    VStack(alignment: .trailing, spacing: 0) {
                        Button(action: {
                            if gameManager.gameState.score > 0 {
                                // If there is an active game, show the action sheet to resume or start new
                                showActionSheet = true
                            } else {
                                // Start a new game directly
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                gameManager.startNewGame(userStatistics: userData.userStatistics)
                                pathStore.path.append(ViewType.game)
                            }
                        }, label: {
                            ZStack {
                                if gameManager.gameState.score > 0 { // Assume game is active if score > 0
                                    Image("Resume_book") // Image when game is active
                                } else {
                                    Image("Title_Book_3") // Default image for new game
                                }
                                Text("Classic Game")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        })
                        .actionSheet(isPresented: $showActionSheet) {
                            ActionSheet(
                                title: Text("Active Game Detected"),
                                message: Text("Would you like to resume your current game or start a new one?"),
                                buttons: [
                                    .default(Text("Resume Game")) {
                                        // Resume the current game
                                        AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                        pathStore.path.append(ViewType.game)
                                    },
                                    .destructive(Text("Start New Game")) {
                                        // Start a new game
                                        AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                        gameManager.startNewGame(userStatistics: userData.userStatistics)
                                        pathStore.path.append(ViewType.game)
                                    },
                                    .cancel()
                                ]
                            )
                        }

                        Button(action: {
                            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                            pathStore.path.append(ViewType.settings)
                        }, label: {
                            ZStack {
                                Image("Title_Book_2")
                                Text("Settings")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(.trailing, 5)
                        })

                        Button(action: {
                            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                            pathStore.path.append(ViewType.tips)
                        }, label: {
                            ZStack {
                                Image("Title_Book_4")
                                Text("How To Play")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        })
                        
                        Button(action: {
                            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                            gameManager.updateUserStatistics(userData.userStatistics)
                            pathStore.path.append(ViewType.stats)
                        }, label: {
                            ZStack {
                                Image("Title_Book_1")
                                Text("Stats")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        })
                        
                    }
                    .padding()
                }
            }
            .navigationDestination(for: ViewType.self) { viewType in
                switch viewType {
                case .game:
                    GameView(navigationPath: $pathStore.path)
                        .navigationBarBackButtonHidden(true) // Disable back button
                case .settings:
                    SettingsView(navigationPath: $pathStore.path)
                        .navigationBarBackButtonHidden(true)
                case .stats:
                    StatsView(navigationPath: $pathStore.path)
                        .navigationBarBackButtonHidden(true)
                case .tips:
                    TipView(navigationPath: $pathStore.path)
                        .navigationBarBackButtonHidden(true)
                }
                
            }
        }
    }
}


enum ViewType: Hashable, Codable {
    case game
    case settings
    case stats
    case tips
}





struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock GameManager instance with default or sample data
        let mockGameManager = GameManager(dictionaryManager: DictionaryManager())
        mockGameManager.gameState = GameState() // Sample state with score 0

        // Mock UserData instance with default or sample data
        let mockUserData = UserData()
        mockUserData.userStatistics = UserStatistics() // Sample statistics

        return HomeView()
            .environmentObject(mockGameManager) // Inject mock GameManager
            .environmentObject(mockUserData) // Inject mock UserData
            .previewDisplayName("HomeView Preview")
    }
}
