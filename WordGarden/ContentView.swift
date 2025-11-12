
import SwiftUI

// The main view of the application, displaying the list of words.
struct ContentView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @State private var showingAddWordSheet = false
    @State private var isEditing = false
    @State private var selection = Set<UUID>()
    @State private var showingDeleteConfirmation = false
    @State private var searchText = ""

    var filteredWords: [Binding<Word>] {
        $wordStorage.words.filter { $0.wrappedValue.text.localizedCaseInsensitiveContains(searchText) || searchText.isEmpty }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if wordStorage.words.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView()
                    Spacer()
                }
            } else {
                List(selection: $selection) {
                    ForEach(filteredWords) { $word in
                        NavigationLink(destination: WordDetailView(word: $word)) {
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
            .padding(.bottom, wordStorage.words.isEmpty ? 40 : 0)
        }
        .searchable(text: $searchText)
        .navigationTitle("WordGarden")
        .navigationBarTitleDisplayMode(.inline)
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
        let wordIdsToDelete = offsets.map { filteredWords[$0].wrappedValue.id }
        wordStorage.words.removeAll(where: { wordIdsToDelete.contains($0.id) })
    }

    private func deleteSelectedWords() {
        wordStorage.words.removeAll(where: { selection.contains($0.id) })
        selection.removeAll()
        isEditing = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with words
        ContentView()
            .environmentObject(WordStorage())

        // Preview with empty state
        let emptyStorage = WordStorage()
        emptyStorage.words = []
        return ContentView()
            .environmentObject(emptyStorage)
            .previewDisplayName("Empty State")

    }
}
