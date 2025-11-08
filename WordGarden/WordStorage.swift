

import Foundation
import Combine

// Manages saving and loading words from UserDefaults.
class WordStorage: ObservableObject {
    @Published var words: [Word] {
        didSet {
            saveWords()
        }
    }

    private let wordsKey = "words"

    init() {
        self.words = WordStorage.loadWords()
    }

    // Load words from UserDefaults
    private static func loadWords() -> [Word] {
        if let data = UserDefaults.standard.data(forKey: "words") {
            if let decodedWords = try? JSONDecoder().decode([Word].self, from: data) {
                return decodedWords
            }
        }
        return []
    }

    // Save words to UserDefaults
    private func saveWords() {
        if let encodedWords = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(encodedWords, forKey: "words")
        }
    }

    // Add a new word
    func addWord(text: String, definition: String, example: String) {
        let newWord = Word(text: text, definition: definition, example: example)
        words.append(newWord)
    }
}
