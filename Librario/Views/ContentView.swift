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
                    ControlPanelView(gameState: gameState, tileManager: gameState.tileManager)
                        .padding()
                        .frame(height: geometry.size.height * 0.30) // 30% of the available height

                    GameGridView(tileManager: gameState.tileManager)
                        .padding()
                        .frame(height: geometry.size.height * 0.50) // 50% of the available height

                    GameStatusView(gameState: gameState)
                        .padding()
                        .frame(height: geometry.size.height * 0.15) // 15% of the available height
                }
                .frame(maxHeight: .infinity) // Ensure the VStack fills the available space
            }
            .background(Color.cyan)
            .ignoresSafeArea()
        }
}

