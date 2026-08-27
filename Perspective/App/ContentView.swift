//
//  ContentView.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(0)
            
            ItemListView()
                .tabItem {
                    Label("Items", systemImage: "cart")
                }
                .tag(1)
            
            SummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
