
import SwiftUI
import SafariServices

struct SettingsView: View {
    @State private var showingClearCacheAlert = false
    @State private var selectedURL: URL?
    @State private var showSafari: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cache")) {
                    Button("Clear Word Cache") {
                        showingClearCacheAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("API Credits")) {
                    Button("Free Dictionary API") {
                        selectedURL = URL(string: "https://dictionaryapi.dev/")
                        showSafari = true
                    }
                    Button("Datamuse API") {
                        selectedURL = URL(string: "https://www.datamuse.com/api/")
                        showSafari = true
                    }
                }

                Section(header: Text("About Us")) {
                    Button("nok.is-a.dev") {
                        selectedURL = URL(string: "https://nok.is-a.dev/")
                        showSafari = true
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showingClearCacheAlert) {
                Alert(
                    title: Text("Clear Cache"),
                    message: Text("Are you sure you want to delete all cached word definitions?"),
                    primaryButton: .destructive(Text("Clear")) {
                        CacheManager.shared.clearCache()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showSafari) {
                if let url = selectedURL {
                    SafariView(url: url)
                }
            }
        }
    }
}

// Wrapper for SFSafariViewController
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No update needed
    }
}
