//
//  LibrarioApp.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/11/24.
//

import SwiftUI
import SwiftData
import Observation
import GameKit
import StoreKit

@main
struct MyApp: App {
    let dictionaryManager: DictionaryManager
    let userData: UserData
    let gameManager: GameManagerProtocol
    let arcadeGameManager: GameManagerProtocol
    let storeManager: StoreManager
    let gameCenterManager = GameCenterManager.shared
    @Environment(\.scenePhase) var scenePhase
    
    // Task to store the Transaction.updates listener
    @State private var transactionListenerTask: Task<Void, Error>?


    init() {
        // Initialize StoreKit transaction listener at app launch
        let dictionaryManager = DictionaryManager()
        let userData = UserData.loadUserData()
        
        // Create store manager with direct access to userData
        let storeManager = StoreManager(userData: userData)
        
        // Create game managers with direct access to userData - using our new protocol-based structure
        let classicGameManager = ClassicGameManager(
            dictionaryManager: dictionaryManager,
            userData: userData
        )
        
        let arcadeGameManager = ArcadeGameManager2(
            dictionaryManager: dictionaryManager,
            userData: userData
        )
        
        self.dictionaryManager = dictionaryManager
        self.gameManager = classicGameManager
        self.arcadeGameManager = arcadeGameManager
        self.userData = userData
        self.storeManager = storeManager
        AudioManager.shared.playMusic(named: "gameLoop1", loop: true)
        
        gameCenterManager.userStatistics = userData.userStatistics
    }

    var body: some Scene {
        WindowGroup {
            HomeView(userData: userData, gameManager: gameManager, arcadeGameManager: arcadeGameManager, storeManager: storeManager)
                .onAppear {
                    // Set up a transaction listener when the app appears
                    // This is a backup in case the listener in StoreManager fails
                    transactionListenerTask = Task {
                        // Iterate through any transactions that don't come from a direct call to `purchase()`
                        for await result in Transaction.updates {
                            // Handle transaction here if needed
                            if case .verified(let transaction) = result {
                                await transaction.finish()
                            }
                        }
                    }
                }
                .onDisappear {
                    // Cancel the transaction listener when the app disappears
                    transactionListenerTask?.cancel()
                    transactionListenerTask = nil
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Only restart timer if we were previously in background
                if oldPhase == .background {
                    print("App became active from background")
                    NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
                }
                
                // Update login streak when app becomes active
                userData.userStatistics.updateLoginStreak()
                userData.userStatistics.saveUserStatistics()
                print("Updated login streak on app launch")
            case .inactive:
                print("App became inactive")
                // Pause timers but don't save state yet
                gameManager.pauseGameTimer()
                arcadeGameManager.pauseGameTimer()
                
                // Also pause fire tile timer for arcade mode
                if let arcadeManager = arcadeGameManager as? ArcadeGameManager2 {
                    arcadeManager.pauseFireTileTimer()
                }
            case .background:
                print("App going into background")
                // Update statistics with current game time before going to background
                gameManager.updateStatisticsWithGameTime()
                arcadeGameManager.updateStatisticsWithGameTime()
                // Save state
                gameManager.saveGame()
                arcadeGameManager.saveGame()
                userData.saveUserData()
            @unknown default:
                break
            }
        }
    }
}

extension UIViewController: @retroactive GKGameCenterControllerDelegate {
    public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
