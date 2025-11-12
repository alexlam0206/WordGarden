import SwiftUI

struct LearnView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @State private var selectedTab = 0
    @State private var showingFocusView = false
    @State private var isEditing = false
    @State private var selection = Set<UUID>()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationView {
            VStack {
                switch selectedTab {
                case 0:
                    ContentView(isEditing: $isEditing, selection: $selection)
                case 1:
                    FlashcardsView()
                case 2:
                    TreeView()
                default:
                    ContentView(isEditing: $isEditing, selection: $selection)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedTab == 0 && !wordStorage.words.isEmpty {
                        Button(isEditing ? "Done" : "Edit") {
                            isEditing.toggle()
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Learn", selection: $selectedTab) {
                        Text("Words").tag(0)
                        Text("Flashcards").tag(1)
                        Text("Tree").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 240)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing && selectedTab == 0 {
                        Button("Delete", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .disabled(selection.isEmpty)
                    } else {
                        Button(action: {
                            showingFocusView = true
                        }) {
                            Label("Focus", systemImage: "moon.fill")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingFocusView) {
                FocusView()
            }
            .alert("Delete Words", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedWords()
                }
            } message: {
                Text("Are you sure you want to delete the selected words?")
            }
        }
    }

    private func deleteSelectedWords() {
        wordStorage.words.removeAll(where: { selection.contains($0.id) })
        selection.removeAll()
        isEditing = false
    }
}