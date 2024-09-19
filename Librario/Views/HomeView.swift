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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showActionSheet = false

    var body: some View {
        NavigationStack(path: $pathStore.path) { // Use pathStore's path
            GeometryReader { geometry in
                let isCompact = horizontalSizeClass == .compact
                let titleFontSize: CGFloat = isCompact ? geometry.size.width * 0.12 : geometry.size.width * 0.08
                let imageWidth: CGFloat = isCompact ? geometry.size.width * 0.8 : geometry.size.width * 0.5

                ZStack {
                    // Background color filling the entire safe area
                    Image("red_curtain")
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        // Header
                        VStack(spacing: 4) {
                            Text("Librario")
                                .font(Font.custom("NerkoOne-Regular", size: titleFontSize, relativeTo: .title))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.white)

                            HStack {
                                Image("happy_sprite")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width * 0.2) // Adjust sprite size based on screen
                            }
                        }

                        // Center with Navigation to various views
                        VStack(alignment: .trailing, spacing: 0) {
                            // Classic Game Button
                            Button(action: {
                                if gameManager.gameState.score > 0 {
                                    showActionSheet = true
                                } else {
                                    AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                    gameManager.startNewGame(userStatistics: userData.userStatistics)
                                    pathStore.path.append(ViewType.game)
                                }
                            }, label: {
                                ZStack {
                                    Image(gameManager.gameState.score > 0 ? "Resume_book" : "Title_Book_3")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: imageWidth)
                                    
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
                                            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                            pathStore.path.append(ViewType.game)
                                        },
                                        .destructive(Text("Start New Game")) {
                                            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                            gameManager.startNewGame(userStatistics: userData.userStatistics)
                                            pathStore.path.append(ViewType.game)
                                        },
                                        .cancel()
                                    ]
                                )
                            }

                            // Settings Button
                            Button(action: {
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                pathStore.path.append(ViewType.settings)
                            }, label: {
                                ZStack {
                                    Image("Title_Book_2")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: imageWidth)
                                    
                                    Text("Settings")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            })
                            .padding(.trailing, 5)

                            // How to Play Button
                            Button(action: {
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                pathStore.path.append(ViewType.tips)
                            }, label: {
                                ZStack {
                                    Image("Title_Book_4")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: imageWidth)
                                    
                                    Text("How To Play")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            })

                            // Stats Button
                            Button(action: {
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                gameManager.updateUserStatistics(userData.userStatistics)
                                pathStore.path.append(ViewType.stats)
                            }, label: {
                                ZStack {
                                    Image("Title_Book_1")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: imageWidth)
                                    
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


