//
//  WordGardenApp.swift
//  WordGarden
//
//  Created by Alex Lam on 8/11/2025.
//


import SwiftUI

@main
struct WordGardenApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()

    init() {
        NotificationManager.shared.requestAuthorization()
        GoogleSignInManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(authViewModel)
        }
    }
}

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel

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