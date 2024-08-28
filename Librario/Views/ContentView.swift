//
//  ContentView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
            GeometryReader { geometry in
                VStack {
                    SubmitWordView(gameState: gameState, tileManager: gameState.tileManager)
                        .padding(.top, topPaddingForDevice())
                        .padding()
                        .background(Color.blue.opacity(0.2))
                       

                    GameGridView(tileManager: gameState.tileManager)
                        .background(Color.green.opacity(0.2))
    

                    GameStatusView(gameState: gameState)
                        .padding()

                }
                .frame(maxHeight: .infinity) // Ensure the VStack fills the available space
            }
            .background(Color(red: 0.55, green: 0.0, blue: 0.0))
            .ignoresSafeArea()
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
    ContentView()
        .environmentObject(GameState(dictionaryManager: DictionaryManager()))
}

