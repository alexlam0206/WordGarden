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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
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

            // Show onboarding on first launch
            if showOnboarding {
                OnboardingView(isOnboarding: $showOnboarding)
                    .transition(.opacity)
            }
        }
        .onAppear {
            wordStorage.addLogEntry("Opened app")

            // Check if this is first launch
            if !hasCompletedOnboarding {
                showOnboarding = true
            }

            // Add glassmorphism effect to tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onChange(of: showOnboarding) { oldValue, newValue in
            if !newValue {
                // Onboarding completed
                hasCompletedOnboarding = true
            }
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
