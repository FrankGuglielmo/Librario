//
//  StoreModels.swift
//  Librario
//
//  Created on 3/8/2025.
//

import Foundation

// MARK: - Store Item
struct StoreItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let iconName: String
    let price: Price
    let itemType: StoreItemType
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String,
        price: Price,
        itemType: StoreItemType
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.price = price
        self.itemType = itemType
    }
}

// MARK: - Store Item Type
enum StoreItemType: Codable {
    case powerup(PowerupType)
    case currency(CurrencyType, amount: Int)
    case bundle([PowerupType], amounts: [Int], currencies: [CurrencyType: Int] = [:])
    case random([PowerupType])
}

// MARK: - Currency Type
enum CurrencyType: String, Codable {
    case coins
    case diamonds
}

// MARK: - Price
enum Price: Codable {
    case coins(Int)
    case diamonds(Int)
    case realMoney(Double)
    case video
    
    var displayString: String {
        switch self {
        case .coins(let amount):
            return "\(amount) Coins"
        case .diamonds(let amount):
            return "\(amount) Diamonds"
        case .realMoney(let amount):
            return "$\(String(format: "%.2f", amount))"
        case .video:
            return "Watch Video"
        }
    }
}
