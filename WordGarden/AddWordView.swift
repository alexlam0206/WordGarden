import SwiftUI

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
                TextField("Example Sentence (optional)", text: $example)
            }
            .navigationTitle("Add New Word")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                // Ensure the word is not just whitespace.
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    wordStorage.addWord(text: text, definition: definition, example: example)
                    wordStorage.addLogEntry("Added word: \(text)")
                    presentationMode.wrappedValue.dismiss()
                }
            })
        }
    }
}
