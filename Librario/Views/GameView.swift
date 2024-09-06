//
//  ContentView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import SwiftUI

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameState: GameState
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
                        
                        SubmitWordView(gameState: gameState, tileManager: gameState.tileManager)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                    
                    GameGridView(tileManager: gameState.tileManager)
                    
                    GameStatusView(gameState: gameState, navigationPath: $navigationPath)
                    
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private func progressBarWidth(totalWidth: CGFloat) -> CGFloat {
        guard let nextLevelThreshold = gameState.levelSystem[gameState.level] else { return 0 }
        let currentLevelThreshold = gameState.level > 1 ? gameState.levelSystem[gameState.level - 1]! : 0
        let levelProgress = CGFloat(gameState.score - currentLevelThreshold) / CGFloat(nextLevelThreshold - currentLevelThreshold)
        return totalWidth * min(levelProgress, 1.0)
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
    GameView(navigationPath: .constant(NavigationPath()))
        .environmentObject(GameState(dictionaryManager: DictionaryManager()))
}


