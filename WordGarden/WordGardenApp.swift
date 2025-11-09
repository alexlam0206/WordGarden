// All changes after that commit have been discarded, and the working directory is now at that state.

import SwiftUI
import Firebase

// All changes after that commit have been discarded, and the working directory is now at that state.

@main
struct WordGardenApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var wordStorage = WordStorage()
    @StateObject private var treeService = TreeService()
    @StateObject private var cloudSyncManager = CloudSyncManager.shared

    init() {
        FirebaseApp.configure()
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(authViewModel)
                .environmentObject(wordStorage)
                .environmentObject(treeService)
                .environmentObject(cloudSyncManager)
        }
    }
}

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var wordStorage: WordStorage

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Vocabulary", systemImage: "book.fill")
                }

            FlashcardsView()
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.stack.fill")
                }

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }



            TreeView()
                .tabItem {
                    Label("Tree", systemImage: "tree.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            wordStorage.addLogEntry("Opened app")
        }
    }
}