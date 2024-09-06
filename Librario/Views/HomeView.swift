//
//  HomeView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/29/24.
//

import SwiftUI

struct HomeView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                                Image("Title_Book_3")
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
                            navigationPath.append(ViewType.game)
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
                    SettingsView() //TODO: Add nav path
                case .stats:
                    StatsView() //TODO: Add nav path
                }
            }
        }
    }
}

enum ViewType: Hashable {
    case game
    case settings
    case stats
}

#Preview {
    HomeView()
}
