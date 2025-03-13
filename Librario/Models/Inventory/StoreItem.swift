//
//  StoreModels.swift
//  Librario
//
//  Created on 3/8/2025.
//

import Foundation
import StoreKit
import SwiftUI

// MARK: - Store Item
struct StoreItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let iconName: String
    let price: Price
    let itemType: StoreItemType
    let accentColor: Color?
    
    // StoreKit product (not stored in Codable)
    var storeKitProduct: Product?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, iconName, price, itemType, accentColor
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String,
        price: Price,
        itemType: StoreItemType,
        accentColor: Color? = nil,
        storeKitProduct: Product? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.price = price
        self.itemType = itemType
        self.accentColor = accentColor
        self.storeKitProduct = storeKitProduct
    }
    
    // Custom Codable implementation to handle the Color property
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        iconName = try container.decode(String.self, forKey: .iconName)
        price = try container.decode(Price.self, forKey: .price)
        itemType = try container.decode(StoreItemType.self, forKey: .itemType)
        
        // Handle optional Color decoding
        if container.contains(.accentColor) {
            do {
                accentColor = try container.decode(Color.self, forKey: .accentColor)
            } catch {
                print("Error decoding accentColor: \(error)")
                accentColor = nil
            }
        } else {
            accentColor = nil
        }
        
        // StoreKit product is not stored in Codable
        storeKitProduct = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(price, forKey: .price)
        try container.encode(itemType, forKey: .itemType)
        
        // Only encode accentColor if it exists
        if let accentColor = accentColor {
            try container.encode(accentColor, forKey: .accentColor)
        }
        
        // StoreKit product is not encoded
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
    case realMoney(Decimal)
    case video
    
    var displayString: String {
        switch self {
        case .coins(let amount):
            return "\(amount) Coins"
        case .diamonds(let amount):
            return "\(amount) Diamonds"
        case .realMoney(let amount):
            return "$\(String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue))"
        case .video:
            return "Watch Video"
        }
    }
    
    // Codable implementation
    private enum CodingKeys: String, CodingKey {
        case type, amount
    }
    
    private enum PriceType: String, Codable {
        case coins, diamonds, realMoney, video
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .coins(let amount):
            try container.encode(PriceType.coins, forKey: .type)
            try container.encode(amount, forKey: .amount)
        case .diamonds(let amount):
            try container.encode(PriceType.diamonds, forKey: .type)
            try container.encode(amount, forKey: .amount)
        case .realMoney(let amount):
            try container.encode(PriceType.realMoney, forKey: .type)
            try container.encode(amount, forKey: .amount)
        case .video:
            try container.encode(PriceType.video, forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PriceType.self, forKey: .type)
        
        switch type {
        case .coins:
            let amount = try container.decode(Int.self, forKey: .amount)
            self = .coins(amount)
        case .diamonds:
            let amount = try container.decode(Int.self, forKey: .amount)
            self = .diamonds(amount)
        case .realMoney:
            let amount = try container.decode(Decimal.self, forKey: .amount)
            self = .realMoney(amount)
        case .video:
            self = .video
        }
    }
}
