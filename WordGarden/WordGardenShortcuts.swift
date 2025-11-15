
import AppIntents

@available(iOS 16.0, *)
struct WordGardenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddWordIntent(),
            phrases: ["Add a word to my garden in \(.applicationName)"],
            shortTitle: "Add Word",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: StartFlashcardsIntent(),
            phrases: ["Start flashcards in \(.applicationName)"],
            shortTitle: "Start Flashcards",
            systemImageName: "rectangle.stack"
        )
        AppShortcut(
            intent: DiscoverNewWordIntent(),
            phrases: ["Discover a new word in \(.applicationName)"],
            shortTitle: "Discover New Word",
            systemImageName: "lightbulb"
        )
        AppShortcut(
            intent: PracticeIntent(),
            phrases: ["Practice my words in \(.applicationName)"],
            shortTitle: "Practice",
            systemImageName: "figure.walk"
        )
    }
}
