//
//  WordGardenApp.swift
//  WordGarden
//
//  Created by Alex Lam on 8/11/2025.
//


import SwiftUI

@main
struct WordGardenApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Vocabulary", systemImage: "book.fill")
                }
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}