//
//  Usage.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import Foundation
import SwiftData

@Model
class Usage {
    var date: Date
    var item: Item?
    
    init(date: Date = .now, item: Item? = nil) {
        self.date = date
        self.item = item
    }
}
