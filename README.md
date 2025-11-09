# WordGarden 🌱

WordGarden is a delightful iOS vocabulary learning app built entirely with SwiftUI. It turns the process of learning new words into a fun and interactive experience by letting you grow your own virtual garden. Each new word you add becomes a plant that you need to nurture, helping you build a stronger vocabulary one plant at a time.

## Features

- **Add & Grow Words**: Add new words to your garden. Each word starts as a seedling.
- **Interactive Growth**: "Water" your plants by tapping a button. Reviewing your words helps them grow from a seedling 🌱 to a full-grown tree 🌳.
- **Cloud Sync**: Sign in with your Google account to back up and sync your vocabulary and progress across devices using Firebase.
- **API Integration**: Automatically fetches detailed definitions, examples, and phonetic spellings from the [Free Dictionary API](https://dictionaryapi.dev/).
- **Manual Definitions**: If you prefer, you can add your own custom definitions for words.
- **Local-First Persistence**: Your garden is saved locally for offline access and synced to the cloud when you're connected.
- **Caching**: API responses are cached to minimize network usage and provide a faster experience.
- **Settings**: A dedicated settings page allows you to manage your account, sync data, and clear the word cache.
- **Text-to-Speech**: Hear the correct pronunciation of words with a simple tap.
- **Modern SwiftUI**: Built using modern SwiftUI features like `async/await` for clean and efficient asynchronous code.

## Technologies Used

- **UI Framework**: SwiftUI
- **Language**: Swift
- **Backend & Sync**: Firebase (Authentication, Firestore)
- **Concurrency**: `async/await`
- **Audio**: `AVFoundation` for text-to-speech.
- **Data Handling**: `Codable` for JSON parsing.
- **Storage**: `UserDefaults` for local data persistence.

## Dependencies

- **[Firebase](https://github.com/firebase/firebase-ios-sdk)**: Used for authentication, cloud database, and storage.
- **[GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS)**: Used for authenticating users with their Google account via Firebase.

## Cloud Sync with Firebase

WordGarden now supports cloud backup and synchronization using Firebase. This allows users to sign in with their Google account and keep their vocabulary, progress, and settings synced across multiple devices.

### Developer Setup

To enable the Firebase integration in your local build, you will need to set up your own Firebase project.

1.  **Create a Firebase Project:**
    *   Go to the [Firebase Console](https://console.firebase.google.com/).
    *   Create a new project and register an iOS app with the bundle ID `alexlam0206.WordGarden`.

2.  **Enable Firebase Services:**
    *   In the console, enable **Authentication** and add the **Google** sign-in provider.
    *   Enable **Firestore** and create a database in production mode.
    *   Enable **Cloud Storage** for future backup features.

3.  **Add Configuration File:**
    *   From your Firebase project settings, download the `GoogleService-Info.plist` file.
    *   Place this file inside the `WordGarden/` directory in your Xcode project, ensuring it is included in the app target.

4.  **Install Packages:**
    *   In Xcode, go to **File > Add Packages...** and add the `firebase-ios-sdk` Swift package (`https://github.com/firebase/firebase-ios-sdk.git`).
    *   Ensure the `FirebaseAuth`, `FirebaseFirestore`, and `FirebaseStorage` products are linked to the main `WordGarden` app target.