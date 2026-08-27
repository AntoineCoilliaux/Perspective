//
//  Currency.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

enum Currency: String, Codable, CaseIterable, Identifiable {
    case eur = "EUR"
    case usd = "USD"
    case gbp = "GBP"
    case chf = "CHF"
    case cad = "CAD"
    case aud = "AUD"
    case sek = "SEK"
    case nzd = "NZD"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .eur: return "€"
        case .usd: return "$"
        case .gbp: return "£"
        case .chf: return "CHF"
        case .cad: return "CA$"
        case .aud: return "A$"
        case .sek: return "kr"
        case .nzd: return "NZ$"
        }
    }
}

extension Currency {
    var eurConversionRate: Double {
        switch self {
        case .eur: return 1.0
        case .usd: return 1.08
        case .gbp: return 0.85
        case .chf: return 0.94
        case .cad: return 1.47
        case .aud: return 1.63
        case .sek: return 11.2
        case .nzd: return 1.77
        }
    }
}
