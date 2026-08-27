//
//  ProfileViewModel.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import Foundation

@Observable
class ProfileViewModel {
    var profile: UserProfile {
        didSet {
            save()
        }
    }
    
    private let defaultsKey = "userProfile"
    
    init() {
        self.profile = Self.load() ?? UserProfile()
    }
    
    var isComplete: Bool {
        profile.computedHourlyRate != nil
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }
    
    private static func load() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return decoded
    }
}
