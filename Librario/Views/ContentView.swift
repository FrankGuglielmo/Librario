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
        VStack {
            GameStatusView(gameState: gameState)
                .padding()

            GameGridView(tileManager: gameState.tileManager)
                .padding()

            ControlPanelView(gameState: gameState, tileManager: gameState.tileManager)
                .padding()
        }
        .background(Color.white)
        .ignoresSafeArea()
    }
}


#Preview {
    ContentView()
}
