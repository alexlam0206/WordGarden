
import SwiftUI
import GoogleSignIn
import CryptoKit

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var wordStorage: WordStorage

    var body: some View {
        VStack {
            if let user = authViewModel.user {
                AsyncImage(url: gravatarURL(for: user.profile?.email ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .padding()

                Text(user.profile?.name ?? "User")
                    .font(.largeTitle)
                    .padding(.bottom, 2)

                Text(user.profile?.email ?? "")
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
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding()


                Spacer()

                Button("Sign Out") {
                    authViewModel.signOut()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text("Not signed in.")
            }
        }
        .padding()
    }

    private func gravatarURL(for email: String) -> URL? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let emailData = trimmedEmail.data(using: .utf8) else { return nil }
        let hash = Insecure.MD5.hash(data: emailData)
        let hashString = hash.map { String(format: "%02hhx", $0) }.joined()
        return URL(string: "https://www.gravatar.com/avatar/\(hashString)?d=identicon&s=100")
    }
}
