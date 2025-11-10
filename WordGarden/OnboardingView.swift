import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarding: Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.4), Color.yellow.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            TabView {
                OnboardingPage(
                    imageName: "leaf.fill",
                    title: "Welcome to WordGarden!",
                    description: "Learn words by growing your garden.",
                    showsDismissButton: false,
                    isOnboarding: $isOnboarding
                )

                OnboardingPage(
                    imageName: "plus.circle.fill",
                    title: "Add New Words",
                    description: "Add new words to plant seeds in your garden.",
                    showsDismissButton: false,
                    isOnboarding: $isOnboarding
                )

                OnboardingPage(
                    imageName: "drop.fill",
                    title: "Grow Your Plants",
                    description: "Review words daily to help your plants grow strong!",
                    showsDismissButton: false,
                    isOnboarding: $isOnboarding
                )

                OnboardingPage(
                    imageName: "exclamationmark.triangle.fill",
                    title: "Keep Growing",
                    description: "Don’t forget to review—otherwise your plants might wilt!",
                    showsDismissButton: true,
                    isOnboarding: $isOnboarding
                )
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

struct OnboardingPage: View {
    let imageName: String
    let title: String
    let description: String
    let showsDismissButton: Bool
    @Binding var isOnboarding: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.green)

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)


            Text(description)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if showsDismissButton {
                Button(action: {
                    isOnboarding = false
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .padding()
    }
}