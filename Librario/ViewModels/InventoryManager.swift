//
//  InventoryManager.swift
//  Librario
//
//  Created on 3/8/2025.
//

import Foundation
import Observation

@Observable class InventoryManager {
    private var inventory: Inventory
    private var saveCallback: () -> Void
    
    // Initializer
    init(inventory: Inventory, saveCallback: @escaping () -> Void) {
        self.inventory = inventory
        self.saveCallback = saveCallback
    }
    
    // MARK: - Wallet Management
    
    func addCoins(_ amount: Int) {
        inventory.coins += amount
        saveInventory()
    }
    
    func useCoins(_ amount: Int) -> Bool {
        guard inventory.coins >= amount else { return false }
        inventory.coins -= amount
        saveInventory()
        return true
    }
    
    func getCoins() -> Int {
        return inventory.coins
    }
    
    func addDiamonds(_ amount: Int) {
        inventory.diamonds += amount
        saveInventory()
    }
    
    func useDiamonds(_ amount: Int) -> Bool {
        guard inventory.diamonds >= amount else { return false }
        inventory.diamonds -= amount
        saveInventory()
        return true
    }
    
    func getDiamonds() -> Int {
        return inventory.diamonds
    }
    
    // MARK: - Powerup Management
    
    func addPowerup(_ type: PowerupType, amount: Int = 1) {
        inventory.powerups[type, default: 0] += amount
        saveInventory()
    }
    
    func usePowerup(_ type: PowerupType) -> Bool {
        guard getPowerupCount(type) > 0 else { return false }
        inventory.powerups[type]! -= 1
        saveInventory()
        return true
    }
    
    func getPowerupCount(_ type: PowerupType) -> Int {
        return inventory.powerups[type] ?? 0
    }
    
    // MARK: - Persistence
    
    private func saveInventory() {
        saveCallback()
    }
}
