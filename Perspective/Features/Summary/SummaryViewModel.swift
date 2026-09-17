//
//  SummaryViewModel.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import Foundation
import SwiftData

@Observable
class SummaryViewModel {
    
    // MARK: - Types
    
    struct EvolutionPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    struct ItemHighlight {
        let item: Item
        let costPerDay: Double
    }
    
    // MARK: - Totals
    
    func totalCostPerDay(items: [Item], currency: Currency) -> Double {
        items
            .filter { $0.calculationMode == .perDay }
            .reduce(0) { $0 + $1.costPerDay(in: currency) }
    }
    
    func totalCostPerUse(items: [Item], currency: Currency) -> Double {
        items
            .filter { $0.calculationMode == .perUse }
            .compactMap { $0.costPerUse(in: currency) }
            .reduce(0) { $0 + $1 }
    }
    
    // MARK: - Monthly spending
    
    func cumulativeInvestment(items: [Item], currency: Currency) -> [EvolutionPoint] {
        let dailyItems = items/*.filter { $0.calculationMode == .perDay }*/
        guard let earliestDate = dailyItems.map(\.purchaseDate).min() else { return [] }
        
        let calendar = Calendar.current
        let earliestDay = calendar.startOfDay(for: earliestDate)
        let today = calendar.startOfDay(for: .now)
        let totalDays = calendar.dateComponents([.day], from: earliestDay, to: today).day ?? 0
        guard totalDays > 0 else { return [] }
        
        var offsets = Set<Int>()
        offsets.insert(0)
        offsets.insert(totalDays)
        for item in dailyItems {
            let offset = calendar.dateComponents([.day], from: earliestDay, to: calendar.startOfDay(for: item.purchaseDate)).day ?? 0
            offsets.insert(max(0, offset))
        }
        
        return offsets.sorted().map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: earliestDay) ?? .now
            let total = dailyItems
                .filter { calendar.startOfDay(for: $0.purchaseDate) <= date }
                .reduce(0.0) { $0 + $1.convertedPrice(to: currency) }
            return EvolutionPoint(date: date, value: total)
        }
    }
    
    // MARK: - Cost/day evolution
    
    func costPerDayEvolution(items: [Item], currency: Currency) -> [EvolutionPoint] {
        let dailyItems = items.filter { $0.calculationMode == .perDay }
        guard let earliestDate = dailyItems.map(\.purchaseDate).min() else { return [] }
        
        let calendar = Calendar.current
        let earliestDay = calendar.startOfDay(for: earliestDate)
        let today = calendar.startOfDay(for: .now)
        let totalDays = calendar.dateComponents([.day], from: earliestDay, to: today).day ?? 0
        guard totalDays > 0 else { return [] }
        
        var offsets = Set<Int>()
        offsets.insert(0)
        offsets.insert(totalDays)
        
        for item in dailyItems {
            let purchaseOffset = calendar.dateComponents([.day], from: earliestDay, to: calendar.startOfDay(for: item.purchaseDate)).day ?? 0
            offsets.insert(max(0, purchaseOffset))
            offsets.insert(min(totalDays, purchaseOffset + 1))
        }
        
        let stepCount = 30
        let step = max(1, totalDays / stepCount)
        for offset in Swift.stride(from: 0, through: totalDays, by: step) {
            offsets.insert(offset)
        }
        
        return offsets.sorted().map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: earliestDay) ?? .now
            let total = dailyItems
                .filter { calendar.startOfDay(for: $0.purchaseDate) <= date }
                .reduce(0.0) { total, item in
                    let purchaseDay = calendar.startOfDay(for: item.purchaseDate)
                    let daysOwned = max(1, (calendar.dateComponents([.day], from: purchaseDay, to: date).day ?? 0) + 1)
                    return total + (item.convertedPrice(to: currency) / Double(daysOwned))
                }
            return EvolutionPoint(date: date, value: total)
        }
    }
    
    // MARK: - Rankings
    
    func mostAndLeastCostEffective(items: [Item], currency: Currency) -> (best: ItemHighlight, worst: ItemHighlight)? {
        let dailyItems = items.filter { $0.calculationMode == .perDay }
        guard dailyItems.count >= 2 else { return nil }
        
        let ranked = dailyItems
            .map { ItemHighlight(item: $0, costPerDay: $0.costPerDay(in: currency)) }
            .sorted { $0.costPerDay < $1.costPerDay }
        
        guard let best = ranked.first, let worst = ranked.last else { return nil }
        return (best, worst)
    }
}
