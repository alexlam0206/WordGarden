
import AppIntents
import SwiftUI

@available(iOS 16.0, *)
struct AddWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Word"
    static var description = IntentDescription("Add a word to your garden.")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Word")
    var word: String

    @Parameter(title: "Definition")
    var definition: String

    init(word: String, definition: String) {
        self.word = word
        self.definition = definition
    }

    init() {
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set("addWord", forKey: "navigationTarget")
        UserDefaults.standard.set(word, forKey: "navigationWord")
        UserDefaults.standard.set(definition, forKey: "navigationDefinition")
        return .result()
    }
}

@available(iOS 16.0, *)
struct StartFlashcardsIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Flashcards"
    static var description = IntentDescription("Start a flashcard session.")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set("flashcards", forKey: "navigationTarget")
        return .result()
    }
}

@available(iOS 16.0, *)
struct DiscoverNewWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Discover New Word"
    static var description = IntentDescription("Discover a new word to add to your garden.")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set("discover", forKey: "navigationTarget")
        return .result()
    }
}

@available(iOS 16.0, *)
struct PracticeIntent: AppIntent {
    static var title: LocalizedStringResource = "Practice"
    static var description = IntentDescription("Practice your words in your garden.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set("practice", forKey: "navigationTarget")
        return .result()
    }
}
