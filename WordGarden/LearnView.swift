
import SwiftUI

struct LearnView: View {
    @State private var selectedTab = 0
    @State private var showingFocusView = false

    var body: some View {
        NavigationView {
            VStack {
                switch selectedTab {
                case 0:
                    ContentView()
                case 1:
                    FlashcardsView()
                case 2:
                    TreeView()
                default:
                    ContentView()
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Learn", selection: $selectedTab) {
                        Text("Words").tag(0)
                        Text("Flashcards").tag(1)
                        Text("Tree").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 300)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFocusView = true
                    }) {
                        Label("Focus", systemImage: "moon.fill")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingFocusView) {
                FocusView()
            }
        }
    }
}
