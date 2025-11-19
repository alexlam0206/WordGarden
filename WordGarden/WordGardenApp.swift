import SwiftUI

@main
struct WordGardenApp: App {
    @StateObject private var wordStorage = WordStorage()
    @StateObject private var treeService = TreeService()

    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
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
            .environmentObject(wordStorage)
            .environmentObject(treeService)
            
        }
    }
}

struct MainView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
                LearnView()
                    .tabItem {
                        Label("Learn", systemImage: "book.fill")
                    }
                    .tag(0)

                DiscoverView()
                    .tabItem {
                        Label("Discover", systemImage: "sparkles")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(2)
        }
        .onAppear {
            wordStorage.addLogEntry("Opened app")

            // Add glassmorphism effect to tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        .onOpenURL { url in
            // Handle deep links from widgets
            if url.scheme == "wordgarden" {
                switch url.host {
                case "learn":
                    selectedTab = 0
                case "discover":
                    selectedTab = 1
                case "settings":
                    selectedTab = 2
                default:
                    break
                }
            }
        }
    }
}
