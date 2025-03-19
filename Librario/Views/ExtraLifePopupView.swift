//
//  ExtraLifePopupView.swift
//  Librario
//
//  Created on 3/16/2025.
//

import SwiftUI

struct ExtraLifePopupView: View {
    @Bindable var gameManager: GameManager
    
    var body: some View {
        let extraLifeCard = Card(
            title: "Use Extra Life?",
            subtitle: "You're about to lose! Do you want to use an extra life to continue playing?",
            cardColor: .ruby,
            isCloseDisabled: true,
            buttons: [
                CardButton(
                    title: "Use Extra Life",
                    cardColor: .ruby,
                    action: {
                        // Clear the timer first to avoid race conditions
                        gameManager.stopExtraLifeTimer()
                        
                        // Use the extra life and continue
                        DispatchQueue.main.async {
                            let _ = gameManager.useExtraLifeAndContinue()
                        }
                    }
                ),
                CardButton(
                    title: "Game Over",
                    cardColor: .charcoal,
                    action: {
                        gameManager.proceedWithGameOver()
                    }
                )
            ]
        ) {
            GeometryReader { geometry in
                VStack(spacing: 16) {
                    // Timer progress bar
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 10)
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geometry.size.width * gameManager.getExtraLifeTimerProgress(), height: 10)
                    }
                    .cornerRadius(5)
                    
                    // Heart icons showing how many extra lives have been used
                    HStack(spacing: 15) {
                        ForEach(0..<min(3, max(gameManager.getPowerupCount(.extraLife), 1)), id: \.self) { index in
                            Image(systemName: index < gameManager.getExtraLivesUsedInSession() ? "heart" : "heart.fill")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Remaining extra lives count
                    Text("You have \(gameManager.getPowerupCount(.extraLife)) extra life(s) remaining")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    // Session limit info
                    Text("(Limit: 3 per session)")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                }
                .padding()
                .frame(width: geometry.size.width)
            }
        }
        
        CardView(cards: [extraLifeCard])
    }
}

#Preview {
    let gameManager = GameManager(dictionaryManager: DictionaryManager())
    return ExtraLifePopupView(gameManager: gameManager)
}
