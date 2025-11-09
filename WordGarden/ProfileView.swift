// All changes after that commit have been discarded, and the working directory is now at that state.

import SwiftUI
import FirebaseAuth
import CryptoKit

// All changes after that commit have been discarded, and the working directory is now at that state.

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var wordStorage: WordStorage
    @EnvironmentObject var treeService: TreeService // New: Inject TreeService
    @EnvironmentObject var cloudSyncManager: CloudSyncManager
    @State private var gravatarImage: UIImage? = nil
    @State private var showingSignOutConfirmation = false

    var body: some View {
        VStack {
            if let user = authViewModel.user {
                if let image = gravatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding()
                        .onAppear { loadGravatar(for: user.email ?? "") }
                } else {
                    ProgressView()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding()
                        .onAppear { loadGravatar(for: user.email ?? "") }
                }

                Text(user.displayName ?? "User")
                    .font(.largeTitle)
                    .padding(.bottom, 2)

                Text(user.email ?? "")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Statistics")
                        .font(.headline)
                    HStack {
                        Text("Total words:")
                        Spacer()
                        Text("\(wordStorage.words.count)")
                    }
                    HStack {
                        Text("Fully grown words:")
                        Spacer()
                        Text("\(wordStorage.words.filter { $0.growthLevel == 5 }.count)")
                    }
                    // New: Display trees grown
                    HStack {
                        Text("Trees grown:")
                        Spacer()
                        Text("\(treeService.treesGrown)")
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding()


                Spacer()

            } else {
                Text("Not signed in.")
            }
        }
        .padding()
        .onAppear {
            Task {
                try? await cloudSyncManager.downloadAllData(wordStorage: wordStorage, treeService: treeService)
            }
        }
    }

    private func gravatarURL(for email: String) -> URL? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let emailData = trimmedEmail.data(using: .utf8) else { return nil }
        let hash = Insecure.MD5.hash(data: emailData)
        let hashString = hash.map { String(format: "%02hhx", $0) }.joined()
        return URL(string: "https://www.gravatar.com/avatar/\(hashString)?d=identicon&s=100")
    }

    private func loadGravatar(for email: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let emailData = trimmedEmail.data(using: .utf8) else { return }
        let hash = Insecure.MD5.hash(data: emailData)
        let hashString = hash.map { String(format: "%02hhx", $0) }.joined()
        let cacheKey = "gravatar-\(hashString)"

        if let cachedImage = CacheManager.shared.getCachedImage(for: cacheKey) {
            self.gravatarImage = cachedImage
            return
        }

        guard let url = URL(string: "https://www.gravatar.com/avatar/\(hashString)?d=identicon&s=100") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.gravatarImage = image
                    CacheManager.shared.cacheImage(image: image, for: cacheKey)
                }
            }
        }.resume()
    }
}
