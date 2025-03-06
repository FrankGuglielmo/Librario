//
//  HomeView.swift
//  Librario
//

import SwiftUI
import GameKit

struct HomeView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var showActionSheet = false
    @State private var pathStore = PathStore() // Create PathStore instance
    @State var gameManager: GameManager
    @State private var gameCenterManager = GameCenterManager.shared
    @Bindable var userData: UserData
    @State private var showingGameCenter = false
    @State private var isParentalGatePassed = false


    // Getting screen size to calculate dynamic values
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        NavigationStack(path: $pathStore.path) {
            ZStack {
                Image("Background_Image")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer().frame(height: topSpacing) // Adjusted spacing based on screen size
                    
                    // Librario text as image
                    Image("Librario_regular")
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageWidth, height: imageHeight)
                    
                    
                    // Sprite and text bubble
                    HStack {
                        ZStack {
                            Image("happy_sprite")
                                .resizable()
                                .scaledToFit()
                                .frame(width: spriteSize, height: spriteSize)
                            
                            if gameCenterManager.isAuthenticated {
                                WelcomeBubbleView(name: GKLocalPlayer.local.alias)
                                    .frame(width: bubbleWidth, height: bubbleHeight)
                                    .offset(x: bubbleOffsetX, y: bubbleOffsetY)
                            } else {
                                WelcomeBubbleView(name: "Librarian")
                                    .frame(width: bubbleWidth, height: bubbleHeight)
                                    .offset(x: bubbleOffsetX, y: bubbleOffsetY)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Stack of books (buttons)
                    HStack {
                        Spacer()
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
                                    if gameManager.gameState.score > 0 {
                                        Image(horizontalSizeClass == .compact ? "Resume_Book" : "Resume_Book_Large")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: bookHeights[0])
                                    } else {
                                        Image(bookImages[0])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: bookHeights[0])
                                    }
                                    
                                    
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
                                    Image(bookImages[1])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: bookHeights[1])
                                    
                                    
                                }
                            })
                            
                            // How to Play Button
                            Button(action: {
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                pathStore.path.append(ViewType.tips)
                            }, label: {
                                ZStack {
                                    Image(bookImages[2])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: bookHeights[2])
                                    
                                    
                                }
                            })
                            
                            // Stats Button
                            Button(action: {
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                gameManager.updateUserStatistics(userData.userStatistics)
                                pathStore.path.append(ViewType.stats)
                            }, label: {
                                Image(bookImages[3])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: bookHeights[3])
                            })
                            
                            // Leaderboard Button with Parental Gate
                            if gameCenterManager.isAuthenticated {
                                Button(action: {
                                    AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                    if isParentalGatePassed {
                                        presentGameCenterDashboard()
                                    } else {
                                        showingGameCenter = true
                                    }
                                }, label: {
                                    Image(bookImages[4])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: bookHeights[4]) // Adjust height as needed
                                })
                                .sheet(isPresented: $showingGameCenter) {
                                    ParentalGateView(isParentalGatePassed: $isParentalGatePassed, presentGameCenterDashboard: presentGameCenterDashboard)
                                }
                            } else {
                                Image(bookImages[5])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: bookHeights[5]) // Adjust height as needed
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: ViewType.self) { viewType in
                switch viewType {
                case .game:
                    GameView(gameManager: gameManager, userData: userData, navigationPath: $pathStore.path)
                        .navigationBarBackButtonHidden(true) // Disable back button
                case .settings:
                    SettingsView(navigationPath: $pathStore.path)
                        .navigationBarBackButtonHidden(true)
                case .stats:
                    StatsView(userData: userData, navigationPath: $pathStore.path)
                        .navigationBarBackButtonHidden(true)
                case .tips:
                    TipView(navigationPath: $pathStore.path)
                        .navigationBarBackButtonHidden(true)
                case .leaderboard:
                    GameCenterView(viewState: .leaderboards)
                }
            }
        }
    }
    
    // MARK: - Dynamic Size Variables

    var topSpacing: CGFloat {
        screenHeight * (horizontalSizeClass == .compact ? 0.02 : 0.03)
    }
    
    var imageWidth: CGFloat {
        screenWidth * (horizontalSizeClass == .compact ? 0.5 : 0.4)
    }
    
    var imageHeight: CGFloat {
        screenHeight * (horizontalSizeClass == .compact ? 0.09 : 0.1)
    }
    
    var imageBottomPadding: CGFloat {
        screenHeight * 0.02
    }
    
    var spriteSize: CGFloat {
        screenWidth * (horizontalSizeClass == .compact ? 0.4 : 0.325)
    }
    
    var bubbleWidth: CGFloat {
        screenWidth * (horizontalSizeClass == .compact ? 0.4 : 0.3)
    }
    
    var bubbleHeight: CGFloat {
        screenHeight * (horizontalSizeClass == .compact ? 0.1 : 0.12)
    }
    
    var bubbleOffsetX: CGFloat {
        screenWidth * (horizontalSizeClass == .compact ? 0.36 : 0.3)
    }
    
    var bubbleOffsetY: CGFloat {
        screenHeight * (horizontalSizeClass == .compact ? -0.04 : -0.06)
    }
    
    var bottomPadding: CGFloat {
        screenHeight * 0.02
    }
    
    var bookImages: [String] {
        // Append "_Large" for larger devices
        if horizontalSizeClass == .compact {
            return ["Classic_Book", "Settings_Book", "HowTo_Book", "Stats_Book", "Leaderboard_Book", "Blank_Book"]
        } else {
            return ["Classic_Book_Large", "Settings_Book_Large", "HowTo_Book_Large", "Stats_Book_Large", "Leaderboard_Book_Large", "Blank_Book_Large"]
        }
    }
    
    var bookHeights: [CGFloat] {
        let isDynamicIsland = UIDevice.current.userInterfaceIdiom == .phone && screenHeight > 800 && screenHeight < 950
        let baseHeight: CGFloat

        if isDynamicIsland {
            // Reduce book size for dynamic island devices (e.g., iPhone 14 Pro/Pro Max)
            baseHeight = screenHeight * 0.105
        } else {
            baseHeight = screenHeight * 0.12
        }

        return [
            baseHeight * (95.0 / 90.0),
            baseHeight * (80.0 / 90.0),
            baseHeight * (80.0 / 90.0),
            baseHeight * (80.0 / 90.0),
            baseHeight * (80.0 / 90.0),
            baseHeight * (80.0 / 90.0)
        ]
    }

    var bookFontSize: CGFloat {
        screenHeight * 0.03
    }
    
    
    func presentGameCenterDashboard() {
        // Get the active window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {

            // Initialize the Game Center dashboard view controller
            let gameCenterVC = GKGameCenterViewController(state: .dashboard)
            gameCenterVC.gameCenterDelegate = rootVC  // No need for a conditional cast

            // Present the Game Center dashboard
            rootVC.present(gameCenterVC, animated: true, completion: nil)
        } else {
            print("Failed to find the root view controller")
        }
    }
}

struct HomePage2_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView(gameManager: GameManager(dictionaryManager: DictionaryManager()), userData: UserData())
        }
    }
}

enum ViewType: Hashable, Codable {
    case game
    case settings
    case stats
    case tips
    case leaderboard
}



