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
    // Declare @StateObject properties
    @StateObject private var dictionaryManager: DictionaryManager
    @StateObject private var gameState: GameState

    // Initializer for MyApp
    init() {
        // Initialize instances of DictionaryManager and GameState
        let manager = DictionaryManager()
        let state = GameState(dictionaryManager: manager)
        
        // Assign instances to @StateObject properties
        _dictionaryManager = StateObject(wrappedValue: manager)
        _gameState = StateObject(wrappedValue: state)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(dictionaryManager)
                .environmentObject(gameState)
        }
    }
}
