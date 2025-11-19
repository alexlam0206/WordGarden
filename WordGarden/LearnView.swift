import SwiftUI

struct LearnView: View {
    @State private var selectedTab = 0
    @State private var showingFocusView = false
    @AppStorage("navigationTarget") private var navigationTarget: String?
    @AppStorage("navigationWord") private var navigationWord: String?
    @State private var destination: String?
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented picker in navigation bar
                HStack {
                    Spacer()
                    Picker("Learn", selection: $selectedTab) {
                        Text("Words").tag(0)
                        Text("Flashcards").tag(1)
                        Text("Tree").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 300)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)

                // Search bar below segmented picker (only for Words tab)
                if selectedTab == 0 {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search words...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial.opacity(0.5))
                }

                // Main content
                Group {
                    switch selectedTab {
                    case 0:
                        ContentView(searchText: $searchText)
                    case 1:
                        FlashcardsView()
                    case 2:
                        TreeView()
                    default:
                        ContentView(searchText: $searchText)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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

struct LearnView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { LearnView() }
            .preferredColorScheme(.light)
    }
}

extension String: Identifiable {
    public var id: String { self }
}
