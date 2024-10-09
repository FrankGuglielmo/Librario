//
//  GameCenterView.swift
//  Librario
//
//  Created by Frank Guglielmo on 10/9/24.
//

import SwiftUI
import GameKit

struct GameCenterView: UIViewControllerRepresentable {
    let viewState: GKGameCenterViewControllerState

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let gameCenterVC = GKGameCenterViewController(state: .dashboard)
        gameCenterVC.gameCenterDelegate = context.coordinator
        return gameCenterVC
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        var parent: GameCenterView

        init(_ parent: GameCenterView) {
            self.parent = parent
        }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
