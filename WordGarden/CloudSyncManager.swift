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

final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published var isLoggedIn = false
    @Published var syncing = false
    @Published var isConnected = false

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
                self?.isLoggedIn = (user != nil)
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
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        syncing = true
        defer { syncing = false }

        let userRef = db.collection("users").document(userId)
        
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
    }

    @MainActor
    func downloadAllData(wordStorage: WordStorage, treeService: TreeService) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        syncing = true
        defer { syncing = false }

        let userRef = db.collection("users").document(userId)
        
        // Download single documents
        let document = try await userRef.getDocument()
        if let treesGrown = document.get("treesGrown") as? Int {
            treeService.treesGrown = treesGrown
        }
        if let treeData = document.get("tree") as? [String: Any] {
            let jsonData = try JSONSerialization.data(withJSONObject: treeData)
            let tree = try JSONDecoder().decode(Tree.self, from: jsonData)
            treeService.tree = tree
        }

        // Download collections
        var downloadedWords: [Word] = []
        let wordsSnapshot = try await userRef.collection("words").getDocuments()
        for document in wordsSnapshot.documents {
            let word = try document.data(as: Word.self)
            downloadedWords.append(word)
        }
        wordStorage.words = downloadedWords

        var downloadedDailyLogs: [DailyLog] = []
        let dailyLogsSnapshot = try await userRef.collection("dailyLogs").getDocuments()
        for document in dailyLogsSnapshot.documents {
            let log = try document.data(as: DailyLog.self)
            downloadedDailyLogs.append(log)
        }
        wordStorage.dailyLogs = downloadedDailyLogs
        
        var downloadedWateringLogs: [WateringLog] = []
        let wateringLogsSnapshot = try await userRef.collection("wateringLogs").getDocuments()
        for document in wateringLogsSnapshot.documents {
            let log = try document.data(as: WateringLog.self)
            downloadedWateringLogs.append(log)
        }
        treeService.wateringLogs = downloadedWateringLogs
    }
}
