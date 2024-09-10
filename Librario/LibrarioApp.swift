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
    @StateObject private var userData: UserData
    @StateObject private var gameManager: GameManager
//    @StateObject private var settings = Settings.load()
    @Environment(\.scenePhase) var scenePhase

    init() {
        let dictionaryManager = DictionaryManager()
        let userData = UserData.loadUserData()
        let gameManager = GameManager(dictionaryManager: dictionaryManager)
        _dictionaryManager = StateObject(wrappedValue: dictionaryManager)
        _gameManager = StateObject(wrappedValue: gameManager)
        _userData = StateObject(wrappedValue: userData)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(gameManager)
                .environmentObject(userData)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                print("App going into background")
                gameManager.saveGame()
            }
        }
    }
}
