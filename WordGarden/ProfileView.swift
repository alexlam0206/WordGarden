import SwiftUI
import FirebaseAuth
import CryptoKit

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var wordStorage: WordStorage
    @EnvironmentObject var treeService: TreeService
    @EnvironmentObject var cloudSyncManager: CloudSyncManager
    @State private var gravatarImage: UIImage? = nil
    @State private var showingSignOutConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = authViewModel.user {
                        // Profile Header
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 130, height: 130)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                if let image = gravatarImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                        .shadow(radius: 5)
                                        .onAppear { loadGravatar(for: user.email ?? "") }
                                } else {
                                    ProgressView()
                                        .frame(width: 100, height: 100)
                                        .onAppear { loadGravatar(for: user.email ?? "") }
                                }
                            }

                            Text(user.displayName ?? "User")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text(user.email ?? "")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical)

                        // Statistics Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Your Progress")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                StatCard(title: "Total Words", value: "\(wordStorage.words.count)", icon: "📚")
                                StatCard(title: "Mastered Words", value: "\(wordStorage.words.filter { $0.growthLevel == 5 }.count)", icon: "🌟")
                                StatCard(title: "Trees Grown", value: "\(treeService.treesGrown)", icon: "🌳")
                                StatCard(title: "Current Level", value: "\(treeService.tree.level)", icon: "📈")
                            }
                        }
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]), startPoint: .top, endPoint: .bottom))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // Achievements Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Achievements")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                AchievementCard(title: "First Word", description: "Added your first word", unlocked: wordStorage.words.count > 0)
                                AchievementCard(title: "Tree Master", description: "Grew your first tree", unlocked: treeService.treesGrown > 0)
                                AchievementCard(title: "Word Scholar", description: "Mastered 10 words", unlocked: wordStorage.words.filter { $0.growthLevel == 5 }.count >= 10)
                                AchievementCard(title: "Dedicated Learner", description: "Logged in for 7 days", unlocked: false) // Placeholder
                            }
                        }
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]), startPoint: .top, endPoint: .bottom))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                        // Actions
                        VStack(spacing: 15) {
                            Button(action: {
                                showingSignOutConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                        .font(.title2)
                                    Text("Sign Out")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]), startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(12)
                                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .alert(isPresented: $showingSignOutConfirmation) {
                                Alert(
                                    title: Text("Sign Out"),
                                    message: Text("Are you sure you want to sign out?"),
                                    primaryButton: .destructive(Text("Sign Out")) {
                                        authViewModel.signOut()
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                        .padding(.horizontal)

                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            Text("Not signed in")
                                .font(.title)
                            Text("Sign in to sync your progress across devices")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 50)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button(action: {
                // Settings action, placeholder
            }) {
                Image(systemName: "gear")
            })
            .onAppear {
                Task {
                    try? await cloudSyncManager.downloadAllData(wordStorage: wordStorage, treeService: treeService)
                }
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 30))
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 15)
        .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color(.secondarySystemBackground)]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct AchievementCard: View {
    let title: String
    let description: String
    let unlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(unlocked ? "🏆" : "🔒")
                    .font(.system(size: 24))
                Spacer()
                if unlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(unlocked ? .primary : .secondary)
            Text(description)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(unlocked ? LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [Color(.secondarySystemBackground), Color(.tertiarySystemBackground)]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(12)
        .shadow(color: unlocked ? Color.blue.opacity(0.2) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(unlocked ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}