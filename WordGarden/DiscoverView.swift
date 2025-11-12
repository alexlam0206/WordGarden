import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @State private var wordOfTheDay: Word?
    @State private var isLoadingWordOfDay = false
    @State private var randomWords: [Word] = []
    @State private var isLoadingRandom = false
    @State private var dailyTasks: [String] = [
        "Add 3 new words to your garden",
        "Review 5 flashcards",
        "Complete a focus session",
        "Explore the word tree"
    ]
    @State private var completedTasks: Set<String> = []

    // UserDefaults keys
    private let completedTasksKey = "completedTasks"
    private let lastResetDateKey = "lastResetDate"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Word of the Day Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Word of the Day")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        if isLoadingWordOfDay {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .frame(height: 100)
                        } else if let word = wordOfTheDay {
                            WordOfDayCard(word: word)
                        } else {
                            Text("Tap to load word of the day")
                                .foregroundColor(.secondary)
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }

                    // Daily Tasks Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Daily Tasks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ForEach(dailyTasks, id: \.self) { task in
                            HStack {
                                Image(systemName: completedTasks.contains(task) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(completedTasks.contains(task) ? .green : .gray)
                                Text(task)
                                    .strikethrough(completedTasks.contains(task))
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .onTapGesture {
                                toggleTask(task)
                            }
                        }
                    }

                    // Discover New Words Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Discover New Words")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        HStack(spacing: 15) {
                            NavigationLink(destination: PhotoVocabView()) {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                    Text("From Photo")
                                        .font(.caption)
                                }
                                .frame(width: 80, height: 80)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }

                            Button(action: generateRandomWords) {
                                VStack {
                                    Image(systemName: "shuffle")
                                        .font(.largeTitle)
                                        .foregroundColor(.green)
                                    Text("Random")
                                        .font(.caption)
                                }
                                .frame(width: 80, height: 80)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .disabled(isLoadingRandom)

                            NavigationLink(destination: CategoriesView()) {
                                VStack {
                                    Image(systemName: "list.bullet")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                    Text("Categories")
                                        .font(.caption)
                                }
                                .frame(width: 80, height: 80)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Random Words Section
                    if !randomWords.isEmpty || isLoadingRandom {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Random Words")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            if isLoadingRandom {
                                HStack {
                                    Spacer()
                                    ProgressView("Loading new words...")
                                        .padding(.vertical, 20)
                                    Spacer()
                                }
                            } else {
                                ForEach(randomWords) { word in
                                    RandomWordCard(word: word)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            wordStorage.addLogEntry("Opened Discover tab")
            loadCompletedTasks()
            checkAndResetDailyTasks()
            loadWordOfTheDay()
        }
    }

    private func loadWordOfTheDay() {
        isLoadingWordOfDay = true
        Task {
            do {
                let wordOfDayText = getWordOfTheDay()
                let dictionaryService = DictionaryService()
                let entries = try await dictionaryService.fetchWord(wordOfDayText)

                if let entry = entries.first,
                   let meaning = entry.meanings.first,
                   let definition = meaning.definitions.first {
                    let word = Word(
                        text: entry.word,
                        definition: definition.definition,
                        example: definition.example ?? ""
                    )
                    wordOfTheDay = word
                }
            } catch {
                print("Failed to load word of the day: \(error)")
            }
            isLoadingWordOfDay = false
        }
    }

    private func getWordOfTheDay() -> String {
        let words = ["serendipity", "ephemeral", "lucid", "resilient", "ethereal", "pragmatic", "eloquent", "tenacious", "ubiquitous", "voracious"]
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return words[dayOfYear % words.count]
    }

    private func generateRandomWords() {
        isLoadingRandom = true
        // Clear existing words immediately to replace them
        randomWords.removeAll()

        Task {
            let dictionaryService = DictionaryService()
            let randomWordTexts = ["curious", "brilliant", "mysterious", "vibrant", "whimsical", "profound", "radiant", "intriguing"]

            var newWords: [Word] = []

            for wordText in randomWordTexts.shuffled().prefix(3) {
                do {
                    let entries = try await dictionaryService.fetchWord(wordText)
                    if let entry = entries.first,
                       let meaning = entry.meanings.first,
                       let definition = meaning.definitions.first {
                        let word = Word(
                            text: entry.word,
                            definition: definition.definition,
                            example: definition.example ?? ""
                        )
                        newWords.append(word)
                    }
                } catch {
                    print("Failed to load random word \(wordText): \(error)")
                }
            }

            // Replace all words at once
            randomWords = newWords
            isLoadingRandom = false
        }
    }

    private func toggleTask(_ task: String) {
        if completedTasks.contains(task) {
            completedTasks.remove(task)
        } else {
            completedTasks.insert(task)
        }
        saveCompletedTasks()
        wordStorage.addLogEntry("Toggled task: \(task) - \(completedTasks.contains(task) ? "completed" : "uncompleted")")
    }

    private func saveCompletedTasks() {
        UserDefaults.standard.set(Array(completedTasks), forKey: completedTasksKey)
        // Also save to shared UserDefaults for widgets
        let sharedDefaults = UserDefaults(suiteName: "group.com.nok.WordGarden")
        sharedDefaults?.set(Array(completedTasks), forKey: completedTasksKey)
    }

    private func loadCompletedTasks() {
        if let savedTasks = UserDefaults.standard.array(forKey: completedTasksKey) as? [String] {
            completedTasks = Set(savedTasks)
        }
    }

    private func checkAndResetDailyTasks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastResetDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date {
            let lastResetDay = calendar.startOfDay(for: lastResetDate)

            // If it's a new day, reset the tasks
            if today > lastResetDay {
                completedTasks.removeAll()
                saveCompletedTasks()
                UserDefaults.standard.set(today, forKey: lastResetDateKey)
                wordStorage.addLogEntry("Daily tasks reset for new day")
            }
        } else {
            // First time - set today's date
            UserDefaults.standard.set(today, forKey: lastResetDateKey)
        }
    }
}

struct WordOfDayCard: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word.text.capitalized)
                .font(.title)
                .fontWeight(.bold)

            Text(word.definition)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if !word.example.isEmpty {
                Text("\"\(word.example)\"")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .italic()
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct RandomWordCard: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word.text.capitalized)
                .font(.headline)
                .fontWeight(.semibold)

            Text(word.definition)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct CategoriesView: View {
    let categories = [
        ("Nature", ["forest", "mountain", "ocean", "sunset"]),
        ("Emotions", ["joy", "melancholy", "serenity", "passion"]),
        ("Abstract", ["time", "space", "infinity", "eternity"]),
        ("Colors", ["crimson", "azure", "emerald", "amber"])
    ]

    var body: some View {
        List {
            ForEach(categories, id: \.0) { category, words in
                Section(header: Text(category)) {
                    ForEach(words, id: \.self) { word in
                        NavigationLink(destination: WordDetailView(word: .constant(Word(text: word, definition: "", example: "")))) {
                            Text(word.capitalized)
                        }
                    }
                }
            }
        }
        .navigationTitle("Word Categories")
    }
}