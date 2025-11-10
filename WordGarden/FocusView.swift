import SwiftUI
import AVFoundation

struct FocusView: View {
    @EnvironmentObject var treeService: TreeService
    @EnvironmentObject var wordStorage: WordStorage
    @Environment(\.scenePhase) private var scenePhase
    @State private var isFocusing = false
    @State private var timeRemaining = 1500 // 25 minutes in seconds
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var startTime: Date?
    @State private var selectedMinutes: Int = 25
    @State private var backgroundEntryTime: Date?

    let focusTimeOptions = [5, 10, 15, 25, 30] // minutes

    var body: some View {
        ZStack {
            // Peaceful background
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Focus Garden")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Choose your focus time and grow your garden while staying focused.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if !isFocusing {
                    VStack(spacing: 15) {
                        Text("Select Focus Duration:")
                            .font(.title2)

                        HStack(spacing: 10) {
                            ForEach(focusTimeOptions, id: \.self) { minutes in
                                Button("\(minutes)m") {
                                    startFocusSession(minutes: minutes)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                                .frame(width: 200, height: 200)

                             Circle()
                                 .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(selectedMinutes * 60))
                                 .stroke(Color.blue, lineWidth: 10)
                                .frame(width: 200, height: 200)
                                .rotationEffect(.degrees(-90))

                            VStack {
                                Text(timeString(from: timeRemaining))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("Focus Time")
                                    .font(.caption)
                            }
                        }

                        Button("End Focus Session") {
                            endFocusSession()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }

                Spacer()

                // Garden visualization
                Text(treeImage(for: treeService.tree.level, maxLevel: treeService.maxTreeLevel))
                    .font(.system(size: 100))
            } // close VStack
            .padding()
        } // close ZStack
        .onAppear {
            playAmbientSound()
        }
        .onDisappear {
            stopAmbientSound()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background && isFocusing {
                backgroundEntryTime = Date()
            } else if newPhase == .active && isFocusing, let entryTime = backgroundEntryTime {
                let elapsed = Date().timeIntervalSince(entryTime)
                timeRemaining = max(0, timeRemaining - Int(elapsed))
                backgroundEntryTime = nil
                if timeRemaining == 0 {
                    endFocusSession()
                }
            }
        }
    }

    private func startFocusSession(minutes: Int) {
        selectedMinutes = minutes
        startTime = Date()
        timeRemaining = minutes * 60
        isFocusing = true
        wordStorage.addLogEntry("Started focus session for \(minutes) minutes")

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endFocusSession()
            }
        }
    }

    private func endFocusSession() {
        timer?.invalidate()
        timer = nil
        isFocusing = false
        startTime = nil

        // Reward growth
        for _ in 0..<3 { // Water 3 times as reward
            treeService.waterTree()
        }
        wordStorage.addLogEntry("Completed focus session, rewarded with growth")
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func playAmbientSound() {
        // Play a simple ambient sound (you'd need to add a sound file to the bundle)
        // For now, just placeholder
    }

    private func stopAmbientSound() {
        audioPlayer?.stop()
    }

    private func treeImage(for level: Int, maxLevel: Int) -> String {
        let progress = Double(level) / Double(maxLevel)
        switch progress {
        case 0..<0.2: return "🌱"
        case 0.2..<0.5: return "🌿"
        case 0.5..<0.8: return "🌳"
        case 0.8..<1.0: return "🌳🌳"
        case 1.0: return "🌳🌳🌳"
        default: return "🌱"
        }
    }
}