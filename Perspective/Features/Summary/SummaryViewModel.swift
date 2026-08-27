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
    
    func totalCostPerDay(items: [Item]) -> Double {
        items
            .filter { $0.calculationMode == .perDay }
            .reduce(0) { $0 + $1.costPerDay }
    }

    func totalCostPerUse(items: [Item]) -> Double {
        items
            .filter { $0.calculationMode == .perUse }
            .compactMap { $0.costPerUse }
            .reduce(0, +)
    }
    
    func monthlySpending(items: [Item]) -> [MonthlyTotal] {
        let dailyItems = items.filter { $0.calculationMode == .perDay }
        let calendar = Calendar.current
        
        guard let earliest = dailyItems.map(\.purchaseDate).min(),
              let latest = dailyItems.map(\.purchaseDate).max() else {
            return []
        }
        
        let spanInMonths = calendar.dateComponents([.month], from: earliest, to: latest).month ?? 0
        let groupByYear = spanInMonths > 24
        
        let grouped = Dictionary(grouping: dailyItems) { item in
            groupByYear
                ? calendar.dateComponents([.year], from: item.purchaseDate)
                : calendar.dateComponents([.year, .month], from: item.purchaseDate)
        }
        
        let totals = grouped.map { components, items in
            MonthlyTotal(
                date: calendar.date(from: components) ?? .now,
                total: items.reduce(0) { $0 + $1.price }
            )
        }
        
        return totals.sorted { $0.date < $1.date }
    }
    
    struct MonthlyTotal: Identifiable {
        let id = UUID()
        let date: Date
        let total: Double
    }
    
    struct EvolutionPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    func costPerDayEvolution(items: [Item]) -> [EvolutionPoint] {
        let dailyItems = items.filter { $0.calculationMode == .perDay }
        guard let earliestDate = dailyItems.map(\.purchaseDate).min() else { return [] }
        
        let calendar = Calendar.current
        let totalDays = calendar.dateComponents([.day], from: earliestDate, to: .now).day ?? 0
        guard totalDays > 0 else { return [] }
        
        let stepCount = min(totalDays + 1, 30)
        let stride = max(1, totalDays / stepCount)
        
        return Swift.stride(from: 0, through: totalDays, by: stride).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: earliestDate) ?? .now
            let total = dailyItems
                .filter { $0.purchaseDate <= date }
                .reduce(0.0) { total, item in
                    let daysOwned = max(1, (calendar.dateComponents([.day], from: item.purchaseDate, to: date).day ?? 0) + 1)
                    return total + (item.price / Double(daysOwned))
                }
            return EvolutionPoint(date: date, value: total)
        }
    }
}
