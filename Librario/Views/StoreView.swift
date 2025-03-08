//
//  StoreView.swift
//  Librario
//
//  Created on 3/8/2025.
//

import SwiftUI

struct StoreView: View {
    @Binding var navigationPath: NavigationPath
    @State private var storeManager: StoreManager
    @State private var selectedPowerup: PowerupType?
    
    // Observe inventory manager to update wallet display
    var inventoryManager: InventoryManager
    
    init(inventoryManager: InventoryManager, navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath
        self.inventoryManager = inventoryManager
        self._storeManager = State(initialValue: StoreManager(inventoryManager: inventoryManager))
    }
    
    var body: some View {
        ZStack {
            // Background image
            Image("Background_Image_2")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Wallet display
                HStack {
                    Spacer()
                    
                    // Coins
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                        Text("\(inventoryManager.getCoins()) Coins")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    
                    Spacer().frame(width: 16)
                    
                    // Diamonds
                    HStack {
                        Image(systemName: "diamond.fill")
                            .foregroundColor(.cyan)
                        Text("\(inventoryManager.getDiamonds()) Diamonds")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    
                    Spacer()
                }
                .padding(.top, 16)
                
                // Store cards
                CardView(cards: [
                    // Today's Deals Card
                    Card(
                        title: "Today's Deals",
                        subtitle: "Special offers refreshed daily",
                        cardColor: .tangerine,
                        tabIcon: "tag.fill"
                    ) {
                        TodaysDealsView(storeManager: storeManager)
                    },
                    
                    // General Store Card
                    Card(
                        title: "General Store",
                        subtitle: "Powerups and currency",
                        cardColor: .emerald,
                        tabIcon: "cart.fill"
                    ) {
                        GeneralStoreView(storeManager: storeManager)
                    },
                    
                    // Special Offers Card
                    Card(
                        title: "Special Offers",
                        subtitle: "Limited time bundles and discounts",
                        cardColor: .sapphire,
                        tabIcon: "gift.fill"
                    ) {
                        SpecialOffersView(storeManager: storeManager)
                    }
                ])
            }
        }
    }
}

// MARK: - Today's Deals View
struct TodaysDealsView: View {
    var storeManager: StoreManager
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(storeManager.dailyDeals) { item in
                StoreItemView(item: item) {
                    _ = storeManager.purchaseItem(item)
                }
            }
            
            if storeManager.dailyDeals.isEmpty {
                Text("No deals available today. Check back tomorrow!")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
    }
}

// MARK: - General Store View
struct GeneralStoreView: View {
    var storeManager: StoreManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(storeManager.generalItems) { item in
                    StoreItemView(item: item) {
                        _ = storeManager.purchaseItem(item)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Special Offers View
struct SpecialOffersView: View {
    var storeManager: StoreManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(storeManager.specialOffers) { item in
                    StoreItemView(item: item) {
                        _ = storeManager.purchaseItem(item)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Store Item View
struct StoreItemView: View {
    let item: StoreItem
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            // Item icon
            Image(systemName: item.iconName)
                .font(.largeTitle)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.7))
                .cornerRadius(15)
                .padding(.trailing, 8)
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Purchase button
            Button(action: onPurchase) {
                switch item.price {
                case .coins(let amount):
                    HStack {
                        Text("\(amount)")
                            .foregroundColor(.white)
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                    
                case .diamonds(let amount):
                    HStack {
                        Text("\(amount)")
                            .foregroundColor(.white)
                        Image(systemName: "diamond.fill")
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple)
                    .cornerRadius(20)
                    
                case .realMoney(let amount):
                    Text("$\(String(format: "%.2f", amount))")
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(20)
                    
                case .video:
                    HStack {
                        Text("Watch")
                            .foregroundColor(.white)
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(15)
    }
}

#Preview {
    // Create a temporary inventory and manager for preview
    let inventory = Inventory()
    let inventoryManager = InventoryManager(
        inventory: inventory,
        saveCallback: {}
    )
    return StoreView(
        inventoryManager: inventoryManager,
        navigationPath: .constant(NavigationPath())
    )
}
