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
    
    // Promo codes dictionary (code, isUsed)
    var promoCodes: [String: Bool] = [
        "WELCOME2025": false,
        "LIBRARIOFUN": false,
        "BOOKWORM": false,
        "WORDMASTER": false,
        "POWERUP50": false
    ]
    
    // Initializer
    init(inventoryManager: InventoryManager) {
        self.inventoryManager = inventoryManager
        setupStoreItems()
    }
    
    // Setup store items
    private func setupStoreItems() {
        // Setup daily deals - 3 items as requested
        dailyDeals = [
            StoreItem(
                name: "Daily Swap",
                description: "Get a swap powerup for free by watching a video",
                iconName: PowerupType.swap.iconName,
                price: .video,
                itemType: .powerup(.swap)
            ),
            StoreItem(
                name: "Discounted Coins",
                description: "Get 100 coins at a discounted price",
                iconName: "dollarsign.circle.fill",
                price: .diamonds(1),
                itemType: .currency(.coins, amount: 100)
            ),
            StoreItem(
                name: "Flash Sale - Extra Life",
                description: "Get an extra life at 30% off today only!",
                iconName: PowerupType.extraLife.iconName,
                price: .coins(150),
                itemType: .powerup(.extraLife)
            )
        ]
        
        // Setup general store items - organize by categories
        
        // Powerups section
        let powerupItems: [StoreItem] = [
            // Individual powerups
            StoreItem(
                name: "Swap Pack",
                description: "1x Swap tiles on the board",
                iconName: PowerupType.swap.iconName,
                price: .coins(100), // As requested, 100 coins
                itemType: .powerup(.swap)
            ),
            StoreItem(
                name: "Wildcard Pack",
                description: "1x Use any letter you want",
                iconName: PowerupType.wildcard.iconName,
                price: .coins(150), // As requested, 150 coins
                itemType: .powerup(.wildcard)
            ),
            StoreItem(
                name: "Extra Life Pack",
                description: "1x Continue playing after game over",
                iconName: PowerupType.extraLife.iconName,
                price: .coins(300), // As requested, 300 coins
                itemType: .powerup(.extraLife)
            ),
            // 10 packs
            StoreItem(
                name: "10 Swaps",
                description: "Get 10 swap powerups",
                iconName: PowerupType.swap.iconName,
                price: .coins(900), // 10% discount on buying 10
                itemType: .bundle([.swap], amounts: [10])
            ),
            StoreItem(
                name: "10 Wildcards",
                description: "Get 10 wildcard powerups",
                iconName: PowerupType.wildcard.iconName,
                price: .coins(1350), // 10% discount on buying 10
                itemType: .bundle([.wildcard], amounts: [10])
            ),
            StoreItem(
                name: "10 Extra Lives",
                description: "Get 10 extra life powerups",
                iconName: PowerupType.extraLife.iconName,
                price: .coins(2700), // 10% discount on buying 10
                itemType: .bundle([.extraLife], amounts: [10])
            )
        ]
        
        // Coins section
        let coinItems: [StoreItem] = [
            StoreItem(
                name: "500 Coins",
                description: "Add 500 coins to your wallet",
                iconName: "dollarsign.circle.fill",
                price: .realMoney(0.99),
                itemType: .currency(.coins, amount: 500)
            ),
            StoreItem(
                name: "2000 Coins",
                description: "Add 2000 coins to your wallet",
                iconName: "dollarsign.circle.fill",
                price: .realMoney(4.99),
                itemType: .currency(.coins, amount: 2000)
            ),
            StoreItem(
                name: "5000 Coins",
                description: "Add 5000 coins to your wallet",
                iconName: "dollarsign.circle.fill",
                price: .realMoney(9.99),
                itemType: .currency(.coins, amount: 5000)
            )
        ]
        
        // Diamonds section
        let diamondItems: [StoreItem] = [
            StoreItem(
                name: "5 Diamonds",
                description: "Add 5 diamonds to your wallet",
                iconName: "diamond_icon",
                price: .realMoney(0.99),
                itemType: .currency(.diamonds, amount: 5)
            ),
            StoreItem(
                name: "20 Diamonds",
                description: "Add 20 diamonds to your wallet",
                iconName: "diamond_icon",
                price: .realMoney(4.99),
                itemType: .currency(.diamonds, amount: 20)
            ),
            StoreItem(
                name: "50 Diamonds",
                description: "Add 50 diamonds to your wallet",
                iconName: "diamond_icon",
                price: .realMoney(9.99),
                itemType: .currency(.diamonds, amount: 50)
            )
        ]
        
        // Combine all sections
        generalItems = []
        generalItems.append(contentsOf: powerupItems)
        generalItems.append(contentsOf: coinItems)
        generalItems.append(contentsOf: diamondItems)
        
        // Setup special offers
        specialOffers = [
            StoreItem(
                name: "Welcome Pack",
                description: "Get 1 of each powerup plus 200 coins",
                iconName: "gift.fill",
                price: .realMoney(2.99), // As requested
                itemType: .bundle([.swap, .extraLife, .wildcard], amounts: [1, 1, 1], currencies: [.coins: 200])
            ),
            StoreItem(
                name: "Premium Bundle",
                description: "Get 3 of each powerup plus 500 coins",
                iconName: "star.fill",
                price: .diamonds(10),
                itemType: .bundle([.swap, .extraLife, .wildcard], amounts: [3, 3, 3], currencies: [.coins: 500])
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
    
    // Validate promo code and grant reward if valid
    func validatePromoCode(_ code: String) -> (isValid: Bool, message: String) {
        let uppercaseCode = code.uppercased()
        
        // Check if code exists
        guard let isUsed = promoCodes[uppercaseCode] else {
            return (false, "Invalid promo code.")
        }
        
        // Check if code has been used
        if isUsed {
            return (false, "This promo code has already been used.")
        }
        
        // Mark code as used
        promoCodes[uppercaseCode] = true
        
        // Grant reward based on the code
        switch uppercaseCode {
        case "WELCOME2025":
            inventoryManager.addCoins(500)
            inventoryManager.addPowerup(.swap, amount: 1)
            return (true, "You received 500 coins and 1 swap powerup!")
            
        case "LIBRARIOFUN":
            inventoryManager.addDiamonds(5)
            return (true, "You received 5 diamonds!")
            
        case "BOOKWORM":
            inventoryManager.addPowerup(.extraLife, amount: 2)
            return (true, "You received 2 extra lives!")
            
        case "WORDMASTER":
            inventoryManager.addPowerup(.wildcard, amount: 2)
            return (true, "You received 2 wildcards!")
            
        case "POWERUP50":
            inventoryManager.addPowerup(.swap, amount: 1)
            inventoryManager.addPowerup(.extraLife, amount: 1)
            inventoryManager.addPowerup(.wildcard, amount: 1)
            return (true, "You received 1 of each powerup!")
            
        default:
            return (false, "Error processing promo code.")
        }
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
            // Handle in-app purchase
            // This would be implemented in a real app
            // For now, show an alert
            return false
        case .video:
            // Video ad would be handled here
            // For now, just grant the item as requested
            break
        }
        
        // Grant the item
        deliverPurchasedItem(item)
        return true
    }
    
    // Deliver a purchased item to the user's inventory
    private func deliverPurchasedItem(_ item: StoreItem) {
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
