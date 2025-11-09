
import Foundation
import SwiftUI
import Combine
import FirebaseAuth

// Manages the user's authentication state for the UI.
class AuthenticationViewModel: ObservableObject {
    @Published var user: User?

    init() {
        checkSignInStatus()
    }

    // Checks for a currently signed-in Firebase user.
    func checkSignInStatus() {
        self.user = Auth.auth().currentUser
    }

    // Starts the sign-in process via CloudSyncManager.
    @MainActor
    func signIn() {
        Task {
            do {
                try await CloudSyncManager.shared.signInWithGoogle()
                self.user = Auth.auth().currentUser
            } catch {
                print("Detailed sign-in error: \(error)")
            }
        }
    }

    // Signs the user out via CloudSyncManager.
    @MainActor
    func signOut() {
        do {
            try CloudSyncManager.shared.signOut()
            self.user = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
