//
//  LibrarioApp.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/11/24.
//

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
    }

    var body: some Scene {
        WindowGroup {
            HomeView(gameManager: gameManager, userData: userData)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                print("App going into background")
                gameManager.levelData.endGameplay()
                gameManager.saveGame()
                userData.saveUserData()
            }
        }
    }
}

extension UIViewController: GKGameCenterControllerDelegate {
    public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}

