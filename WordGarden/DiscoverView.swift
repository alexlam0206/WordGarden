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
                VStack(spacing: 25) {
                    // Word of the Day Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Word of the Day")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal)

                        if isLoadingWordOfDay {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                Spacer()
                            }
                            .frame(height: 120)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                            .cornerRadius(15)
                            .padding(.horizontal)
                        } else if let word = wordOfTheDay {
                            WordOfDayCard(word: word)
                        } else {
                            Text("Tap to load word of the day")
                                .foregroundColor(.secondary)
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                                .cornerRadius(15)
                                .padding(.horizontal)
                        }
                    }

                    // Daily Tasks Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "checklist")
                                .foregroundColor(.orange)
                            Text("Daily Tasks")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal)

                        ForEach(dailyTasks, id: \.self) { task in
                            HStack {
                                Image(systemName: completedTasks.contains(task) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(completedTasks.contains(task) ? .green : .gray)
                                    .font(.title2)
                                Text(task)
                                    .strikethrough(completedTasks.contains(task))
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                Spacer()
                            }
                            .padding(15)
                            .background(completedTasks.contains(task) ? LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .padding(.horizontal)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    toggleTask(task)
                                }
                            }
                        }
                    }

                    // Discover New Words Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.purple)
                            Text("Discover New Words")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal)

                        HStack(spacing: 20) {
                            NavigationLink(destination: PhotoVocabView()) {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                    Text("From Photo")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 90, height: 90)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                                .cornerRadius(15)
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }

                            Button(action: generateRandomWords) {
                                VStack(spacing: 8) {
                                    Image(systemName: "shuffle")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                    Text("Random")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 90, height: 90)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                                .cornerRadius(15)
                                .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .disabled(isLoadingRandom)

                            NavigationLink(destination: CategoriesView()) {
                                VStack(spacing: 8) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                    Text("Categories")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 90, height: 90)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                                .cornerRadius(15)
                                .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Random Words Section
                    if !randomWords.isEmpty || isLoadingRandom {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "dice.fill")
                                    .foregroundColor(.pink)
                                Text("Random Words")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal)

                            if isLoadingRandom {
                                HStack {
                                    Spacer()
                                    ProgressView("Loading new words...")
                                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                                        .padding(.vertical, 30)
                                    Spacer()
                                }
                                .background(LinearGradient(gradient: Gradient(colors: [Color.pink.opacity(0.1), Color.pink.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                                .cornerRadius(15)
                                .padding(.horizontal)
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
                if let word = wordStorage.words.first(where: { $0.text.lowercased() == wordOfDayText.lowercased() }) {
                    wordOfTheDay = word
                } else {
                    // If not in user's list, fetch from API
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
                }
            } catch {
                print("Failed to load word of the day: \(error)")
            }
            isLoadingWordOfDay = false
        }
    }

    private func getWordOfTheDay() -> String {
        if !wordStorage.words.isEmpty {
            let calendar = Calendar.current
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
            let index = dayOfYear % wordStorage.words.count
            return wordStorage.words[index].text
        } else {
            // Fallback to predefined words if user has no words
            let words = ["serendipity", "ephemeral", "lucid", "resilient", "ethereal", "pragmatic", "eloquent", "tenacious", "ubiquitous", "voracious"]
            let calendar = Calendar.current
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
            return words[dayOfYear % words.count]
        }
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(word.text.capitalized)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }

            Text(word.definition)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(3)

            if !word.example.isEmpty {
                Text("\"\(word.example)\"")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                    .italic()
            }
        }
        .padding(20)
        .background(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.2), Color.yellow.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(15)
        .shadow(color: Color.yellow.opacity(0.3), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
    }
}

struct RandomWordCard: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(word.text.capitalized)
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            Text(word.definition)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(15)
        .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
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
                Section(header: Text(category).font(.system(size: 18, weight: .semibold, design: .rounded))) {
                    ForEach(words, id: \.self) { word in
                        NavigationLink(destination: WordDetailView(word: .constant(Word(text: word, definition: "", example: "")))) {
                            HStack {
                                Text(word.capitalized)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
        }
        .navigationTitle("Word Categories")
        .listStyle(InsetGroupedListStyle())
    }
}