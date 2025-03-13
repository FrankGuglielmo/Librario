//
//  StoreManager.swift
//  Librario
//
//  Created on 3/8/2025.
//

import Foundation
import Observation
import StoreKit

@Observable class StoreManager {
    private var userData: UserData
    private var userInventory: Inventory // Reference to userData.inventory for readability
    
    // Store items
    var dailyDeals: [StoreItem] = []
    var generalItems: [StoreItem] = []
    var specialOffers: [StoreItem] = []
    
    // Track purchased one-time items
    var purchasedItems: Set<UUID> = []
    
    // Daily deal tracking
    private var lastDailyDealsRefreshDate: Date?
    private var allPossibleDailyDeals: [StoreItem] = []
    private var dailyDealsForToday: [StoreItem] = [] // Store the selected deals for today
    
    // Track purchased daily deals for the current day
    private var purchasedDailyDeals: Set<UUID> = []
    
    // Debug flag for testing
    var showDebugOptions = false
    
    // StoreKit products
    var storeProducts: [Product] = []
    var productsLoaded = false
    
    // Promo codes dictionary (code, isUsed)
    var promoCodes: [String: Bool] = [
        "WELCOME2025": false,
        "LIBRARIOFUN": false,
        "BOOKWORM": false,
        "WORDMASTER": false,
        "POWERUP50": false
    ]
    
    // Keys for UserDefaults
    private let purchasedItemsKey = "purchasedItems"
    private let lastDailyDealsRefreshKey = "lastDailyDealsRefresh"
    private let purchasedDailyDealsKey = "purchasedDailyDeals"
    private let dailyDealsForTodayKey = "dailyDealsForToday"
    
    // Initializer
    init(userData: UserData) {
        self.userData = userData
        self.userInventory = userData.inventory
        
        // Load purchased items from UserDefaults if available
        if let purchasedItemsData = UserDefaults.standard.data(forKey: purchasedItemsKey),
           let decodedItems = try? JSONDecoder().decode(Set<UUID>.self, from: purchasedItemsData) {
            self.purchasedItems = decodedItems
        }
        
        // Load last refresh date
        if let refreshDateData = UserDefaults.standard.data(forKey: lastDailyDealsRefreshKey),
           let refreshDate = try? JSONDecoder().decode(Date.self, from: refreshDateData) {
            self.lastDailyDealsRefreshDate = refreshDate
        }
        
        // Load purchased daily deals from UserDefaults
        if let purchasedDailyDealsData = UserDefaults.standard.data(forKey: purchasedDailyDealsKey),
           let decodedItems = try? JSONDecoder().decode(Set<UUID>.self, from: purchasedDailyDealsData) {
            self.purchasedDailyDeals = decodedItems
        }
        
        // Create possible daily deals pool
        createDailyDealsPool()
        
        // Setup store items (general items and special offers)
        setupStoreItems()
        
        // Load or generate daily deals
        loadOrGenerateDailyDeals()
        
        // Load StoreKit products
        Task {
            await fetchStoreKitProducts()
        }
        
        // Start listening for StoreKit transactions
        listenForTransactions()
    }
    
    // Check if an item has been purchased
    func isItemPurchased(_ item: StoreItem) -> Bool {
        return purchasedItems.contains(item.id)
    }
    
    // Check if a daily deal has been purchased today
    func isDailyDealPurchasedToday(_ item: StoreItem) -> Bool {
        return purchasedDailyDeals.contains(item.id)
    }
    
    // Mark an item as purchased
    private func markItemAsPurchased(_ item: StoreItem) {
        purchasedItems.insert(item.id)
        savePurchasedItems()
    }
    
    // Save purchased items to UserDefaults
    private func savePurchasedItems() {
        if let encodedData = try? JSONEncoder().encode(purchasedItems) {
            UserDefaults.standard.set(encodedData, forKey: purchasedItemsKey)
        }
    }
    
    // Save purchased daily deals to UserDefaults
    private func savePurchasedDailyDeals() {
        if let encodedData = try? JSONEncoder().encode(purchasedDailyDeals) {
            UserDefaults.standard.set(encodedData, forKey: purchasedDailyDealsKey)
        }
    }
    
    // Create pool of possible daily deals (20 different items)
    private func createDailyDealsPool() {
        allPossibleDailyDeals = [
            // Powerup deals - discounted from general store prices
            StoreItem(
                name: "Daily Swap Special",
                description: "Get a swap powerup at 50% off, today only!",
                iconName: PowerupType.swap.iconName,
                price: .coins(50), // 50% off normal price
                itemType: .powerup(.swap),
                accentColor: .orange
            ),
            StoreItem(
                name: "Daily Wildcard Special",
                description: "Get a wildcard powerup at 50% off, today only!",
                iconName: PowerupType.wildcard.iconName,
                price: .coins(75), // 50% off normal price
                itemType: .powerup(.wildcard),
                accentColor: .purple
            ),
            StoreItem(
                name: "Daily Extra Life Special",
                description: "Get an extra life at 50% off, today only!",
                iconName: PowerupType.extraLife.iconName,
                price: .coins(150), // 50% off normal price
                itemType: .powerup(.extraLife),
                accentColor: .red
            ),
            
            // Coin deals
            StoreItem(
                name: "Small Coin Pack",
                description: "Get 50 coins at a discounted price",
                iconName: "dollarsign.circle.fill",
                price: .diamonds(1),
                itemType: .currency(.coins, amount: 50),
                accentColor: .yellow
            ),
            StoreItem(
                name: "Medium Coin Pack",
                description: "Get 100 coins at a discounted price",
                iconName: "dollarsign.circle.fill", 
                price: .diamonds(2),
                itemType: .currency(.coins, amount: 100),
                accentColor: .yellow
            ),
            StoreItem(
                name: "Large Coin Pack",
                description: "Get 200 coins at a discounted price",
                iconName: "dollarsign.circle.fill",
                price: .diamonds(3),
                itemType: .currency(.coins, amount: 200),
                accentColor: .yellow
            ),
            
            // Diamond deals
            StoreItem(
                name: "Free Diamond",
                description: "Get 1 diamond by watching a video",
                iconName: "diamond_icon",
                price: .video,
                itemType: .currency(.diamonds, amount: 1),
                accentColor: .cyan
            ),
            StoreItem(
                name: "Diamond Trio",
                description: "Get 3 diamonds for the price of 2",
                iconName: "diamond_icon",
                price: .coins(300),
                itemType: .currency(.diamonds, amount: 3),
                accentColor: .cyan
            ),
            
            // Bundle deals
            StoreItem(
                name: "Daily Starter Pack",
                description: "Get 1 of each powerup at a special price",
                iconName: "gift.fill",
                price: .coins(250), // Discounted bundle
                itemType: .bundle([.swap, .extraLife, .wildcard], amounts: [1, 1, 1]),
                accentColor: .green
            ),
            StoreItem(
                name: "Swap Bundle",
                description: "Get 3 swap powerups at a special price",
                iconName: PowerupType.swap.iconName,
                price: .coins(200), // Discounted from 300 regular price
                itemType: .bundle([.swap], amounts: [3]),
                accentColor: .orange
            ),
            StoreItem(
                name: "Wildcard Bundle",
                description: "Get 3 wildcard powerups at a special price",
                iconName: PowerupType.wildcard.iconName,
                price: .coins(300), // Discounted from 450 regular price
                itemType: .bundle([.wildcard], amounts: [3]),
                accentColor: .purple
            ),
            StoreItem(
                name: "Life Bundle",
                description: "Get 3 extra lives at a special price",
                iconName: PowerupType.extraLife.iconName,
                price: .coins(600), // Discounted from 900 regular price
                itemType: .bundle([.extraLife], amounts: [3]),
                accentColor: .red
            ),
            
            // Video offers
            StoreItem(
                name: "Free Swap",
                description: "Get a swap powerup for free by watching a video",
                iconName: PowerupType.swap.iconName,
                price: .video,
                itemType: .powerup(.swap),
                accentColor: .orange
            ),
            StoreItem(
                name: "Free Wildcard",
                description: "Get a wildcard powerup for free by watching a video",
                iconName: PowerupType.wildcard.iconName,
                price: .video,
                itemType: .powerup(.wildcard),
                accentColor: .purple
            ),
            StoreItem(
                name: "Free Extra Life",
                description: "Get an extra life for free by watching a video",
                iconName: PowerupType.extraLife.iconName,
                price: .video,
                itemType: .powerup(.extraLife),
                accentColor: .red
            ),
            
            // Coins for video
            StoreItem(
                name: "Video Coins",
                description: "Get 25 coins by watching a video",
                iconName: "dollarsign.circle.fill",
                price: .video,
                itemType: .currency(.coins, amount: 25),
                accentColor: .yellow
            ),
            
            // Special mixed bundles
            StoreItem(
                name: "Swap & Coins Bundle",
                description: "Get 2 swaps and 50 coins at a special price",
                iconName: "gift.fill",
                price: .coins(180), // Discounted
                itemType: .bundle([.swap], amounts: [2], currencies: [.coins: 50]),
                accentColor: .orange
            ),
            StoreItem(
                name: "Wildcard & Coins Bundle",
                description: "Get 2 wildcards and 50 coins at a special price",
                iconName: "gift.fill",
                price: .coins(280), // Discounted
                itemType: .bundle([.wildcard], amounts: [2], currencies: [.coins: 50]),
                accentColor: .purple
            ),
            StoreItem(
                name: "Extra Life & Coins Bundle",
                description: "Get 2 extra lives and 50 coins at a special price",
                iconName: "gift.fill",
                price: .coins(550), // Discounted
                itemType: .bundle([.extraLife], amounts: [2], currencies: [.coins: 50]),
                accentColor: .red
            ),
            StoreItem(
                name: "Diamond & Powerup Bundle",
                description: "Get 1 diamond and 1 of each powerup",
                iconName: "gift.fill",
                price: .coins(500), // Special bundle
                itemType: .bundle([.swap, .extraLife, .wildcard], amounts: [1, 1, 1], currencies: [.diamonds: 1]),
                accentColor: .cyan
            )
        ]
    }
    
    // Load existing daily deals or generate new ones if needed
    private func loadOrGenerateDailyDeals() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we have saved daily deals
        if let dailyDealsData = UserDefaults.standard.data(forKey: dailyDealsForTodayKey),
           let decodedDeals = try? JSONDecoder().decode([StoreItem].self, from: dailyDealsData) {
            
            // Check if they're from today
            if let lastRefreshDate = lastDailyDealsRefreshDate, calendar.isDate(lastRefreshDate, inSameDayAs: now) {
                // Use the stored deals from today
                self.dailyDealsForToday = decodedDeals
                self.dailyDeals = decodedDeals
                return
            }
        }
        
        // If we don't have deals for today or it's a new day, generate new ones
        if let lastRefreshDate = lastDailyDealsRefreshDate, !calendar.isDate(lastRefreshDate, inSameDayAs: now) {
            // It's a new day, refresh the deals
            generateDailyDeals()
            saveLastRefreshDate(now)
            
            // Clear purchased daily deals for the new day
            purchasedDailyDeals.removeAll()
            savePurchasedDailyDeals()
        } else if lastDailyDealsRefreshDate == nil {
            // No refresh date saved, so this is first run
            generateDailyDeals()
            saveLastRefreshDate(now)
        }
    }
    
    // Save daily deals to UserDefaults
    private func saveDailyDeals() {
        if let encodedData = try? JSONEncoder().encode(dailyDealsForToday) {
            UserDefaults.standard.set(encodedData, forKey: dailyDealsForTodayKey)
        }
    }
    
    // Save the last refresh date to UserDefaults
    private func saveLastRefreshDate(_ date: Date) {
        lastDailyDealsRefreshDate = date
        if let encodedData = try? JSONEncoder().encode(date) {
            UserDefaults.standard.set(encodedData, forKey: lastDailyDealsRefreshKey)
        }
    }
    
    // Setup general store items and special offers
    private func setupStoreItems() {
        
        // Setup general store items - organize by categories
        
        // Powerups section
        let powerupItems: [StoreItem] = [
            // Individual powerups
            StoreItem(
                name: "Swap Pack",
                description: "1x Swap tiles on the board",
                iconName: PowerupType.swap.iconName,
                price: .coins(100), // As requested, 100 coins
                itemType: .powerup(.swap),
                accentColor: .orange
            ),
            StoreItem(
                name: "Wildcard Pack",
                description: "1x Use any letter you want",
                iconName: PowerupType.wildcard.iconName,
                price: .coins(150), // As requested, 150 coins
                itemType: .powerup(.wildcard),
                accentColor: .purple
            ),
            StoreItem(
                name: "Extra Life Pack",
                description: "1x Continue playing after game over",
                iconName: PowerupType.extraLife.iconName,
                price: .coins(300), // As requested, 300 coins
                itemType: .powerup(.extraLife),
                accentColor: .red
            ),
            // 10 packs
            StoreItem(
                name: "10 Swaps",
                description: "Get 10 swap powerups",
                iconName: PowerupType.swap.iconName,
                price: .coins(900), // 10% discount on buying 10
                itemType: .bundle([.swap], amounts: [10]),
                accentColor: .orange
            ),
            StoreItem(
                name: "10 Wildcards",
                description: "Get 10 wildcard powerups",
                iconName: PowerupType.wildcard.iconName,
                price: .coins(1350), // 10% discount on buying 10
                itemType: .bundle([.wildcard], amounts: [10]),
                accentColor: .purple
            ),
            StoreItem(
                name: "10 Extra Lives",
                description: "Get 10 extra life powerups",
                iconName: PowerupType.extraLife.iconName,
                price: .coins(2700), // 10% discount on buying 10
                itemType: .bundle([.extraLife], amounts: [10]),
                accentColor: .red
            )
        ]
        
        // Coins section
        let coinItems: [StoreItem] = [
            StoreItem(
                name: "500 Coins",
                description: "Add 500 coins to your wallet",
                iconName: "dollarsign.circle.fill",
                price: .realMoney(0.99),
                itemType: .currency(.coins, amount: 500),
                accentColor: .yellow
            ),
            StoreItem(
                name: "2000 Coins",
                description: "Add 2000 coins to your wallet",
                iconName: "dollarsign.circle.fill",
                price: .realMoney(4.99),
                itemType: .currency(.coins, amount: 2000),
                accentColor: .yellow
            ),
            StoreItem(
                name: "5000 Coins",
                description: "Add 5000 coins to your wallet",
                iconName: "dollarsign.circle.fill",
                price: .realMoney(9.99),
                itemType: .currency(.coins, amount: 5000),
                accentColor: .yellow
            )
        ]
        
        // Diamonds section
        let diamondItems: [StoreItem] = [
            StoreItem(
                name: "5 Diamonds",
                description: "Add 5 diamonds to your wallet",
                iconName: "diamond_icon",
                price: .realMoney(0.99),
                itemType: .currency(.diamonds, amount: 5),
                accentColor: .cyan
            ),
            StoreItem(
                name: "20 Diamonds",
                description: "Add 20 diamonds to your wallet",
                iconName: "diamond_icon",
                price: .realMoney(4.99),
                itemType: .currency(.diamonds, amount: 20),
                accentColor: .cyan
            ),
            StoreItem(
                name: "50 Diamonds",
                description: "Add 50 diamonds to your wallet",
                iconName: "diamond_icon",
                price: .realMoney(9.99),
                itemType: .currency(.diamonds, amount: 50),
                accentColor: .cyan
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
                itemType: .bundle([.swap, .extraLife, .wildcard], amounts: [1, 1, 1], currencies: [.coins: 200]),
                accentColor: .green
            ),
            StoreItem(
                name: "Premium Bundle",
                description: "Get 3 of each powerup plus 500 coins",
                iconName: "star.fill",
                price: .diamonds(10),
                itemType: .bundle([.swap, .extraLife, .wildcard], amounts: [3, 3, 3], currencies: [.coins: 500]),
                accentColor: .pink
            ),
            StoreItem(
                name: "Video Reward",
                description: "Watch a video to get a random powerup",
                iconName: "play.rectangle.fill",
                price: .video,
                itemType: .random([.swap, .extraLife, .wildcard]),
                accentColor: .indigo
            )
        ]
    }
    
    // Listen for StoreKit transaction updates
    private func listenForTransactions() {
        // Start a task that will run for the lifetime of the app
        Task.detached(priority: .background) {
            // Iterate through any transactions that don't come from a direct call to `purchase()`
            for await verificationResult in Transaction.updates {
                // Check if the transaction is verified
                switch verificationResult {
                case .verified(let transaction):
                    // Handle the transaction on the main thread
                    await self.handleVerifiedTransaction(transaction)
                    // Always finish a transaction after handling it
                    await transaction.finish()
                case .unverified:
                    // Handle unverified transactions (e.g., log for investigation)
                    print("Unverified transaction received")
                }
            }
        }
    }
    
    // Handle a verified transaction
    @MainActor
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        // Find the matching product
        guard let product = storeProducts.first(where: { $0.id == transaction.productID }) else {
            print("No matching product found for transaction: \(transaction.productID)")
            return
        }
        
        // Find the matching store item
        if let matchingItem = findStoreItemForProduct(product) {
            // Deliver the purchased item
            deliverPurchasedItem(matchingItem)
            print("Transaction completed for product: \(product.id)")
        } else {
            // Create a temporary store item if no matching one is found
            let currencyType: CurrencyType = product.id.contains("COINS") ? .coins : .diamonds
            let amount: Int
            
            if product.id.contains("500") {
                amount = 500
            } else if product.id.contains("2000") {
                amount = 2000
            } else if product.id.contains("5000") {
                amount = 5000
            } else if product.id.contains("5") {
                amount = 5
            } else if product.id.contains("20") {
                amount = 20
            } else if product.id.contains("50") {
                amount = 50
            } else {
                amount = 0
            }
            
            if amount > 0 {
                let tempItem = StoreItem(
                    name: product.displayName,
                    description: product.description,
                    iconName: currencyType == .coins ? "dollarsign.circle.fill" : "diamond_icon",
                    price: .realMoney(product.price),
                    itemType: .currency(currencyType, amount: amount),
                    accentColor: currencyType == .coins ? .yellow : .cyan,
                    storeKitProduct: product
                )
                
                deliverPurchasedItem(tempItem)
                print("Transaction completed for product: \(product.id) using temporary item")
            } else if product.id == "WELCOME_PACK" {
                // Handle welcome pack
                let tempItem = StoreItem(
                    name: "Welcome Pack",
                    description: "Get 1 of each powerup plus 200 coins",
                    iconName: "gift.fill",
                    price: .realMoney(product.price),
                    itemType: .bundle([.swap, .extraLife, .wildcard], amounts: [1, 1, 1], currencies: [.coins: 200]),
                    accentColor: .green,
                    storeKitProduct: product
                )
                
                deliverPurchasedItem(tempItem)
                print("Transaction completed for Welcome Pack using temporary item")
            }
        }
    }
    
    // MARK: - StoreKit Integration
    
    // Fetch StoreKit products using RevenueCat
    @MainActor
    func fetchStoreKitProducts() async {
        do {
            // Request products directly from StoreKit
            let productIDs = [
                "COINS_500_UNITS",
                "COINS_2000_UNITS",
                "COINS_5000_UNITS",
                "DIAMONDS_5_UNITS",
                "DIAMONDS_20_UNITS",
                "DIAMONDS_50_UNITS",
                "WELCOME_PACK"
            ]
            
            // Request products from StoreKit
            let products = try await Product.products(for: productIDs)
            self.storeProducts = products
            self.productsLoaded = true
            
            // Update store items with actual StoreKit products
            updateStoreItemsWithStoreKitProducts()
            
            print("Successfully loaded \(products.count) StoreKit products")
        } catch {
            print("Failed to load StoreKit products: \(error)")
        }
    }
    
    // Update store items with actual StoreKit products
    private func updateStoreItemsWithStoreKitProducts() {
        // Map StoreKit products to existing store items
        for product in storeProducts {
            updateStoreItemWithProduct(product)
        }
    }
    
    // Update a specific store item with a StoreKit product
    private func updateStoreItemWithProduct(_ product: Product) {
        // Find matching store items based on product ID
        switch product.id {
        case "COINS_500_UNITS":
            updateCoinItem(product, amount: 500)
        case "COINS_2000_UNITS":
            updateCoinItem(product, amount: 2000)
        case "COINS_5000_UNITS":
            updateCoinItem(product, amount: 5000)
        case "DIAMONDS_5_UNITS":
            updateDiamondItem(product, amount: 5)
        case "DIAMONDS_20_UNITS":
            updateDiamondItem(product, amount: 20)
        case "DIAMONDS_50_UNITS":
            updateDiamondItem(product, amount: 50)
        case "WELCOME_PACK":
            updateSpecialOfferItem(product, name: "Welcome Pack")
        default:
            break
        }
    }
    
    // Update coin items with StoreKit product
    private func updateCoinItem(_ product: Product, amount: Int) {
        for i in 0..<generalItems.count {
            if case .currency(.coins, let itemAmount) = generalItems[i].itemType, itemAmount == amount,
               case .realMoney = generalItems[i].price {
                let updatedItem = StoreItem(
                    id: generalItems[i].id,
                    name: product.displayName,
                    description: product.description,
                    iconName: generalItems[i].iconName,
                    price: .realMoney(product.price),
                    itemType: generalItems[i].itemType,
                    accentColor: generalItems[i].accentColor,
                    storeKitProduct: product
                )
                generalItems[i] = updatedItem
            }
        }
    }
    
    // Update diamond items with StoreKit product
    private func updateDiamondItem(_ product: Product, amount: Int) {
        for i in 0..<generalItems.count {
            if case .currency(.diamonds, let itemAmount) = generalItems[i].itemType, itemAmount == amount,
               case .realMoney = generalItems[i].price {
                let updatedItem = StoreItem(
                    id: generalItems[i].id,
                    name: product.displayName,
                    description: product.description,
                    iconName: generalItems[i].iconName,
                    price: .realMoney(product.price),
                    itemType: generalItems[i].itemType,
                    accentColor: generalItems[i].accentColor,
                    storeKitProduct: product
                )
                generalItems[i] = updatedItem
            }
        }
    }
    
    // Update special offer items with StoreKit product
    private func updateSpecialOfferItem(_ product: Product, name: String) {
        for i in 0..<specialOffers.count {
            if specialOffers[i].name == name, case .realMoney = specialOffers[i].price {
                let updatedItem = StoreItem(
                    id: specialOffers[i].id,
                    name: product.displayName,
                    description: product.description,
                    iconName: specialOffers[i].iconName,
                    price: .realMoney(product.price),
                    itemType: specialOffers[i].itemType,
                    accentColor: specialOffers[i].accentColor,
                    storeKitProduct: product
                )
                specialOffers[i] = updatedItem
            }
        }
    }
    
    // Handle a StoreKit purchase transaction
    @MainActor
    func handlePurchase(for product: Product) async -> Bool {
        do {
            // Direct StoreKit purchase
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check if the transaction is verified
                switch verification {
                case .verified(let transaction):
                    // Handle the verified transaction
                    print("Transaction verified for product: \(product.id)")
                    
                    // Find matching store item and deliver it
                    if let matchingItem = findStoreItemForProduct(product) {
                        deliverPurchasedItem(matchingItem)
                    } else {
                        // Handle the case when no matching item is found
                        deliverProductContent(product.id)
                    }
                    
                    // Finish the transaction
                    await transaction.finish()
                    return true
                    
                case .unverified:
                    print("Transaction unverified for product: \(product.id)")
                    return false
                }
                
            case .userCancelled:
                print("User cancelled purchase for product: \(product.id)")
                return false
                
            case .pending:
                print("Purchase pending for product: \(product.id)")
                return false
                
            @unknown default:
                print("Unknown purchase result for product: \(product.id)")
                return false
            }
        } catch {
            print("Error purchasing product \(product.id): \(error)")
            return false
        }
    }
    
    // Helper method to deliver content based on product ID
    private func deliverProductContent(_ productId: String) {
        switch productId {
        case "COINS_500_UNITS":
            addCoins(500)
        case "COINS_2000_UNITS":
            addCoins(2000)
        case "COINS_5000_UNITS":
            addCoins(5000)
        case "DIAMONDS_5_UNITS":
            addDiamonds(5)
        case "DIAMONDS_20_UNITS":
            addDiamonds(20)
        case "DIAMONDS_50_UNITS":
            addDiamonds(50)
        case "WELCOME_PACK":
            addCoins(200)
            addPowerup(.swap, amount: 1)
            addPowerup(.extraLife, amount: 1)
            addPowerup(.wildcard, amount: 1)
        default:
            print("Unknown product ID: \(productId)")
        }
        
        // Save user data after delivering content
        userData.saveUserData()
    }
    
    // Restore purchases
    func restorePurchases() async -> Bool {
        do {
            // Direct StoreKit restore
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    // Process the transaction
                    print("Restored transaction: \(transaction.productID)")
                    deliverProductContent(transaction.productID)
                    
                    // Finish the transaction
                    await transaction.finish()
                }
            }
            
            print("Purchases restored successfully")
            return true
        } catch {
            print("Failed to restore purchases: \(error)")
            return false
        }
    }
    
    // Find a store item that matches a StoreKit product
    private func findStoreItemForProduct(_ product: Product) -> StoreItem? {
        // Look in general items
        for item in generalItems {
            if item.storeKitProduct?.id == product.id {
                return item
            }
        }
        
        // Look in special offers
        for item in specialOffers {
            if item.storeKitProduct?.id == product.id {
                return item
            }
        }
        
        // Look in daily deals
        for item in dailyDeals {
            if item.storeKitProduct?.id == product.id {
                return item
            }
        }
        
        return nil
    }
    
    // MARK: - Inventory Methods
    
    // Get coins
    func getCoins() -> Int {
        return userInventory.coins
    }
    
    // Get diamonds
    func getDiamonds() -> Int {
        return userInventory.diamonds
    }
    
    // Add coins
    func addCoins(_ amount: Int) {
        userInventory.coins += amount
        userData.saveUserData()
    }
    
    // Use coins
    func useCoins(_ amount: Int) -> Bool {
        guard userInventory.coins >= amount else { return false }
        userInventory.coins -= amount
        userData.saveUserData()
        return true
    }
    
    // Add diamonds
    func addDiamonds(_ amount: Int) {
        userInventory.diamonds += amount
        userData.saveUserData()
    }
    
    // Use diamonds
    func useDiamonds(_ amount: Int) -> Bool {
        guard userInventory.diamonds >= amount else { return false }
        userInventory.diamonds -= amount
        userData.saveUserData()
        return true
    }
    
    // Add powerup
    func addPowerup(_ type: PowerupType, amount: Int = 1) {
        userInventory.powerups[type, default: 0] += amount
        userData.saveUserData()
    }
    
    // Use powerup
    func usePowerup(_ type: PowerupType) -> Bool {
        guard getPowerupCount(type) > 0 else { return false }
        userInventory.powerups[type]! -= 1
        userData.saveUserData()
        return true
    }
    
    // Get powerup count
    func getPowerupCount(_ type: PowerupType) -> Int {
        return userInventory.powerups[type] ?? 0
    }
    
    // MARK: - Promo Codes
    
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
            addCoins(500)
            addPowerup(.swap, amount: 1)
            return (true, "You received 500 coins and 1 swap powerup!")
            
        case "LIBRARIOFUN":
            addDiamonds(5)
            return (true, "You received 5 diamonds!")
            
        case "BOOKWORM":
            addPowerup(.extraLife, amount: 2)
            return (true, "You received 2 extra lives!")
            
        case "WORDMASTER":
            addPowerup(.wildcard, amount: 2)
            return (true, "You received 2 wildcards!")
            
        case "POWERUP50":
            addPowerup(.swap, amount: 1)
            addPowerup(.extraLife, amount: 1)
            addPowerup(.wildcard, amount: 1)
            return (true, "You received 1 of each powerup!")
            
        default:
            return (false, "Error processing promo code.")
        }
    }
    
    // MARK: - Purchase Methods
    
    // Purchase an item
    func purchaseItem(_ item: StoreItem) async -> Bool {
        // For StoreKit products, use the StoreKit purchase flow
        if let storeKitProduct = item.storeKitProduct {
            return await handlePurchase(for: storeKitProduct)
        }
        
        // For non-StoreKit purchases, use the regular flow
        // Check if the user can afford the item
        switch item.price {
        case .coins(let amount):
            guard useCoins(amount) else { return false }
        case .diamonds(let amount):
            guard useDiamonds(amount) else { return false }
        case .realMoney:
            // This should not happen for non-StoreKit items
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
    
    // Synchronous version for backward compatibility
    func purchaseItem(_ item: StoreItem) -> Bool {
        // For StoreKit products, defer to async method
        if item.storeKitProduct != nil {
            Task {
                let success = await purchaseItem(item)
                // This won't be used immediately, but provides feedback in the UI
                return success
            }
            return true // Return optimistically for UI feedback
        }
        
        // For non-StoreKit purchases, use the regular flow
        // Check if the user can afford the item
        switch item.price {
        case .coins(let amount):
            guard useCoins(amount) else { return false }
        case .diamonds(let amount):
            guard useDiamonds(amount) else { return false }
        case .realMoney:
            // This should not happen for non-StoreKit items
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
        // Add item to user's inventory
        switch item.itemType {
        case .powerup(let powerupType):
            addPowerup(powerupType)
        case .currency(let currencyType, let amount):
            switch currencyType {
            case .coins:
                addCoins(amount)
            case .diamonds:
                addDiamonds(amount)
            }
        case .bundle(let powerups, let amounts, let currencies):
            // Add powerups
            for (index, powerup) in powerups.enumerated() {
                let amount = index < amounts.count ? amounts[index] : 1
                addPowerup(powerup, amount: amount)
            }
            
            // Add currencies
            for (currency, amount) in currencies {
                switch currency {
                case .coins:
                    addCoins(amount)
                case .diamonds:
                    addDiamonds(amount)
                }
            }
        case .random(let possiblePowerups):
            // Select a random powerup
            if let randomPowerup = possiblePowerups.randomElement() {
                addPowerup(randomPowerup)
            }
        }
        
        // Check if this is a daily deal
        if dailyDeals.contains(where: { $0.id == item.id }) {
            purchasedDailyDeals.insert(item.id)
            savePurchasedDailyDeals()
        }
        
        // Mark special offers and daily deals as purchased (one-time only items)
        // General store items can be purchased multiple times
        let isGeneralStoreItem = generalItems.contains { $0.id == item.id }
        if !isGeneralStoreItem {
            markItemAsPurchased(item)
        }
    }
    
    // Watch a video to get a powerup (placeholder implementation)
    func watchVideoForPowerup(_ type: PowerupType) {
        // In a real implementation, this would show a video ad
        // For now, just grant the powerup
        addPowerup(type)
    }
    
    // Generate new daily deals by randomly selecting 3 new deals from the entire pool
    private func generateDailyDeals() {
        // Make sure we have deals in the pool
        guard !allPossibleDailyDeals.isEmpty else { return }
        
        // Get 3 random deals from the complete pool
        var randomDeals: [StoreItem] = []
        var selectedIndices = Set<Int>()
        
        // Try to select 3 unique deals
        let numDealsToSelect = min(3, allPossibleDailyDeals.count)
        while randomDeals.count < numDealsToSelect {
            let randomIndex = Int.random(in: 0..<allPossibleDailyDeals.count)
            
            // Only add if not already selected for today
            if !selectedIndices.contains(randomIndex) {
                selectedIndices.insert(randomIndex)
                randomDeals.append(allPossibleDailyDeals[randomIndex])
            }
        }
        
        // Update the daily deals both in memory and for persistence
        dailyDealsForToday = randomDeals
        dailyDeals = randomDeals
        
        // Save the daily deals to persist across app sessions
        saveDailyDeals()
    }
    
    // Public method for manually refreshing deals (for testing/debugging)
    func forceRefreshDailyDeals() {
        generateDailyDeals()
        saveLastRefreshDate(Date())
        
        // Clear purchased daily deals for the new deals
        purchasedDailyDeals.removeAll()
        savePurchasedDailyDeals()
    }
}
