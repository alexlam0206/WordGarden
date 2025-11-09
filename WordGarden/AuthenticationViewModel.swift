import Foundation
import SwiftUI
import Combine
import FirebaseAuth

// Manages the user's authentication state and provides methods for sign-in and sign-out.
class AuthenticationViewModel: ObservableObject {
    @Published var user: User?

    init() {
        checkSignInStatus()
    }

    // Checks the current authentication state of the user.
    func checkSignInStatus() {
        self.user = Auth.auth().currentUser
    }

    // Initiates the Google sign-in process.
    @MainActor
    func signIn() {
        Task {
            do {
                try await CloudSyncManager.shared.signInWithGoogle()
                self.user = Auth.auth().currentUser
            } catch {
                print("Error signing in: \(error.localizedDescription)")
            }
        }
    }

    // Signs the current user out.
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
