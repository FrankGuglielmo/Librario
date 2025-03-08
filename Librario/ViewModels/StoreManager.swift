//
//  StoreManager.swift
//  Librario
//
//  Created on 3/8/2025.
//

import Foundation
import Observation

@Observable class StoreManager {
    private var inventoryManager: InventoryManager
    
    // Store items
    var dailyDeals: [StoreItem] = []
    var generalItems: [StoreItem] = []
    var specialOffers: [StoreItem] = []
    
    // Initializer
    init(inventoryManager: InventoryManager) {
        self.inventoryManager = inventoryManager
        setupStoreItems()
    }
    
    // Setup store items
    private func setupStoreItems() {
        // Setup daily deals
        dailyDeals = [
            StoreItem(
                name: "Daily Swap",
                description: "Get a swap powerup for free by watching a video",
                iconName: PowerupType.swap.iconName,
                price: .video,
                itemType: .powerup(.swap)
            ),
            StoreItem(
                name: "Coin Bonus",
                description: "Get 50 coins at a discounted price",
                iconName: "dollarsign.circle.fill",
                price: .diamonds(1),
                itemType: .currency(.coins, amount: 50)
            )
        ]
        
        // Setup general store items
        generalItems = [
            StoreItem(
                name: "Swap Powerup",
                description: "Swap tiles on the board",
                iconName: PowerupType.swap.iconName,
                price: .coins(PowerupType.swap.basePrice),
                itemType: .powerup(.swap)
            ),
            StoreItem(
                name: "Extra Life",
                description: "Continue playing after game over",
                iconName: PowerupType.extraLife.iconName,
                price: .coins(PowerupType.extraLife.basePrice),
                itemType: .powerup(.extraLife)
            ),
            StoreItem(
                name: "Wildcard",
                description: "Use any letter you want",
                iconName: PowerupType.wildcard.iconName,
                price: .coins(PowerupType.wildcard.basePrice),
                itemType: .powerup(.wildcard)
            ),
            StoreItem(
                name: "100 Coins",
                description: "Add 100 coins to your wallet",
                iconName: "dollarsign.circle.fill",
                price: .diamonds(2),
                itemType: .currency(.coins, amount: 100)
            ),
            StoreItem(
                name: "5 Diamonds",
                description: "Add 5 diamonds to your wallet",
                iconName: "diamond.fill",
                price: .realMoney(0.99),
                itemType: .currency(.diamonds, amount: 5)
            )
        ]
        
        // Setup special offers
        specialOffers = [
            StoreItem(
                name: "Starter Pack",
                description: "Get 1 of each powerup at a discounted price",
                iconName: "gift.fill",
                price: .coins(PowerupType.swap.basePrice + PowerupType.extraLife.basePrice + PowerupType.wildcard.basePrice - 100),
                itemType: .bundle([.swap, .extraLife, .wildcard], amounts: [1, 1, 1])
            ),
            StoreItem(
                name: "Premium Pack",
                description: "Get 3 of each powerup plus 50 coins",
                iconName: "star.fill",
                price: .diamonds(5),
                itemType: .bundle([.swap, .extraLife, .wildcard], amounts: [3, 3, 3], currencies: [.coins: 50])
            ),
            StoreItem(
                name: "Video Reward",
                description: "Watch a video to get a random powerup",
                iconName: "play.rectangle.fill",
                price: .video,
                itemType: .random([.swap, .extraLife, .wildcard])
            )
        ]
    }
    
    // Purchase an item
    func purchaseItem(_ item: StoreItem) -> Bool {
        // Check if the user can afford the item
        switch item.price {
        case .coins(let amount):
            guard inventoryManager.useCoins(amount) else { return false }
        case .diamonds(let amount):
            guard inventoryManager.useDiamonds(amount) else { return false }
        case .realMoney:
            // In-app purchase would be handled here
            // For now, just return false as we're not implementing this yet
            return false
        case .video:
            // Video ad would be handled here
            // For now, just grant the item as requested
            break
        }
        
        // Grant the item
        switch item.itemType {
        case .powerup(let powerupType):
            inventoryManager.addPowerup(powerupType)
        case .currency(let currencyType, let amount):
            switch currencyType {
            case .coins:
                inventoryManager.addCoins(amount)
            case .diamonds:
                inventoryManager.addDiamonds(amount)
            }
        case .bundle(let powerups, let amounts, let currencies):
            // Add powerups
            for (index, powerup) in powerups.enumerated() {
                let amount = index < amounts.count ? amounts[index] : 1
                inventoryManager.addPowerup(powerup, amount: amount)
            }
            
            // Add currencies
            for (currency, amount) in currencies {
                switch currency {
                case .coins:
                    inventoryManager.addCoins(amount)
                case .diamonds:
                    inventoryManager.addDiamonds(amount)
                }
            }
        case .random(let possiblePowerups):
            // Select a random powerup
            if let randomPowerup = possiblePowerups.randomElement() {
                inventoryManager.addPowerup(randomPowerup)
            }
        }
        
        return true
    }
    
    // Watch a video to get a powerup (placeholder implementation)
    func watchVideoForPowerup(_ type: PowerupType) {
        // In a real implementation, this would show a video ad
        // For now, just grant the powerup
        inventoryManager.addPowerup(type)
    }
    
    // Refresh daily deals
    func refreshDailyDeals() {
        // In a real implementation, this would generate new daily deals
        // For now, just keep the existing ones
    }
}
