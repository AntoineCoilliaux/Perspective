//
//  Worktime.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 17/09/2026.
//

import Foundation

enum WorkTime {
    /// Short form used in list chips: "2 min", "1,4 h"
    static func shortText(cost: Double, hourlyRate: Double) -> String? {
        guard hourlyRate > 0, cost > 0 else { return nil }
        let hours = cost / hourlyRate
        if hours < 1 {
            return "\(max(1, Int((hours * 60).rounded()))) min"
        }
        return "\(hours.formatted(.number.precision(.fractionLength(1))))h"
    }
    
    /// Long form used in detail banners: "equals 2 min of your work"
    static func longText(cost: Double, hourlyRate: Double) -> String? {
        guard let short = shortText(cost: cost, hourlyRate: hourlyRate) else { return nil }
        return "equals \(short) of your work"
    }
}
