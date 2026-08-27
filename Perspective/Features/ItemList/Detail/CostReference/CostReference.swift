//
//  CostReference.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 27/08/2026.
//

import Foundation

struct CostReference {
    let name: String
    let price: Double
}

let costReferences: [CostReference] = [
    CostReference(name: "a pencil ✏️", price: 0.60),
    CostReference(name: "a baguette 🥖", price: 1.2),
    CostReference(name: "a metro ticket 🚇", price: 2.0),
    CostReference(name: "a coffee ☕️", price: 3.0),
    CostReference(name: "a sandwich 🥪", price: 5.0),
    CostReference(name: "a fast food menu 🍔", price: 9.0),
    CostReference(name: "a movie ticket 🎬", price: 12.0),
    CostReference(name: "a month of Netflix 📺", price: 15.0),
    CostReference(name: "a restaurant lunch 🧑‍🍳", price: 18.0),
    CostReference(name: "a t-shirt 👕", price: 35.0),
    CostReference(name: "a pair of jeans 👖", price: 50.0),
    CostReference(name: "a tank of gas ⛽️", price: 70.0),
    CostReference(name: "a nice dinner for two 🍱", price: 80.0),
    CostReference(name: "a short-haul flight ✈️", price: 120.0),
    CostReference(name: "a video-game console 🎮", price: 500.0),
    CostReference(name: "a smartphone 📱", price: 800.0)
]

struct CostComparison {
    let text: String
}

func costComparison(for value: Double, in currency: Currency) -> CostComparison? {
    guard value > 0 else { return nil }
    
    let valueInEUR = value / currency.eurConversionRate
    let sorted = costReferences.sorted { $0.price < $1.price }
    
    if let nextAbove = sorted.first(where: { $0.price >= valueInEUR }) {
        return CostComparison(text: "less than \(nextAbove.name)")
    }
    
    if let mostExpensive = sorted.last {
        return nil
    }
    
    return nil
}
