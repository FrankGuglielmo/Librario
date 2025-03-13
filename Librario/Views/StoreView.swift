//
//  StoreView.swift
//  Librario
//
//  Created on 3/8/2025.
//

import SwiftUI
import StoreKit

fileprivate var GENERAL_STORE_THEME: CardColor = .teal
fileprivate var SPECIAL_STORE_THEME: CardColor = .crimson
fileprivate var TODAYS_DEAL_THEME: CardColor = .tangerine
fileprivate var INVENTORY_THEME: CardColor = .lavender

struct StoreView: View {
    @Binding var navigationPath: NavigationPath
    @State var storeManager: StoreManager
    @State private var selectedPowerup: PowerupType?
    @State private var showingPurchaseError = false
    @State private var showingRestoreSuccess = false
    @State private var purchaseInProgress = false
    
    // User data for inventory access
    var userData: UserData
    
    init(userData: UserData, storeManager: StoreManager, navigationPath: Binding<NavigationPath>) {
        self._navigationPath = navigationPath
        self.userData = userData
        self.storeManager = storeManager
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
                        Text("\(storeManager.getCoins()) Coins")
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
                        Image("diamond_icon")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text("\(storeManager.getDiamonds()) Diamonds")
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
                        subtitle: "Great Deals Refreshed Daily!",
                        cardColor: TODAYS_DEAL_THEME,
                        tabIcon: "tag.fill"
                    ) {
                        TodaysDealsView(storeManager: storeManager, theme: TODAYS_DEAL_THEME)
                    },
                    
                    // General Store Card
                    Card(
                        title: "General Store",
                        cardColor: GENERAL_STORE_THEME,
                        tabIcon: "cart.fill"
                    ) {
                        GeneralStoreView(storeManager: storeManager, theme: GENERAL_STORE_THEME)
                    },
                    
                    // Special Offers Card
                    Card(
                        title: "Special Offers",
                        cardColor: SPECIAL_STORE_THEME,
                        tabIcon: "gift.fill"
                    ) {
                        SpecialOffersView(storeManager: storeManager, theme: SPECIAL_STORE_THEME)
                    },
                    
                    // Inventory Card
                    Card(
                        title: "Inventory",
                        cardColor: INVENTORY_THEME,
                        tabIcon: "bag.fill"
                    ) {
                        InventoryCardView(storeManager: storeManager, theme: INVENTORY_THEME)
                    }
                ])
            }
        }
    }
}

// MARK: - Today's Deals View
struct TodaysDealsView: View {
    var storeManager: StoreManager
    var theme: CardColor
    @State private var showingPurchaseError = false
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(storeManager.dailyDeals) { item in
                StoreItemView(item: item, cardColor: theme, storeManager: storeManager) {
                    handlePurchase(item)
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

// MARK: - Purchase Handling for Today's Deals
extension TodaysDealsView {
    func handlePurchase(_ item: StoreItem) {
        Task {
            if case .realMoney = item.price, let _ = item.storeKitProduct {
                // For StoreKit products, use async purchase flow
                let success = await storeManager.purchaseItem(item)
                if !success {
                    DispatchQueue.main.async {
                        showingPurchaseError = true
                    }
                }
            } else {
                // For non-StoreKit products, use synchronous flow
                let success = await storeManager.purchaseItem(item)
                if !success {
                    showingPurchaseError = true
                }
            }
        }
    }
}

// MARK: - General Store View
struct GeneralStoreView: View {
    var storeManager: StoreManager
    var theme: CardColor
    @State private var showingPurchaseError = false
    
    // Filter items by type
    private var powerupItems: [StoreItem] {
        storeManager.generalItems.filter { item in
            if case .powerup = item.itemType { return true }
            if case .bundle(let powerups, _, _) = item.itemType, !powerups.isEmpty { return true }
            return false
        }
    }
    
    private var coinItems: [StoreItem] {
        storeManager.generalItems.filter { item in
            if case .currency(.coins, _) = item.itemType { return true }
            return false
        }
    }
    
    private var diamondItems: [StoreItem] {
        storeManager.generalItems.filter { item in
            if case .currency(.diamonds, _) = item.itemType { return true }
            return false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Powerups Section
                if !powerupItems.isEmpty {
                    SectionHeaderView(title: "Powerups", theme: theme)
                    
                    ForEach(powerupItems) { item in
                        StoreItemView(item: item, cardColor: theme, storeManager: storeManager) {
                            handlePurchase(item)
                        }
                    }
                    
                    Divider()
                        .background(theme.borderColor)
                        .padding(.vertical, 10)
                }
                
                // Coins Section
                if !coinItems.isEmpty {
                    SectionHeaderView(title: "Coins", theme: theme)
                    
                    ForEach(coinItems) { item in
                        StoreItemView(item: item, cardColor: theme, storeManager: storeManager) {
                            handlePurchase(item)
                        }
                    }
                    
                    Divider()
                        .background(theme.borderColor)
                        .padding(.vertical, 10)
                }
                
                // Diamonds Section
                if !diamondItems.isEmpty {
                    SectionHeaderView(title: "Diamonds", theme: theme)
                    
                    ForEach(diamondItems) { item in
                        StoreItemView(item: item, cardColor: theme, storeManager: storeManager) {
                            handlePurchase(item)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Inventory Card View
struct InventoryCardView: View {
    var storeManager: StoreManager
    var theme: CardColor
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Powerups Section with title
                Text("Powerups")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textColor)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(theme.primaryColor.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.top, 8)
                
                // Swap powerup
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: PowerupType.swap.iconName)
                        .resizable()
                        .foregroundColor(theme.accentColor)
                        .frame(width: 30, height: 30)
                        
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swap:")
                            .font(.subheadline)
                            .foregroundColor(theme.textColor)
                        Text("\(storeManager.getPowerupCount(.swap))")
                            .font(.title3)
                            .foregroundColor(theme.textColor)
                    }
                }
                .padding(.vertical, 8)
                
                // Extra Life powerup
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: PowerupType.extraLife.iconName)
                        .resizable()
                        .foregroundColor(theme.accentColor)
                        .frame(width: 30, height: 30)
                        
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Life:")
                            .font(.subheadline)
                            .foregroundColor(theme.textColor)
                        Text("\(storeManager.getPowerupCount(.extraLife))")
                            .font(.title3)
                            .foregroundColor(theme.textColor)
                    }
                }
                .padding(.vertical, 8)
                
                // Wildcard powerup
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: PowerupType.wildcard.iconName)
                        .resizable()
                        .foregroundColor(theme.accentColor)
                        .frame(width: 30, height: 30)
                        
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wild:")
                            .font(.subheadline)
                            .foregroundColor(theme.textColor)
                        Text("\(storeManager.getPowerupCount(.wildcard))")
                            .font(.title3)
                            .foregroundColor(theme.textColor)
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                    .background(theme.borderColor)
                    .padding(.vertical, 10)
                
                // Currencies Section with title
                Text("Currencies")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textColor)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(theme.primaryColor.opacity(0.7))
                    .cornerRadius(8)
                
                // Coins
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "dollarsign.circle.fill")
                        .resizable()
                        .foregroundColor(.yellow)
                        .frame(width: 30, height: 30)
                        
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coins:")
                            .font(.subheadline)
                            .foregroundColor(theme.textColor)
                        Text("\(storeManager.getCoins())")
                            .font(.title3)
                            .foregroundColor(theme.textColor)
                    }
                }
                .padding(.vertical, 8)
                
                // Diamonds
                HStack(alignment: .center, spacing: 16) {
                    Image("diamond_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Diamonds:")
                            .font(.subheadline)
                            .foregroundColor(theme.textColor)
                        Text("\(storeManager.getDiamonds())")
                            .font(.title3)
                            .foregroundColor(theme.textColor)
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Section Header View
struct SectionHeaderView: View {
    var title: String
    var theme: CardColor
    
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(theme.textColor)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(theme.primaryColor.opacity(0.7))
            .cornerRadius(8)
    }
}

// MARK: - Purchase Handling for General Store
extension GeneralStoreView {
    func handlePurchase(_ item: StoreItem) {
        Task {
            if case .realMoney = item.price, let _ = item.storeKitProduct {
                // For StoreKit products, use async purchase flow
                let success = await storeManager.purchaseItem(item)
                if !success {
                    DispatchQueue.main.async {
                        showingPurchaseError = true
                    }
                }
            } else {
                // For non-StoreKit products, use synchronous flow
                let success = await storeManager.purchaseItem(item)
                if !success {
                    showingPurchaseError = true
                }
            }
        }
    }
}

// MARK: - Special Offers View
struct SpecialOffersView: View {
    var storeManager: StoreManager
    var theme: CardColor
    @State private var promoCode: String = ""
    @State private var promoMessage: String = ""
    @State private var isPromoValid: Bool = false
    @State private var showPromoMessage: Bool = false
    @State private var showingPurchaseError = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Special offers section
                ForEach(storeManager.specialOffers) { item in
                    StoreItemView(item: item, cardColor: theme, storeManager: storeManager) {
                        handlePurchase(item)
                    }
                }
                
                Divider()
                    .background(theme.borderColor)
                    .padding(.vertical, 10)
                
                // Promo code section
                SectionHeaderView(title: "Promo Code", theme: theme)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter a promo code to receive special rewards!")
                        .foregroundColor(.white)
                        .font(.subheadline)
                    
                    HStack {
                        TextField("Enter code", text: $promoCode)
                            .padding(10)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                            .foregroundColor(.black)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                        
                        Button(action: {
                            let result = storeManager.validatePromoCode(promoCode)
                            promoMessage = result.message
                            isPromoValid = result.isValid
                            showPromoMessage = true
                            
                            // Clear the field if valid
                            if result.isValid {
                                promoCode = ""
                            }
                            
                            // Auto-hide message after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showPromoMessage = false
                            }
                        }) {
                            Text("Submit")
                                .foregroundColor(theme.textColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(theme.primaryColor)
                                .cornerRadius(8)
                        }
                        .disabled(promoCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if showPromoMessage {
                        Text(promoMessage)
                            .foregroundColor(isPromoValid ? .green : .red)
                            .font(.subheadline)
                            .padding(.top, 5)
                            .transition(.opacity)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Store Item View
struct StoreItemView: View {
    let item: StoreItem
    let cardColor: CardColor
    let storeManager: StoreManager
    let onPurchase: () -> Void
    @State private var isPurchasing = false
    @State private var showingDetail = false
    
    // Create a custom item with accent color from card color if not provided
    private var customItem: StoreItem {
        if item.accentColor != nil {
            return item
        } else {
            // Create a Color that best matches the CardColor
            let color: Color
            switch cardColor {
            case .teal:
                color = .cyan
            case .crimson:
                color = .red
            case .tangerine:
                color = .orange
            default:
                color = .blue
            }
            
            return StoreItem(
                id: item.id,
                name: item.name,
                description: item.description,
                iconName: item.iconName,
                price: item.price,
                itemType: item.itemType,
                accentColor: color,
                storeKitProduct: item.storeKitProduct
            )
        }
    }
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
                Rectangle()
                    .fill(cardColor.primaryColor.opacity(0.4))
                    .blur(radius: 4)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.clear)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                    .border(cardColor.borderColor, width: 6)
                    .cornerRadius(10)
                
                
                HStack {
                    HStack(alignment: .center, spacing: 10) {
                        FlexibleImageView(iconName: item.iconName,
                                                 foregroundColor: cardColor.textColor,
                                                 fontSize: .largeTitle)
                                    .frame(width: 50, height: 50)
                                    .background(cardColor.primaryColor.opacity(0.6))
                                    .cornerRadius(5)
                        
                        
                        Text(item.name)
                            .font(.headline)
                            .foregroundColor(cardColor.textColor)
                    }
                    .padding(.leading)
                    Spacer()
                    
                    // Price display
                    Group {
                        switch item.price {
                        case .coins(let amount):
                            HStack {
                                Text("\(amount)")
                                    .foregroundColor(cardColor.textColor)
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(cardColor.accentColor)
                            .cornerRadius(20)
                            
                        case .diamonds(let amount):
                            HStack {
                                Text("\(amount)")
                                    .foregroundColor(cardColor.textColor)
                                Image("diamond_icon")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(cardColor.complementaryColor)
                            .cornerRadius(20)
                            
                        case .realMoney(let amount):
                            Text(item.storeKitProduct?.displayPrice ?? "$\(String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue))")
                                .foregroundColor(cardColor.textColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(cardColor.accentColor)
                                .cornerRadius(20)
                            
                        case .video:
                            HStack {
                                Text("Watch")
                                    .foregroundColor(cardColor.textColor)
                                Image(systemName: "movieclapper")
                                    .foregroundColor(cardColor.textColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(cardColor.primaryColor)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.trailing)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPurchasing)
        .sheet(isPresented: $showingDetail) {
            StoreItemDetailView(
                item: customItem,
                storeManager: storeManager,
                onPurchase: {
                    // Set purchasing state for real money items
                    if case .realMoney = item.price {
                        isPurchasing = true
                    }
                    
                    // Try to purchase the item
                    onPurchase()
                    
                    // For non-real money purchases, immediately reset the state
                    if case .realMoney = item.price { } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isPurchasing = false
                        }
                    }
                }
            )
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Purchase Handling for Special Offers
extension SpecialOffersView {
    func handlePurchase(_ item: StoreItem) {
        Task {
            if case .realMoney = item.price, let _ = item.storeKitProduct {
                // For StoreKit products, use async purchase flow
                let success = await storeManager.purchaseItem(item)
                if !success {
                    DispatchQueue.main.async {
                        showingPurchaseError = true
                    }
                }
            } else {
                // For non-StoreKit products, use synchronous flow
                let success = await storeManager.purchaseItem(item)
                if !success {
                    showingPurchaseError = true
                }
            }
        }
    }
}

// MARK: - Purchase Handling for Store View

extension StoreView {
    // Handle purchase of a store item
    func handlePurchase(_ item: StoreItem) {
        if case .realMoney = item.price, case _ = item.storeKitProduct {
            // For StoreKit products, use async purchase flow
            purchaseInProgress = true
            
            Task {
                let success = await storeManager.purchaseItem(item)
                
                // Update UI on the main thread
                DispatchQueue.main.async {
                    purchaseInProgress = false
                    if !success {
                        showingPurchaseError = true
                    }
                }
            }
        } else {
            // For non-StoreKit products, use synchronous flow
            if !storeManager.purchaseItem(item) {
                showingPurchaseError = true
            }
        }
    }
}

#Preview {
    // Create a temporary userData and store manager for preview
    let userData = UserData()
    let storeManager = StoreManager(userData: userData)
    StoreView(
        userData: userData, storeManager: storeManager,
        navigationPath: .constant(NavigationPath())
    )
}
