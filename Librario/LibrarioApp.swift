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

@main
struct MyApp: App {
    let dictionaryManager: DictionaryManager
    let userData: UserData
    let gameManager: GameManager
    let gameCenterManager = GameCenterManager.shared
    @Environment(\.scenePhase) var scenePhase


    init() {
        let dictionaryManager = DictionaryManager()
        let userData = UserData.loadUserData()
        let gameManager = GameManager(dictionaryManager: dictionaryManager)
        self.dictionaryManager = dictionaryManager
        self.gameManager = gameManager
        self.userData = userData
        AudioManager.shared.playMusic(named: "gameLoop1", loop: true)
        
        gameCenterManager.userStatistics = userData.userStatistics
    }

    var body: some Scene {
        WindowGroup {
            HomeView(gameManager: gameManager, userData: userData)
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
                // Pause timer but don't save state yet
                gameManager.pauseGameTimer()
            case .background:
                print("App going into background")
                // Update statistics with current game time before going to background
                gameManager.updateStatisticsWithGameTime()
                // Save state
                gameManager.saveGame()
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
