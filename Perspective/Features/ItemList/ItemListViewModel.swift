//
//  ItemListViewModel.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import Foundation
import SwiftData
import UserNotifications

@Observable
class ItemListViewModel {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func delete(_ item: Item) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.notificationIdentifier])
        modelContext.delete(item)
    }
    
    func logUsage(for item: Item) {
        let usage = Usage(date: .now, item: item)
        item.usages.append(usage)
    }
    
    func displayedCost(for item: Item, currency: Currency) -> (value: Double, unit: String) {
        switch item.calculationMode {
        case .perDay:
            return (item.costPerDay(in: currency), "day")
        case .perUse:
            if let cost = item.costPerUse(in: currency) {
                return (cost, "use")
            }
            return (item.convertedPrice(to: currency), "use")
        }
    }
}
