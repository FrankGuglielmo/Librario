//
//  GameStatusView.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/18/24.
//

import SwiftUI

struct GameStatusView: View {
    @ObservedObject var gameState: GameState

    var body: some View {
        HStack {
            Text("Score: \(gameState.score)")
                .font(.headline)
            Spacer()
            Text("Level: \(gameState.level)")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

