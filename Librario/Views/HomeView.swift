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
    @Bindable var userData: UserData
    @State private var gameCenterManager = GameCenterManager.shared
    @State private var inventoryManager: InventoryManager
    @State private var gameManager: GameManager
    
    init() {
        // Create user data
        let loadedUserData = UserData.loadUserData()
        self._userData = Bindable(wrappedValue: loadedUserData)
        
        // Create inventory manager
        let invManager = InventoryManager(
            inventory: loadedUserData.inventory,
            saveCallback: { loadedUserData.saveUserData() }
        )
        self._inventoryManager = State(initialValue: invManager)
        
        // Create game manager with inventory manager
        let gameMan = GameManager(
            dictionaryManager: DictionaryManager(),
            inventoryManager: invManager
        )
        self._gameManager = State(initialValue: gameMan)
    }
    
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
                    ZStack {
                        HStack {
                            Spacer()
                            
                            // Settings gear icon in top right
                            Button(action: {
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                pathStore.path.append(ViewType.settings)
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        
                        VStack {
                            Spacer().frame(height: topSpacing) // Adjusted spacing based on screen size
                            
                            // Librario text as image
                            Image("Librario_regular")
                                .resizable()
                                .scaledToFit()
                                .frame(width: imageWidth, height: imageHeight)
                        }
                    }
                    
                    
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
                            
                            // Settings Button (action now blank)
                            Button(action: {
                                // Action is now blank
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                            }, label: {
                                Image(bookImages[1])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: bookHeights[1])
                            })
                            
                            // How to Play Button
                            Button(action: {
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                pathStore.path.append(ViewType.tips)
                            }, label: {
                                Image(bookImages[2])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: bookHeights[2])
                            })
                            
                            // Stats Button (now includes leaderboards)
                            Button(action: {
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                gameManager.updateUserStatistics(userData.userStatistics)
                                pathStore.path.append(ViewType.store)
                            }, label: {
                                Image(bookImages[3])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: bookHeights[3])
                            })
                            
                            Button(action: {
                                AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                                gameManager.updateUserStatistics(userData.userStatistics)
                                pathStore.path.append(ViewType.stats)
                            }, label: {
                                Image(bookImages[4])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: bookHeights[4])
                            })
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
                case .store:
                    StoreView(inventoryManager: inventoryManager, navigationPath: $pathStore.path)
                        .navigationBarBackButtonHidden(true)
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
            return ["Classic_Book", "Arcade_Book", "HowTo_Book", "Store_Book", "Leaderboard_Book"]
        } else {
            return ["Classic_Book_Large", "Arcade_Book_Large", "HowTo_Book_Large", "Store_Book_Large", "Leaderboard_Book_Large"]
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
}

struct HomePage2_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
        }
    }
}

enum ViewType: Hashable, Codable {
    case game
    case settings
    case stats
    case tips
    case store
}
