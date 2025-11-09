

import Foundation
import Combine

struct Flashcard: Identifiable {
    let id = UUID()
    let word: String
    let definition: String
}

struct DailyLog: Codable, Identifiable {
    var id = UUID()
    let date: Date
    var logs: [String]
}

// Manages saving and loading words from iCloud Key-Value Storage.
class WordStorage: ObservableObject {
    @Published var dailyLogs: [DailyLog] = [] {
        didSet {
            saveLogs()
        }
    }
    @Published var words: [Word] {
        didSet {
            saveWords()
        }
    }

    private let wordsKey = "words"
    private let logsKey = "dailyLogs"

    init() {
        self.words = WordStorage.loadWords()
        self.dailyLogs = WordStorage.loadLogs()
        cleanOldLogs()
    }

    // Load words from local storage
    private static func loadWords() -> [Word] {
        if let data = UserDefaults.standard.data(forKey: "words") {
            if let decodedWords = try? JSONDecoder().decode([Word].self, from: data) {
                return decodedWords
            }
        }
        return []
    }

    // Load logs from local storage
    private static func loadLogs() -> [DailyLog] {
        if let data = UserDefaults.standard.data(forKey: "dailyLogs") {
            if let decodedLogs = try? JSONDecoder().decode([DailyLog].self, from: data) {
                return decodedLogs
            }
        }
        return []
    }

    // Save words to local storage
    private func saveWords() {
        if let encodedWords = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(encodedWords, forKey: "words")
        }
    }

    // Save logs to local storage
    private func saveLogs() {
        if let encodedLogs = try? JSONEncoder().encode(dailyLogs) {
            UserDefaults.standard.set(encodedLogs, forKey: "dailyLogs")
        }
    }

    // Get or create today's log
    private func getTodaysLog() -> DailyLog {
        let today = Calendar.current.startOfDay(for: Date())
        if let index = dailyLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return dailyLogs[index]
        } else {
            let newLog = DailyLog(date: today, logs: [])
            dailyLogs.append(newLog)
            return newLog
        }
    }

    // Add log entry
    func addLogEntry(_ entry: String) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = timeFormatter.string(from: Date())
        let entryWithTime = "[\(timestamp)] \(entry)"
        var todaysLog = getTodaysLog()
        todaysLog.logs.append(entryWithTime)
        if let index = dailyLogs.firstIndex(where: { $0.id == todaysLog.id }) {
            dailyLogs[index] = todaysLog
        }
    }

    // Clean logs older than 7 days
    private func cleanOldLogs() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        dailyLogs = dailyLogs.filter { $0.date >= sevenDaysAgo }
    }

    @objc private func ubiquitousKeyValueStoreDidChange(notification: Notification) {
        // Reload data when iCloud changes
        self.words = WordStorage.loadWords()
    }

    // Add a new word
    func addWord(text: String, definition: String, example: String) {
        let newWord = Word(text: text, definition: definition, example: example)
        words.append(newWord)
    }

    // Export data as JSON string
    func exportData() -> String? {
        if let data = try? JSONEncoder().encode(words) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    // Import data from JSON string, merging with existing words and avoiding duplicates.
    func importData(json: String) -> Bool {
        if let data = json.data(using: .utf8),
           let importedWords = try? JSONDecoder().decode([Word].self, from: data) {

            let existingWordTexts = Set(words.map { $0.text.lowercased() })

            for word in importedWords {
                if !existingWordTexts.contains(word.text.lowercased()) {
                    words.append(word)
                }
            }

            return true
        }
        return false
    }

    // Generate flashcards for all words, using the first definition from the API if not manually set
    func generateFlashcards() async -> [Flashcard] {
        let dictionaryService = DictionaryService()
        var flashcards: [Flashcard] = []

        for word in words {
            var definition = word.definition
            if definition.isEmpty || definition == "Definition not available" { // Assuming placeholder
                do {
                    let entries = try await dictionaryService.fetchWord(word.text)
                    if let firstMeaning = entries.first?.meanings.first,
                       let firstDef = firstMeaning.definitions.first {
                        definition = firstDef.definition
                    }
                } catch {
                    definition = "Definition not available"
                }
            }
            if definition != "Definition not available" && !definition.isEmpty {
                flashcards.append(Flashcard(word: word.text, definition: definition))
            }
        }

        return flashcards
    }
}
