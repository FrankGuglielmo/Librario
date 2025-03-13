//
//  StoreItemDetailView.swift
//  Librario
//
//  Created on 3/11/2025.
//

import SwiftUI
import StoreKit

struct StoreItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: StoreItem
    let storeManager: StoreManager
    let onPurchase: () -> Void
    
    @State private var isPurchasing = false
    
    // Check if this is a consumable item
    private var isConsumable: Bool {
        switch item.itemType {
        case .currency:
            // Currency items are always consumable
            return true
        case .powerup, .bundle, .random:
            // These could be consumable if they're in the general store
            return storeManager.generalItems.contains { $0.id == item.id }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Item icon
            FlexibleImageView(iconName: item.iconName,
                             foregroundColor: item.accentColor ?? .primary,
                             fontSize: .system(size: 60))
                .frame(width: 100, height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill((item.accentColor ?? .blue).opacity(0.2))
                )
                .padding(.top, 30)
                .padding(.bottom, 10)
            
            // Item name and description
            Text(item.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(item.accentColor ?? .primary)
                .multilineTextAlignment(.center)
            
            Text(item.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            // Current inventory status
            CurrentInventoryView(item: item, storeManager: storeManager)
                .padding(.vertical, 5)
            
            // Purchase button
            Button(action: {
                isPurchasing = true
                onPurchase()
                
                // Always dismiss after a brief delay, but keep the purchasing state reset for consumables
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isConsumable {
                        isPurchasing = false
                    }
                    dismiss()
                }
            }) {
                HStack {
                    Text("Purchase")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    PriceView(item: item)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(item.accentColor ?? .blue)
                .cornerRadius(10)
                .opacity(isPurchasing ? 0.6 : 1.0)
            }
            .disabled(isPurchasing)
            .padding(.horizontal, 30)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .frame(minWidth: 300)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// Helper view to show the current inventory status
struct CurrentInventoryView: View {
    let item: StoreItem
    let storeManager: StoreManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Inventory Status")
                .font(.headline)
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            switch item.itemType {
            case .powerup(let powerupType):
                // Show current powerup count and what it will be after purchase
                HStack(spacing: 25) {
                    InventoryStatusItem(
                        label: "Current",
                        value: "\(storeManager.getPowerupCount(powerupType))",
                        icon: powerupType.iconName
                    )
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    InventoryStatusItem(
                        label: "After Purchase",
                        value: "\(storeManager.getPowerupCount(powerupType) + 1)",
                        icon: powerupType.iconName,
                        highlight: true
                    )
                }
                
            case .currency(let currencyType, let amount):
                // Show current currency amount and what it will be after purchase
                HStack(spacing: 25) {
                    InventoryStatusItem(
                        label: "Current",
                        value: currencyType == .coins ? 
                            "\(storeManager.getCoins())" : "\(storeManager.getDiamonds())",
                        icon: currencyType == .coins ? "dollarsign.circle.fill" : "diamond_icon"
                    )
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    
                    InventoryStatusItem(
                        label: "After Purchase",
                        value: currencyType == .coins ? 
                            "\(storeManager.getCoins() + amount)" : "\(storeManager.getDiamonds() + amount)",
                        icon: currencyType == .coins ? "dollarsign.circle.fill" : "diamond_icon",
                        highlight: true
                    )
                }
                
            case .bundle(let powerups, let amounts, let currencies):
                // Display detailed inventory impact for bundle items
                VStack(spacing: 12) {
                    // Show powerups
                    if !powerups.isEmpty {
                        ForEach(0..<powerups.count, id: \.self) { index in
                            let powerupType = powerups[index]
                            let amount = index < amounts.count ? amounts[index] : 1
                            
                            HStack(spacing: 20) {
                                InventoryStatusItem(
                                    label: powerupType.displayName,
                                    value: "\(storeManager.getPowerupCount(powerupType))",
                                    icon: powerupType.iconName
                                )
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .font(.caption)
                                
                                InventoryStatusItem(
                                    label: "After",
                                    value: "\(storeManager.getPowerupCount(powerupType) + amount)",
                                    icon: powerupType.iconName,
                                    highlight: true
                                )
                            }
                        }
                    }
                    
                    // Show currencies
                    ForEach(currencies.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { currency, amount in
                        HStack(spacing: 20) {
                            InventoryStatusItem(
                                label: currency == .coins ? "Coins" : "Diamonds",
                                value: currency == .coins ? 
                                    "\(storeManager.getCoins())" : "\(storeManager.getDiamonds())",
                                icon: currency == .coins ? "dollarsign.circle.fill" : "diamond_icon"
                            )
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .font(.caption)
                            
                            InventoryStatusItem(
                                label: "After",
                                value: currency == .coins ? 
                                    "\(storeManager.getCoins() + amount)" : "\(storeManager.getDiamonds() + amount)",
                                icon: currency == .coins ? "dollarsign.circle.fill" : "diamond_icon",
                                highlight: true
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
            case .random:
                Text("Receive a random powerup")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// Helper view for showing inventory quantities
struct InventoryStatusItem: View {
    let label: String
    let value: String
    let icon: String
    var highlight: Bool = false
    
    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            HStack(spacing: 3) {
                FlexibleImageView(iconName: icon,
                                 foregroundColor: highlight ? .blue : .gray,
                                 fontSize: .caption2)
                    .frame(width: 16, height: 16)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(highlight ? .bold : .regular)
                    .foregroundColor(highlight ? .blue : .primary)
            }
        }
        .padding(5)
        .background(highlight ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(5)
    }
}

// Helper view for showing price
struct PriceView: View {
    let item: StoreItem
    
    var body: some View {
        Group {
            switch item.price {
            case .coins(let amount):
                HStack {
                    Text("\(amount)")
                        .foregroundColor(.white)
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                }
                
            case .diamonds(let amount):
                HStack {
                    Text("\(amount)")
                        .foregroundColor(.white)
                    Image("diamond_icon")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                
            case .realMoney(let amount):
                Text(item.storeKitProduct?.displayPrice ?? "$\(String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue))")
                    .foregroundColor(.white)
                
            case .video:
                HStack {
                    Text("Watch")
                        .foregroundColor(.white)
                    Image(systemName: "movieclapper")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    let userData = UserData()
    let storeManager = StoreManager(userData: userData)
    
    StoreItemDetailView(
        item: StoreItem(
            name: "500 Coins",
            description: "Add 500 coins to your wallet",
            iconName: "dollarsign.circle.fill",
            price: .realMoney(0.99),
            itemType: .currency(.coins, amount: 500),
            accentColor: .yellow
        ),
        storeManager: storeManager,
        onPurchase: {}
    )
    .frame(width: 350)
}
