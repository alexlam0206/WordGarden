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

// Manages the storage of words and daily logs using UserDefaults.
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

    // Loads words from UserDefaults.
    private static func loadWords() -> [Word] {
        if let data = UserDefaults.standard.data(forKey: "words") {
            if let decodedWords = try? JSONDecoder().decode([Word].self, from: data) {
                return decodedWords
            }
        }
        return []
    }

    // Loads daily logs from UserDefaults.
    private static func loadLogs() -> [DailyLog] {
        if let data = UserDefaults.standard.data(forKey: "dailyLogs") {
            if let decodedLogs = try? JSONDecoder().decode([DailyLog].self, from: data) {
                return decodedLogs
            }
        }
        return []
    }

    // Saves the current array of words to UserDefaults.
    private func saveWords() {
        if let encodedWords = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(encodedWords, forKey: "words")
        }
    }

    // Saves the current array of daily logs to UserDefaults.
    private func saveLogs() {
        if let encodedLogs = try? JSONEncoder().encode(dailyLogs) {
            UserDefaults.standard.set(encodedLogs, forKey: "dailyLogs")
        }
    }

    // Retrieves the index for today's log, creating a new log if one doesn't exist.
    private func getTodaysLogIndex() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        if let index = dailyLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return index
        } else {
            let newLog = DailyLog(date: today, logs: [])
            dailyLogs.append(newLog)
            return dailyLogs.count - 1
        }
    }

    // Adds a new string entry to the log for the current day.
    func addLogEntry(_ entry: String) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = timeFormatter.string(from: Date())
        let entryWithTime = "[\(timestamp)] \(entry)"
        
        let index = getTodaysLogIndex()
        dailyLogs[index].logs.append(entryWithTime)
    }

    // Removes log entries that are older than seven days.
    private func cleanOldLogs() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        dailyLogs = dailyLogs.filter { $0.date >= sevenDaysAgo }
    }

    // Responds to changes in the ubiquitous key-value store.
    @objc private func ubiquitousKeyValueStoreDidChange(notification: Notification) {
        self.words = WordStorage.loadWords()
    }

    // Adds a new Word object to the words array.
    func addWord(text: String, definition: String, example: String) {
        let newWord = Word(text: text, definition: definition, example: example)
        words.append(newWord)
    }

    // Exports the current words array to a JSON string.
    func exportData() -> String? {
        if let data = try? JSONEncoder().encode(words) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    // Imports words from a JSON string, merging them with existing words while avoiding duplicates.
    func importData(json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let importedWords = try? JSONDecoder().decode([Word].self, from: data) else {
            return false
        }

        let existingWordTexts = Set(words.map { $0.text.lowercased() })

        for word in importedWords {
            if !existingWordTexts.contains(word.text.lowercased()) {
                words.append(word)
            }
        }
        return true
    }

    // Generates flashcards for all words. If a definition is missing, it attempts to fetch one from the DictionaryService.
    func generateFlashcards() async -> [Flashcard] {
        let dictionaryService = DictionaryService()
        var flashcards: [Flashcard] = []

        for word in words {
            var definition = word.definition
            if definition.isEmpty {
                do {
                    let entries = try await dictionaryService.fetchWord(word.text)
                    if let firstMeaning = entries.first?.meanings.first,
                       let firstDef = firstMeaning.definitions.first {
                        definition = firstDef.definition
                    }
                } catch {
                    definition = "Definition not available."
                }
            }
            
            if !definition.isEmpty && definition != "Definition not available." {
                flashcards.append(Flashcard(word: word.text, definition: definition))
            }
        }

        return flashcards
    }
}
