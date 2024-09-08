//
//  LibrarioApp.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/11/24.
//

import SwiftUI
import SwiftData

@main
struct MyApp: App {
    @StateObject private var dictionaryManager: DictionaryManager
    @StateObject private var gameState: GameState
    @Environment(\.scenePhase) var scenePhase

    init() {
        let manager = DictionaryManager()
        let state = GameState.loadGameState(dictionaryManager: manager)
        _dictionaryManager = StateObject(wrappedValue: manager)
        _gameState = StateObject(wrappedValue: state)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(dictionaryManager)
                .environmentObject(gameState)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                gameState.saveGameState()
            }
        }
    }
}
