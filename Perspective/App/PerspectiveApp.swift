//
//  PerspectiveApp.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import SwiftData
import SwiftUI

@main
struct PerspectiveApp: App {
    @State private var profileViewModel = ProfileViewModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(profileViewModel)
                .onAppear {
                    NotificationManager.requestAuthorization()
                }
        }
           .modelContainer(for: Item.self)
       }
}
