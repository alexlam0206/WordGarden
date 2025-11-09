
import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var wordStorage: WordStorage

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tasks")) {
                    Text("Complete daily word challenges")
                    // Add more task items here
                }
                Section(header: Text("Discover")) {
                    Text("Discover new words here!")
                }
            }
            .navigationTitle("Discover")
        }
        .onAppear {
            wordStorage.addLogEntry("Opened Discover tab")
        }
    }
}
