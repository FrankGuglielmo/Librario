//
//  PowerupType.swift
//  Librario
//
//  Created on 3/8/2025.
//

import Foundation

enum PowerupType: String, Codable, CaseIterable {
    case swap
    case extraLife
    case wildcard
    
    var iconName: String {
        switch self {
        case .swap: return "arrow.2.squarepath"
        case .extraLife: return "heart.fill"
        case .wildcard: return "sparkles"
        }
    }
    
    var displayName: String {
        switch self {
        case .swap: return "Swap"
        case .extraLife: return "Life"
        case .wildcard: return "Wild"
        }
    }
    
    var basePrice: Int {
        switch self {
        case .swap: return 100      // Cheapest
        case .extraLife: return 150 // Middle
        case .wildcard: return 200  // Most expensive
        }
    }
}
