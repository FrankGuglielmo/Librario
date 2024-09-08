//
//  HomeView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/29/24.
//

import SwiftUI

struct HomeView: View {
    @State private var navigationPath = NavigationPath() // Create PathStore instance
    @EnvironmentObject var gameState: GameState

    var body: some View {
        NavigationStack(path: $navigationPath) { // Use pathStore's path
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
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                        HStack {
                            Image("happy_sprite")
                        }
                    }

                    // Center with Navigation to various views
                    VStack(alignment: .trailing, spacing: 0) {
                        Button(action: {
                            navigationPath.append(ViewType.game)
                        }, label: {
                            ZStack {
                                // Conditionally show different images based on the game state
                                if gameState.score > 0 { // Assume game is active if score > 0
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

                        Button(action: {
                            navigationPath.append(ViewType.settings)
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
                            navigationPath.append(ViewType.stats)
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
                    GameView(navigationPath: $navigationPath)
                        .navigationBarBackButtonHidden(true) // Disable back button
                case .settings:
                    SettingsView()
                case .stats:
                    StatsView()
                }
            }
        }
    }
}


enum ViewType: Hashable, Codable {
    case game
    case settings
    case stats
}

#Preview {
    HomeView()
}
