

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @State private var showingAddWordSheet = false
    @State private var isEditing = false
    @State private var selection = Set<UUID>()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                List(selection: $selection) {
                    ForEach($wordStorage.words) { $word in
                        NavigationLink(destination: WordDetailView(word: $word)) {
                            Text(word.text)
                        }
                    }
                    .onDelete(perform: deleteWords)
                }
                .navigationTitle("WordGarden 🌿")
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
                
                // Floating Action Button
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
    }

    private func deleteWords(at offsets: IndexSet) {
        wordStorage.words.remove(atOffsets: offsets)
    }

    private func deleteSelectedWords() {
        wordStorage.words.removeAll { selection.contains($0.id) }
        selection.removeAll()
        isEditing = false
    }
}

struct AddWordView: View {
    @ObservedObject var wordStorage: WordStorage
    @Environment(\.presentationMode) var presentationMode
    @State private var text = ""
    @State private var definition = ""
    @State private var example = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Word", text: $text)
                TextField("Definition (optional)", text: $definition)
                TextField("Example Sentence(optional)", text: $example)
            }
            .navigationTitle("Add New Word")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                wordStorage.addWord(text: text, definition: definition, example: example)
                wordStorage.addLogEntry("Added word: \(text)")
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WordStorage())
    }
}
