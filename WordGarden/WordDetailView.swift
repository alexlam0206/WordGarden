import SwiftUI
import AVFoundation

struct WordDetailView: View {
    @Binding var word: Word // Now a @Binding variable
    @EnvironmentObject var wordStorage: WordStorage
    @State private var wordEntries: Welcome?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingAlert = false
    @State private var spellingSuggestions: [SpellingSuggestion] = []
    @State private var currentSuggestionPage = 0
    @State private var aiExplanation: String?
    @State private var aiExample: String?

    @State private var isAILoading = false
    @AppStorage("geminiApiKey") private var geminiApiKey = ""
    @AppStorage("openaiApiKey") private var openaiApiKey = ""
    @AppStorage("openrouterApiKey") private var openrouterApiKey = ""
    @AppStorage("localAIAPIKey") private var localAIAPIKey = ""
    @State private var selectedProvider: AIProvider = .onDevice
    @State private var showAISheet = false
    
    private let dictionaryService = DictionaryService()
    private let datamuseService = DatamuseService()
    private var aiService: AIService {
        AIService(geminiApiKey: geminiApiKey, openaiApiKey: openaiApiKey, openrouterApiKey: openrouterApiKey, localAIAPIKey: localAIAPIKey)
    }

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
                    .frame(maxWidth: .infinity, alignment: .leading)
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

                        if let phonetic = entries.first?.phonetics.first(where: { $0.text != nil })?.text {
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if !spellingSuggestions.isEmpty {
                // Display spelling suggestions in a paginated view
                VStack(alignment: .leading) {
                    Text("Word not found. Did you mean:")
                        .font(.headline)
                    
                    TabView(selection: $currentSuggestionPage) {
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
                            .tag(page)
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: CGFloat(suggestionsPerPage) * 40) // Adjust height based on content

                    PageControl(numberOfPages: numberOfPages, currentPage: $currentSuggestionPage)
                }
            } else if errorMessage != nil {
                Text(errorMessage!)
                    .foregroundColor(.red)
                    .padding()
            }

            // AI Features
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAISheet = true
                    }) {
                        Image(systemName: "brain.head.profile")
                            .font(.title)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showAISheet) {
                AISheetView(word: word, selectedProvider: $selectedProvider, aiExplanation: $aiExplanation, aiExample: $aiExample, isAILoading: $isAILoading)
            }
        }
        .padding()
        .navigationTitle("Definition")
        .task {
            await fetchWordDetails()
            // Increase growth level when viewing details
            wordStorage.reviewWord(wordID: word.id)
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
                // Save the first definition to word.definition for caching
                if let firstDef = entries.first?.meanings.first?.definitions.first?.definition {
                    word.definition = firstDef
                }
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

    private func generateExplanation() async {
        isAILoading = true
        do {
            aiExplanation = try await aiService.generateExplanation(for: word.text, provider: selectedProvider)
        } catch {
            print("Failed to generate explanation: \(error.localizedDescription)")
            aiExplanation = "Failed to generate explanation: \(error.localizedDescription)"
        }
        isAILoading = false
    }

    private func generateExample() async {
        isAILoading = true
        do {
            aiExample = try await aiService.generateExampleSentence(for: word.text, provider: selectedProvider)
        } catch {
            print("Failed to generate example: \(error.localizedDescription)")
            aiExample = "Failed to generate example: \(error.localizedDescription)"
        }
        isAILoading = false
    }


}

struct AISheetView: View {
    let word: Word
    @Binding var selectedProvider: AIProvider
    @Binding var aiExplanation: String?
    @Binding var aiExample: String?

    @Binding var isAILoading: Bool

    @Environment(\.dismiss) var dismiss

    private var aiService: AIService {
        let geminiApiKey = UserDefaults.standard.string(forKey: "geminiApiKey") ?? ""
        let openaiApiKey = UserDefaults.standard.string(forKey: "openaiApiKey") ?? ""
        let openrouterApiKey = UserDefaults.standard.string(forKey: "openrouterApiKey") ?? ""
        let localAIAPIKey = UserDefaults.standard.string(forKey: "localAIAPIKey") ?? ""
        return AIService(geminiApiKey: geminiApiKey, openaiApiKey: openaiApiKey, openrouterApiKey: openrouterApiKey, localAIAPIKey: localAIAPIKey)
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Provider")) {
                    Picker("AI Provider", selection: $selectedProvider) {
                        Text("On-Device").tag(AIProvider.onDevice)
                        Text("Gemini").tag(AIProvider.gemini)
                        Text("OpenAI").tag(AIProvider.openai)
                        Text("OpenRouter").tag(AIProvider.openrouter)
                        Text("Local AI").tag(AIProvider.localAI)
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Generate")) {
                    Button(action: {
                        Task {
                            await generateExplanation()
                        }
                    }) {
                        HStack {
                            Text("Explain Word")
                            Spacer()
                            if isAILoading && aiExplanation == nil {
                                ProgressView()
                            } else if aiExplanation != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    Button(action: {
                        Task {
                            await generateExample()
                        }
                    }) {
                        HStack {
                            Text("Example Sentence")
                            Spacer()
                            if isAILoading && aiExample == nil {
                                ProgressView()
                            } else if aiExample != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }


                }

                if let explanation = aiExplanation {
                    Section(header: Text("Explanation")) {
                        Text(explanation)
                    }
                }

                if let example = aiExample {
                    Section(header: Text("Example")) {
                        Text(example)
                    }
                }


            }
            .navigationTitle("AI Assistant")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }

    private func generateExplanation() async {
        isAILoading = true
        do {
            aiExplanation = try await aiService.generateExplanation(for: word.text, provider: selectedProvider)
        } catch {
            print("Failed to generate explanation: \(error.localizedDescription)")
            aiExplanation = "Failed: \(error.localizedDescription)"
        }
        isAILoading = false
    }

    private func generateExample() async {
        isAILoading = true
        do {
            aiExample = try await aiService.generateExampleSentence(for: word.text, provider: selectedProvider)
        } catch {
            print("Failed to generate example: \(error.localizedDescription)")
            aiExample = "Failed: \(error.localizedDescription)"
        }
        isAILoading = false
    }


}
