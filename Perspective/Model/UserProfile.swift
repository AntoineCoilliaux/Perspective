//
//  UserProfile.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import Foundation

struct UserProfile: Codable {
    var name: String?
    var salary: Double?
    var salaryType: SalaryType = .monthly
    var hoursPerWeek: Double?
    var currency: Currency = .eur
    
    enum SalaryType: String, Codable {
        case monthly
        case weekly
        case hourly
    }
    
    var computedHourlyRate: Double? {
        guard let salary, let hoursPerWeek, hoursPerWeek > 0 else { return nil }
        switch salaryType {
        case .hourly:
            return salary
            case .weekly:
            return salary / hoursPerWeek
        case .monthly:
            return salary / (hoursPerWeek * 52 / 12)
        }
    }
}
