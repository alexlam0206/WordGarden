// All changes after that commit have been discarded, and the working directory is now at that state.

import SwiftUI
import AVFoundation

struct WordDetailView: View {
    @Binding var word: Word // Now a @Binding variable
    @State private var wordEntries: Welcome?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingAlert = false
    @State private var spellingSuggestions: [SpellingSuggestion] = []
    
    private let dictionaryService = DictionaryService()
    private let datamuseService = DatamuseService()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                ProgressView("Fetching definition...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let manualDef = word.manualDefinition, !manualDef.isEmpty {
                // Display manual definition if available
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(word.text.capitalized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: {
                                SpeechService.shared.speak(text: word.text)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                            }
                        }
                        Text("Manual Definition:")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top)
                        Text(manualDef)
                    }
                }
            } else if let entries = wordEntries {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(word.text.capitalized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: {
                                SpeechService.shared.speak(text: word.text)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                            }
                        }

                        if let phonetic = entries.first?.phonetic {
                            Text(phonetic)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }

                        ForEach(entries.flatMap(\.meanings)) { meaning in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(meaning.partOfSpeech)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.top)

                                ForEach(meaning.definitions) { def in
                                    VStack(alignment: .leading) {
                                        Text("• \(def.definition)")
                                        if let example = def.example {
                                            Text("\"\(example)\"")
                                                .italic()
                                                .foregroundColor(.gray)
                                                .padding(.leading)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else if !spellingSuggestions.isEmpty {
                // Display spelling suggestions in a paginated view
                VStack(alignment: .leading) {
                    Text("Word not found. Did you mean:")
                        .font(.headline)
                    
                    TabView {
                        ForEach(0..<numberOfPages, id: \.self) { page in
                            VStack(alignment: .leading) {
                                ForEach(suggestions(for: page)) { suggestion in
                                    Button(action: {
                                        self.word.text = suggestion.word
                                        Task {
                                            await fetchWordDetails()
                                        }
                                    }) {
                                        Text(suggestion.word)
                                            .font(.body)
                                            .padding(5)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: CGFloat(suggestionsPerPage) * 40) // Adjust height based on content
                    
                    PageControl(numberOfPages: numberOfPages, currentPage: .constant(0))
                }
            } else if errorMessage != nil {
                Text(errorMessage!)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .navigationTitle("Definition")
        .task {
            await fetchWordDetails()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "An unknown error occurred."), dismissButton: .default(Text("OK")))
        }
    }

    private let suggestionsPerPage = 5

    private var numberOfPages: Int {
        return (spellingSuggestions.count + suggestionsPerPage - 1) / suggestionsPerPage
    }

    private func suggestions(for page: Int) -> [SpellingSuggestion] {
        let startIndex = page * suggestionsPerPage
        let endIndex = min(startIndex + suggestionsPerPage, spellingSuggestions.count)
        return Array(spellingSuggestions[startIndex..<endIndex])
    }

    private func fetchWordDetails() async {
        // If a manual definition exists, display it and skip API call
        if let manualDef = word.manualDefinition, !manualDef.isEmpty {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        spellingSuggestions = []
        wordEntries = nil

        do {
            let entries = try await dictionaryService.fetchWord(word.text)
            if entries.isEmpty {
                self.errorMessage = "No definition found for '\(word.text)'."
            } else {
                self.wordEntries = entries
            }
        } catch let error as APIError {
            if case .apiError(404) = error {
                // Word not found, fetch suggestions
                do {
                    self.spellingSuggestions = try await datamuseService.fetchSpellingSuggestions(for: word.text)
                    if self.spellingSuggestions.isEmpty {
                        self.errorMessage = "Word not found and no suggestions available."
                    }
                } catch {
                    self.errorMessage = "Word not found. Failed to fetch suggestions."
                    self.showingAlert = true
                }
            } else {
                self.errorMessage = error.localizedDescription
                self.showingAlert = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingAlert = true
        }
        isLoading = false
    }
}
