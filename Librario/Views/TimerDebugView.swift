//
//  TimerDebugView.swift
//  Librario
//
//  Created by Frank Guglielmo on 3/5/25.
//

import SwiftUI

struct TimerDebugView: View {
    @Bindable var gameManager: GameManager
    @Bindable var userData: UserData
    @State private var isExpanded: Bool = false
    @State private var timer: Timer? = nil
    @State private var refreshTrigger: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                isExpanded.toggle()
                
                // Start or stop the refresh timer based on expansion state
                if isExpanded {
                    startRefreshTimer()
                } else {
                    stopRefreshTimer()
                }
            }) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.white)
                    
                    Text("Timer Debug")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .padding(6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current game time: \(gameManager.currentGameTime.formattedCompact)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("Level time: \(gameManager.levelData.timePlayed.formattedCompact)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("Session time: \(gameManager.sessionData.timePlayed.formattedCompact)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("Lifetime time: \(userData.userStatistics.timePlayed.formattedCompact)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("Game state: \(String(describing: gameManager.gameplayState))")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("In GameView: \(gameManager.isInGameView ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
                .id(refreshTrigger) // Force refresh when this changes
            }
        }
        .padding(8)
        .onDisappear {
            stopRefreshTimer()
        }
    }
    
    private func startRefreshTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            refreshTrigger.toggle() // Toggle to force refresh
        }
    }
    
    private func stopRefreshTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    let dictionaryManager = DictionaryManager()
    let gameManager = GameManager(dictionaryManager: dictionaryManager)
    let userData = UserData()
    
    return TimerDebugView(gameManager: gameManager, userData: userData)
        .background(Color.gray)
}
