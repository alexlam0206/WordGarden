import SwiftUI

struct LearnView: View {
    @State private var selectedTab = 0
    @State private var showingFocusView = false
    @AppStorage("navigationTarget") private var navigationTarget: String?
    @AppStorage("navigationWord") private var navigationWord: String?
    @State private var destination: String?

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
            .onAppear {
                if let navigationTarget = navigationTarget {
                    destination = navigationTarget
                }
            }
            .sheet(item: $destination) { destination in
                switch destination {
                case "addWord":
                    AddWordView(wordStorage: WordStorage(), word: navigationWord)
                case "flashcards":
                    FlashcardsView()
                case "discover":
                    DiscoverView()
                case "practice":
                    LearnView()
                default:
                    EmptyView()
                }
            }
            .onChange(of: navigationTarget) {
                if let navigationTarget = navigationTarget {
                    destination = navigationTarget
                }
            }
        }
    }
}

extension String: Identifiable {
    public var id: String { self }
}
