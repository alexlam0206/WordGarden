import SwiftUI

// The main view of the application, displaying the list of words.
struct ContentView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @State private var showingAddWordSheet = false
    @State private var isEditing = false
    @State private var selection = Set<UUID>()
    @State private var showingDeleteConfirmation = false
    @Binding var searchText: String

    init(searchText: Binding<String> = .constant("")) {
        self._searchText = searchText
    }

    var filteredWords: [Word] {
        if searchText.isEmpty {
            return wordStorage.words
        } else {
            return wordStorage.words.filter { word in
                word.text.localizedCaseInsensitiveContains(searchText) ||
                word.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if wordStorage.words.isEmpty {
                EmptyStateView()
            } else {
                List(selection: $selection) {
                    ForEach(filteredWords) { word in
                        NavigationLink(destination: WordDetailView(word: .constant(word))) {
                            WordRowView(word: word)
                        }
                    }
                    .onDelete(perform: deleteWords)
                }
            }
            
            // Floating action button for adding a new word.
            Button(action: {
                showingAddWordSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.title.weight(.semibold))
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 4, x: 0, y: 4)
            }
            .padding()
        }
        .navigationTitle("WordGarden")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !wordStorage.words.isEmpty {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .disabled(selection.isEmpty)
                }
            }
        }
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
        .sheet(isPresented: $showingAddWordSheet) {
            AddWordView(wordStorage: wordStorage)
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

    private func deleteWords(at offsets: IndexSet) {
        let wordsToDelete = offsets.map { filteredWords[$0] }
        wordStorage.words.removeAll { word in
            wordsToDelete.contains(where: { $0.id == word.id })
        }
    }

    private func deleteSelectedWords() {
        wordStorage.words.removeAll { selection.contains($0.id) }
        selection.removeAll()
        isEditing = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let emptyStorage = WordStorage()
        emptyStorage.words = []
        return Group {
            ContentView()
                .environmentObject(WordStorage())
            ContentView()
                .environmentObject(emptyStorage)
                .previewDisplayName("Empty State")
        }
    }
}
