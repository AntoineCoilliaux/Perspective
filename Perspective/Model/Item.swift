//
//  Item.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import Foundation
import SwiftData

enum CalculationMode: String, Codable, CaseIterable {
    case perDay
    case perUse
}

@Model
class Item {
    var name: String
    var price: Double
    var purchaseDate: Date
    var calculationMode: CalculationMode
    
    @Relationship(deleteRule: .cascade, inverse: \Usage.item)
    var usages: [Usage] = []
    
    init(name: String, price: Double, purchaseDate: Date, calculationMode: CalculationMode) {
        self.name = name
        self.price = price
        self.purchaseDate = purchaseDate
        self.calculationMode = calculationMode
    }
}

extension Item {
    var daysOwned: Int {
        let days = Calendar.current.dateComponents([.day], from: purchaseDate, to: .now).day ?? 0
        return max(1, days + 1)
    }
    
    var costPerDay: Double {
        price / Double(daysOwned)
    }
    
    var costPerUse: Double? {
        guard !usages.isEmpty else { return nil }
        return price / Double(usages.count)
    }
    
    var averageUsesPerWeek: Double? {
        guard !usages.isEmpty else { return nil }
        let weeks = Double(daysOwned) / 7.0
        return Double(usages.count) / weeks
    }
}
