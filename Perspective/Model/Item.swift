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
    var currency: Currency = Currency.eur
    
    @Relationship(deleteRule: .cascade, inverse: \Usage.item)
    var usages: [Usage] = []
    
    init(name: String, price: Double, purchaseDate: Date, calculationMode: CalculationMode, category: String? = nil, currency: Currency = .eur) {
        self.name = name
        self.price = price
        self.purchaseDate = purchaseDate
        self.calculationMode = calculationMode
        self.currency = currency
    }
}

extension Item {
    
    // MARK: - Ownership duration
    
    var daysOwned: Int {
        let calendar = Calendar.current
        let purchaseDay = calendar.startOfDay(for: purchaseDate)
        let today = calendar.startOfDay(for: .now)
        let days = calendar.dateComponents([.day], from: purchaseDay, to: today).day ?? 0
        return max(1, days + 1)
    }
    
    // MARK: - Currency conversion
    
    func convertedPrice(to displayCurrency: Currency) -> Double {
        let valueInEUR = price / currency.eurConversionRate
        return valueInEUR * displayCurrency.eurConversionRate
    }
    
    // MARK: - Cost calculations
    
    func costPerDay(in displayCurrency: Currency) -> Double {
        convertedPrice(to: displayCurrency) / Double(daysOwned)
    }
    
    func costPerUse(in displayCurrency: Currency) -> Double? {
        guard !usages.isEmpty else { return nil }
        return convertedPrice(to: displayCurrency) / Double(usages.count)
    }
    
    var averageUsesPerWeek: Double? {
        guard !usages.isEmpty else { return nil }
        let weeks = Double(daysOwned) / 7.0
        return Double(usages.count) / weeks
    }
    
    // MARK: - Symbolic thresholds
    
    static let symbolicThresholds: [Double] = [50, 20, 10, 5, 2, 1, 0.5, 0.1]
    
    func nextThreshold(in currency: Currency) -> (value: Double, daysUntil: Int)? {
        let current = costPerDay(in: currency)
        
        guard let threshold = Item.symbolicThresholds.first(where: { $0 < current }) else {
            return nil
        }
        
        let convertedPrice = convertedPrice(to: currency)
        let daysNeeded = Int((convertedPrice / threshold).rounded(.up))
        let daysRemaining = daysNeeded - daysOwned
        
        guard daysRemaining > 0 else { return nil }
        return (threshold, daysRemaining)
    }
    
    // MARK: - Ranking
    
    func isBestValue(among items: [Item], currency: Currency) -> Bool {
        let dailyItems = items.filter { $0.calculationMode == .perDay }
        guard dailyItems.count >= 2 else { return false }
        guard let best = dailyItems.min(by: { $0.costPerDay(in: currency) < $1.costPerDay(in: currency) }) else {
            return false
        }
        return best.id == self.id
    }
    
    // MARK: - Notifications
    
    var notificationIdentifier: String {
        "threshold-\(persistentModelID)"
    }
}
