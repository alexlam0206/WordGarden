import SwiftUI
import Firebase

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
            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
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
        .onAppear {
            wordStorage.addLogEntry("Opened app")
        }
    }
}
