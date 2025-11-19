import SwiftUI
import AVFoundation

struct FocusView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var treeService: TreeService
    @EnvironmentObject var wordStorage: WordStorage
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isFocusing = false
    @State private var timeRemaining: Int = 1500
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    
    // For state restoration
    @State private var backgroundEntryTime: Date?
    @State private var initialDuration: Int = 1500

    // For the time pickers (hours and minutes)
    @State private var focusHours: Int = 0
    @State private var focusMinutes: Int = 25

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color.blue.opacity(0.25),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
            VStack(spacing: 20) {
                Text("🌙 Focus Garden")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                    .shadow(color: Color.white.opacity(0.3), radius: 5, x: 0, y: 2)

                if !isFocusing {
                    VStack(spacing: 25) {
                        Text("Choose your focus time and grow your garden while staying focused.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .foregroundColor(.white.opacity(0.9))
                        
                        // Vertical Time Picker (like Timer app)
                        VStack(spacing: 20) {
                            Text("Set Focus Time")
                                .font(.title2)
                                .fontWeight(.semibold)

                            HStack(spacing: 40) {
                                // Hours Picker
                                VStack {
                                    Text("\(focusHours)")
                                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                                        .foregroundColor(.blue)
                                    Text("hours")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text(":")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.secondary)

                                // Minutes Picker
                                VStack {
                                    Text(String(format: "%02d", focusMinutes))
                                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                                        .foregroundColor(.blue)
                                    Text("min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Time Pickers (like iOS Timer app)
                            HStack(spacing: 20) {
                                // Hours Picker
                                VStack {
                                    Picker("Hours", selection: $focusHours) {
                                        ForEach(0...23, id: \.self) { hour in
                                            Text("\(hour)")
                                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 80, height: 120)
                                    .clipped()

                                    Text("hours")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                // Minutes Picker
                                VStack {
                                    Picker("Minutes", selection: $focusMinutes) {
                                        ForEach(0...59, id: \.self) { minute in
                                            Text(String(format: "%02d", minute))
                                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 80, height: 120)
                                    .clipped()

                                    Text("min")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(.vertical)

                        Button("Start Focusing") {
                            let totalSeconds = (focusHours * 3600) + (focusMinutes * 60)
                            startFocusSession(seconds: totalSeconds)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(focusHours == 0 && focusMinutes == 0)
                        
                    }
                } else {
                     VStack(spacing: 30) {
                         ZStack {
                             // Background circle
                             Circle()
                                 .fill(Color.white.opacity(0.1))
                                 .frame(width: 280, height: 280)

                             // Progress circle
                             Circle()
                                 .stroke(Color.white.opacity(0.2), lineWidth: 8)
                                 .frame(width: 260, height: 260)

                             Circle()
                                 .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(initialDuration))
                                 .stroke(
                                     AngularGradient(
                                         gradient: Gradient(colors: [Color.indigo, Color.purple]),
                                         center: .center,
                                         startAngle: .degrees(-90),
                                         endAngle: .degrees(270)
                                     ),
                                     style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                 )
                                 .rotationEffect(.degrees(-90))
                                 .frame(width: 260, height: 260)
                                 .animation(.linear(duration: 1), value: timeRemaining)

                             VStack(spacing: 5) {
                                 Text(timeString(from: timeRemaining))
                                     .font(.system(size: 48, weight: .bold, design: .monospaced))
                                     .foregroundColor(.white)
                                 Text("Focus Time")
                                     .font(.system(size: 16, weight: .medium, design: .rounded))
                                     .foregroundColor(.white.opacity(0.8))
                             }
                         }
                         .frame(width: 280, height: 280)
                         .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)

                         Button("End Focus Session") {
                             endFocusSession(completed: false)
                         }
                         .font(.system(size: 18, weight: .semibold, design: .rounded))
                         .padding(.vertical, 12)
                         .padding(.horizontal, 24)
                         .background(Color.red.opacity(0.8))
                         .foregroundColor(.white)
                         .cornerRadius(25)
                         .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 4)
                     }
                }

                Spacer()

                // Garden visualization with beautiful styling
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 5)

                    Text(treeImage(for: treeService.tree.level, maxLevel: treeService.maxTreeLevel))
                        .font(.system(size: 60))
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            }

            // Exit Button - positioned to avoid overlap
            Button(action: {
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 50)
            .padding(.trailing, 20)

        }
        .onAppear(perform: playAmbientSound)
        .onDisappear(perform: stopAmbientSound)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background && isFocusing {
                backgroundEntryTime = Date()
                timer?.invalidate() // Stop timer in background
            } else if newPhase == .active && isFocusing, let entryTime = backgroundEntryTime {
                let elapsed = Date().timeIntervalSince(entryTime)
                timeRemaining = max(0, timeRemaining - Int(elapsed))
                backgroundEntryTime = nil
                if timeRemaining > 0 {
                    // Restart timer
                    startTimer()
                } else {
                    endFocusSession(completed: true)
                }
            }
        }
    }

    private func startFocusSession(seconds: Int) {
        guard seconds > 0 else { return }
        initialDuration = seconds
        timeRemaining = seconds
        isFocusing = true
        wordStorage.addLogEntry("Started focus session for \(timeString(from: seconds))")
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate() // Ensure no multiple timers
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endFocusSession(completed: true)
            }
        }
    }

    private func endFocusSession(completed: Bool) {
        timer?.invalidate()
        timer = nil
        isFocusing = false
        
        if completed {
            // Reward growth
            for _ in 0..<3 { // Water 3 times as reward
                treeService.waterTree()
            }
            wordStorage.addLogEntry("Completed focus session, rewarded with growth")
        } else {
            wordStorage.addLogEntry("Ended focus session early")
        }
    }

    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = (seconds % 3600) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
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
