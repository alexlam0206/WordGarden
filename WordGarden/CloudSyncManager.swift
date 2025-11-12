import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn
import Network
import UIKit

// MARK: - Helper Extensions
extension Encodable {
    /// Converts an Encodable object to a dictionary for Firestore.
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

extension DocumentSnapshot {
    /// Decodes a Firestore document into a Decodable object.
    func data<T: Decodable>(as type: T.Type) throws -> T {
        guard let data = data() else {
            throw NSError() // Or a custom decoding error
        }
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
        let object = try JSONDecoder().decode(T.self, from: jsonData)
        return object
    }
}

enum CloudSyncError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case dataEncodingError(Error)
    case dataDecodingError(Error)
    case firestoreError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated. Please sign in to sync data."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .dataEncodingError(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .dataDecodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        }
    }
}

final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published var isLoggedIn = false
    @Published var syncing = false
    @Published var isConnected = false
    @Published var lastSyncError: String?

    private var currentSyncTask: Task<Void, Never>?

    private let monitor = NWPathMonitor()
    private let db = Firestore.firestore()

    private init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)

        // Listen for Firebase Auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                let wasLoggedIn = self?.isLoggedIn ?? false
                self?.isLoggedIn = (user != nil)

                // Auto-sync when user signs in
                if !wasLoggedIn && (user != nil) {
                    // Note: We can't call async functions directly here, so we'll rely on the UI to trigger sync
                    // The SettingsView will show sync options when logged in
                }
            }
        }
    }

    // MARK: - Authentication
    @MainActor
    func signInWithGoogle() async throws {
        guard let topVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?
                .windows
                .filter({ $0.isKeyWindow })
                .first?
                .rootViewController else {
            throw URLError(.cannotFindHost)
        }

        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: gidSignInResult.user.accessToken.tokenString)
        
        try await Auth.auth().signIn(with: credential)
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }

    // MARK: - Data Sync
    @MainActor
    func uploadAllData(wordStorage: WordStorage, treeService: TreeService) async throws {
        // Prevent concurrent sync operations
        guard currentSyncTask == nil else {
            throw CloudSyncError.networkError(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sync operation already in progress"]))
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            throw CloudSyncError.notAuthenticated
        }

        currentSyncTask = Task<Void, Never> {
            syncing = true
            lastSyncError = nil
            defer {
                syncing = false
                currentSyncTask = nil
            }

            let userRef = db.collection("users").document(userId)

            do {
                // Upload single documents
                try await userRef.setData(["treesGrown": treeService.treesGrown], merge: true)
                let treeDict = try treeService.tree.asDictionary()
                try await userRef.setData(["tree": treeDict], merge: true)

                // Upload collections
                for word in wordStorage.words {
                    let wordDict = try word.asDictionary()
                    try await userRef.collection("words").document(word.id.uuidString).setData(wordDict)
                }
                for log in wordStorage.dailyLogs {
                    let logDict = try log.asDictionary()
                    try await userRef.collection("dailyLogs").document(log.id.uuidString).setData(logDict)
                }
                for log in treeService.wateringLogs {
                    let logDict = try log.asDictionary()
                    try await userRef.collection("wateringLogs").document(log.id.uuidString).setData(logDict)
                }
            } catch let error as CloudSyncError {
                lastSyncError = error.errorDescription
            } catch {
                let syncError = CloudSyncError.firestoreError(error)
                lastSyncError = syncError.errorDescription
            }
        }
        try await currentSyncTask?.value
    }

    @MainActor
    func downloadAllData(wordStorage: WordStorage, treeService: TreeService) async throws {
        // Prevent concurrent sync operations
        guard currentSyncTask == nil else {
            throw CloudSyncError.networkError(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sync operation already in progress"]))
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            throw CloudSyncError.notAuthenticated
        }

        currentSyncTask = Task<Void, Never> {
            syncing = true
            lastSyncError = nil
            defer {
                syncing = false
                currentSyncTask = nil
            }

            let userRef = db.collection("users").document(userId)

            do {
                // Download single documents
                let document = try await userRef.getDocument()
                if let cloudTreesGrown = document.get("treesGrown") as? Int {
                    // Merge by taking the higher value, ensuring local progress isn't lost.
                    treeService.treesGrown = max(treeService.treesGrown, cloudTreesGrown)
                }
                if let treeData = document.get("tree") as? [String: Any] {
                    let jsonData = try JSONSerialization.data(withJSONObject: treeData)
                    let cloudTree = try JSONDecoder().decode(Tree.self, from: jsonData)

                    // Merge tree data: keep the higher level
                    let mergedLevel = max(treeService.tree.level, cloudTree.level)

                    // For lastWatered, use the most recent date, but ensure it doesn't conflict with local watering logs
                    let localLastWatered = treeService.wateringLogs.last?.date ?? treeService.tree.lastWatered
                    let cloudLastWatered = cloudTree.lastWatered
                    let mergedLastWatered = max(localLastWatered, cloudLastWatered)

                    treeService.tree = Tree(id: treeService.tree.id, level: mergedLevel, lastWatered: mergedLastWatered)
                }

                // Download and merge words
                var downloadedWords: [Word] = []
                let wordsSnapshot = try await userRef.collection("words").getDocuments()
                for document in wordsSnapshot.documents {
                    let word = try document.data(as: Word.self)
                    downloadedWords.append(word)
                }

                // Merge words: keep both local and cloud words, avoiding duplicates by text
                let existingWordTexts = Set(wordStorage.words.map { $0.text.lowercased() })
                for word in downloadedWords {
                    if !existingWordTexts.contains(word.text.lowercased()) {
                        wordStorage.words.append(word)
                    }
                }

                // Download and merge daily logs
                var downloadedDailyLogs: [DailyLog] = []
                let dailyLogsSnapshot = try await userRef.collection("dailyLogs").getDocuments()
                for document in dailyLogsSnapshot.documents {
                    let log = try document.data(as: DailyLog.self)
                    downloadedDailyLogs.append(log)
                }

                // Merge daily logs: combine logs for the same date
                for cloudLog in downloadedDailyLogs {
                    if let existingIndex = wordStorage.dailyLogs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: cloudLog.date) }) {
                        // Merge logs for the same day
                        let existingLogs = wordStorage.dailyLogs[existingIndex].logs
                        let combinedLogs = Set(existingLogs + cloudLog.logs).sorted() // Remove duplicates and sort
                        wordStorage.dailyLogs[existingIndex].logs = combinedLogs
                    } else {
                        // Add new date log
                        wordStorage.dailyLogs.append(cloudLog)
                    }
                }

                // Download and merge watering logs
                var downloadedWateringLogs: [WateringLog] = []
                let wateringLogsSnapshot = try await userRef.collection("wateringLogs").getDocuments()
                for document in wateringLogsSnapshot.documents {
                    let log = try document.data(as: WateringLog.self)
                    downloadedWateringLogs.append(log)
                }

                // Merge watering logs: combine unique logs by date (assuming same date means same watering)
                let existingWateringDates = Set(treeService.wateringLogs.map { $0.date })
                for log in downloadedWateringLogs {
                    if !existingWateringDates.contains(log.date) {
                        treeService.wateringLogs.append(log)
                    }
                }

                // Sort watering logs by date
                treeService.wateringLogs.sort { $0.date < $1.date }
            } catch let error as CloudSyncError {
                lastSyncError = error.errorDescription
            } catch {
                let syncError = CloudSyncError.firestoreError(error)
                lastSyncError = syncError.errorDescription
            }
        }
        try await currentSyncTask?.value
    }
}
