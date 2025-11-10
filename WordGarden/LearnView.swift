
import SwiftUI

struct LearnView: View {
    @State private var selectedTab = 0
    @State private var showingFocusView = false

    var body: some View {
        NavigationView {
            VStack {
                Picker("Learn", selection: $selectedTab) {
                    Text("Words").tag(0)
                    Text("Flashcards").tag(1)
                    Text("Tree").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                Spacer()

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
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFocusView = true
                    }) {
                        Label("Focus", systemImage: "leaf.fill")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingFocusView) {
                FocusView()
            }
        }
    }
}
