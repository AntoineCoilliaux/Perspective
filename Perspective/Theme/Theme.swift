//
//  Theme.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 17/09/2026.
//

import SwiftUI

// MARK: - Color helpers

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
    
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Theme

enum Theme {
    
    // MARK: Surfaces
    
    static let background = Color(light: Color(hex: 0xEFEFEA), dark: Color(hex: 0x14171C))
    static let card       = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1C2028))
    static let cardAlt    = Color(light: Color(hex: 0xF7F6F1), dark: Color(hex: 0x232833))
    static let border     = Color(light: Color(hex: 0xE1DFD7), dark: Color(hex: 0x2A2F39))
    
    // MARK: Text
    
    static let text1 = Color(light: Color(hex: 0x1D1C19), dark: Color(hex: 0xECEEF0))
    static let text2 = Color(light: Color(hex: 0x7A776D), dark: Color(hex: 0x8B909C))
    static let text3 = Color(light: Color(hex: 0xA6A399), dark: Color(hex: 0x565C68))
    
    // MARK: Accents
    
    static let gold  = Color(light: Color(hex: 0x9C7A1F), dark: Color(hex: 0xC9A227))
    static let slate = Color(light: Color(hex: 0x33475B), dark: Color(hex: 0x7C93B8))
    static let teal  = Color(light: Color(hex: 0x3E8878), dark: Color(hex: 0x5CAE9E))
    static let rust  = Color(light: Color(hex: 0xA85A40), dark: Color(hex: 0xC36A50))
    
    static let goldBg  = Color(light: Color(hex: 0xF3ECDA), dark: Color(hex: 0xC9A227).opacity(0.13))
    static let slateBg = Color(light: Color(hex: 0xE7ECF0), dark: Color(hex: 0x7C93B8).opacity(0.14))
    static let tealBg  = Color(light: Color(hex: 0xE3EFEB), dark: Color(hex: 0x5CAE9E).opacity(0.15))
    static let rustBg  = Color(light: Color(hex: 0xF4E6E0), dark: Color(hex: 0xC36A50).opacity(0.16))
    
    // MARK: Typography
    
    /// Set to "Fraunces" once the font files are bundled in the project.
    private static let serifName: String? = nil
    
    static func serif(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        if let serifName {
            return .custom(serifName, size: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .serif)
    }
    
    // MARK: Metrics
    
    static let cardRadius: CGFloat = 16
    static let bannerRadius: CGFloat = 12
}

// MARK: - Reusable modifiers

struct ThemeCard: ViewModifier {
    var padding: CGFloat = 18
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}

extension View {
    func themeCard(padding: CGFloat = 18) -> some View {
        modifier(ThemeCard(padding: padding))
    }
}

struct ThemeBanner: View {
    let text: String
    let systemImage: String?
    let tint: Color
    let background: Color
    
    init(_ text: String, systemImage: String? = nil, tint: Color, background: Color) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
        self.background = background
    }
    
    var body: some View {
        Group {
            if let systemImage {
                Label(text, systemImage: systemImage)
            } else {
                Text(text)
            }
        }
        .font(.subheadline)
        .foregroundStyle(tint)
        .multilineTextAlignment(.center)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(background, in: RoundedRectangle(cornerRadius: Theme.bannerRadius))
    }
}
