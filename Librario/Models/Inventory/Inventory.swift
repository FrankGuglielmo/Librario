//
//  Inventory.swift
//  Librario
//
//  Created on 3/8/2025.
//

import Foundation
import Observation

@Observable class Inventory: Codable {
    // Player wallet
    var coins: Int = 0
    var diamonds: Int = 0
    
    // Powerups dictionary
    var powerups: [PowerupType: Int] = [
        .swap: 0,
        .extraLife: 0,
        .wildcard: 0
    ]
    
    // Coding keys
    private enum CodingKeys: String, CodingKey {
        case coins, diamonds, powerups
    }
    
    // Default initializer
    init() {}
    
    // Codable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coins = try container.decode(Int.self, forKey: .coins)
        diamonds = try container.decode(Int.self, forKey: .diamonds)
        powerups = try container.decode([PowerupType: Int].self, forKey: .powerups)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coins, forKey: .coins)
        try container.encode(diamonds, forKey: .diamonds)
        try container.encode(powerups, forKey: .powerups)
    }
}
