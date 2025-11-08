# WordGarden 🌱

WordGarden is a delightful iOS vocabulary learning app built entirely with SwiftUI. It turns the process of learning new words into a fun and interactive experience by letting you grow your own virtual garden. Each new word you add becomes a plant that you need to nurture, helping you build a stronger vocabulary one plant at a time.

## Features

- **Add & Grow Words**: Add new words to your garden. Each word starts as a seedling.
- **Interactive Growth**: "Water" your plants by tapping a button. Reviewing your words helps them grow from a seedling 🌱 to a full-grown tree 🌳.
- **API Integration**: Automatically fetches detailed definitions, examples, and phonetic spellings from the [Free Dictionary API](https://dictionaryapi.dev/).
- **Manual Definitions**: If you prefer, you can add your own custom definitions for words. The app will prioritize your definition over the API.
- **Local Persistence**: Your garden is saved locally, so your progress is always there when you return.
- **Caching**: API responses are cached to minimize network usage and provide a faster experience.
- **Settings**: A dedicated settings page allows you to clear the word cache if needed.
- **Text-to-Speech**: Hear the correct pronunciation of words with a simple tap.
- **Modern SwiftUI**: Built using modern SwiftUI features like `async/await` for clean and efficient asynchronous code.

## How to Build

1.  Clone this repository to your local machine.
2.  Open the `WordGarden.xcodeproj` file in Xcode.
3.  Select a simulator or connect a physical iOS device.
4.  Build and run the project (▶️).

No API keys are required to run this project.

## Technologies Used

- **UI Framework**: SwiftUI
- **Language**: Swift
- **Concurrency**: `async/await`
- **Audio**: `AVFoundation` for text-to-speech.
- **Data Handling**: `Codable` for JSON parsing from the API.
- **Storage**: `UserDefaults` and file-based caching for local data persistence.

## Code Structure

- `WordGardenApp.swift`: The main entry point for the app.
- `ContentView.swift`: The main view displaying the list of words (plants).
- `WordDetailView.swift`: The view that shows the detailed definition of a word, either from a manual entry or the API.
- `AddWordView.swift`: A sheet used to add new words to the garden.
- `SettingsView.swift`: The settings page, currently with a "Clear Cache" option.
- `DictionaryService.swift`: Handles all networking logic for fetching data from the Free Dictionary API.
- `CacheManager.swift`: Manages the caching of API responses to the device's file system.
- `Word.swift`: The data model for a single word.
- `WordStorage.swift`: A class responsible for loading and saving the user's words.
