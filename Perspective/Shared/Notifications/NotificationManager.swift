//
//  NotificationManager.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 08/09/2026.
//

import Foundation
import SwiftData
import UserNotifications

enum NotificationManager {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    static func scheduleThresholdNotification(for item: Item, currency: Currency) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.notificationIdentifier])
        
        guard let next = item.nextThreshold(in: currency) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = item.name
        content.body = "Just dropped under \(next.value.formatted(.currency(code: currency.rawValue)))/day!"
        content.sound = .default
        
        let triggerDate = Calendar.current.date(byAdding: .day, value: next.daysUntil, to: .now) ?? .now
        var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        components.hour = 9
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: item.notificationIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
