import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Binding var isOnboarding: Bool
    @State private var notificationPermissionGranted = false
    @State private var hasCheckedPermissions = false

    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "667eea"),
                    Color(hex: "764ba2"),
                    Color(hex: "f093fb"),
                    Color(hex: "f5576c")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle pattern overlay
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    path.move(to: CGPoint(x: 0, y: height * 0.3))
                    path.addQuadCurve(to: CGPoint(x: width, y: height * 0.7),
                                     control: CGPoint(x: width * 0.5, y: height * 0.5))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.05))
            }

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

                if !notificationPermissionGranted {
                    NotificationPermissionPage(
                        permissionGranted: $notificationPermissionGranted,
                        isOnboarding: $isOnboarding
                    )
                }

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
        .onAppear {
            checkNotificationPermissions()
        }
    }

    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
                self.hasCheckedPermissions = true
            }
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
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .foregroundColor(.green)
                    .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 2)
            }

            VStack(spacing: 15) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }

            if showsDismissButton {
                VStack(spacing: 15) {
                    Button(action: {
                        isOnboarding = false
                    }) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .padding(.vertical, 16)
                            .padding(.horizontal, 40)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }

                    Text("You can change settings later")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
}

struct NotificationPermissionPage: View {
    @Binding var permissionGranted: Bool
    @Binding var isOnboarding: Bool
    @State private var isRequestingPermission = false

    var body: some View {
        VStack(spacing: 25) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "bell.badge.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
            }
            .padding(.top, 20)

            Text("Stay on Track!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Enable notifications to get daily reminders for learning new words and keeping your garden healthy.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                Button(action: requestNotificationPermission) {
                    if isRequestingPermission {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Enable Notifications")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isRequestingPermission)

                Button(action: {
                    // Skip notifications and continue
                    permissionGranted = false
                }) {
                    Text("Maybe Later")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .padding()
    }

    private func requestNotificationPermission() {
        isRequestingPermission = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isRequestingPermission = false
                self.permissionGranted = granted

                if granted {
                    // Schedule a default daily notification at 8 PM
                    let calendar = Calendar.current
                    var components = DateComponents()
                    components.hour = 20
                    components.minute = 0

                    if let defaultTime = calendar.date(from: components) {
                        NotificationManager.shared.scheduleDailyNotification(at: defaultTime)
                    }
                }

                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}