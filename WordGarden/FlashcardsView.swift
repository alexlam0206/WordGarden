import SwiftUI
import UIKit

struct FlashcardsView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @EnvironmentObject var treeService: TreeService
    @State private var wordsForFlashcards: [Word] = []
    @State private var currentIndex = 0
    @State private var showDefinition = false
    @State private var isLoading = false
    @State private var isShuffled = true
    @State private var showExample = true
    @State private var showControls = true
    @GestureState private var dragOffset: CGFloat = 0
    @State private var swipeState: SwipeDirection = .none
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var showHelp = false
    @State private var knownWords: Set<String> = []
    @State private var reviewWords: [Word] = []
    @State private var sessionWords: [Word] = []
    @State private var isReviewPhase = false
    @State private var isSessionComplete = false
    
    private var borderColorForSwipe: Color {
        switch swipeState {
        case .right:
            return Color.green
        case .left:
            return Color.red
        case .none:
            return Color.gray.opacity(0.3)
        }
    }
    
    private var swipeStateOverlayColor: Color {
        switch swipeState {
        case .right:
            return Color.green.opacity(0.25)
        case .left:
            return Color.red.opacity(0.25)
        case .none:
            return Color.clear
        }
    }

    enum SwipeDirection: String, CaseIterable {
        case none, left, right
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading flashcards...")
            } else if isSessionComplete {
                sessionCompletionView
            } else if wordsForFlashcards.isEmpty {
                Text("No words available for flashcards. Add some words first.")
                    .padding()
            } else {
                ZStack {
                    // Beautiful gradient background card
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(borderColorForSwipe, lineWidth: swipeState == .none ? 1 : 3)
                        )
                        .overlay(
                            swipeStateOverlayColor
                                .cornerRadius(28)
                                .allowsHitTesting(false)
                        )

                    if showDefinition {
                        VStack {
                            Spacer(minLength: 8)
                            Text("Definition")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            ScrollView {
                                VStack(spacing: 8) {
                                    Text(wordsForFlashcards[currentIndex].definition)
                                        .font(.title3)
                                        .padding(.horizontal)
                                        .multilineTextAlignment(.center)
                                    if showExample && !wordsForFlashcards[currentIndex].example.isEmpty {
                                        Text(wordsForFlashcards[currentIndex].example)
                                            .font(.callout)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .frame(maxHeight: 220)
                            Spacer(minLength: 8)
                        }
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    } else {
                        VStack {
                            Spacer()
                            Text("Word")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(wordsForFlashcards[currentIndex].text.capitalized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            if showExample && !wordsForFlashcards[currentIndex].example.isEmpty {
                                Text(wordsForFlashcards[currentIndex].example)
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                )
                .frame(height: 350)
                .padding()
                .rotation3DEffect(.degrees(showDefinition ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .offset(cardOffset)
                .rotationEffect(.degrees(cardRotation))
                .scaleEffect(showDefinition ? 1.05 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showDefinition)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: cardOffset)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: cardRotation)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            let width = value.translation.width
                            let height = value.translation.height
                            let threshold: CGFloat = 60
                            if abs(width) > threshold {
                                swipeState = width > 0 ? .right : .left
                            } else {
                                swipeState = .none
                            }
                            let rotation = width / 10
                            cardOffset = CGSize(width: width, height: height * 0.2)
                            cardRotation = rotation
                        }
                        .onEnded { value in
                            let width = value.translation.width
                            let threshold: CGFloat = 80
                            if abs(width) > threshold {
                                if width > 0 {
                                    // Mark as known (right swipe)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        cardOffset.width = 200
                                        cardRotation = 15
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        markWordAsKnown()
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        wordStorage.reviewWord(wordID: wordsForFlashcards[currentIndex].id)
                                        cardOffset = .zero
                                        cardRotation = 0
                                        swipeState = .none
                                    }
                                } else {
                                    // Mark as unknown (left swipe)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        cardOffset.width = -200
                                        cardRotation = -15
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        markWordAsUnknown()
                                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                        wordStorage.reviewWord(wordID: wordsForFlashcards[currentIndex].id)
                                        cardOffset = .zero
                                        cardRotation = 0
                                        swipeState = .none
                                    }
                                }
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    cardOffset = .zero
                                    cardRotation = 0
                                    swipeState = .none
                                }
                            }
                        }
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showDefinition.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    wordStorage.reviewWord(wordID: wordsForFlashcards[currentIndex].id)
                    let action = showDefinition ? "flipped to definition" : "flipped to word"
                    wordStorage.addLogEntry("Flipped card \(currentIndex + 1): \(action)")
                    print("Flashcards log: Flipped card \(currentIndex + 1): \(action)")
                }

                HStack {
                    Button(action: previousCard) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                    }
                    .disabled(currentIndex == 0)

                    Spacer()

                    VStack(spacing: 4) {
                        Text("\(currentIndex + 1) / \(wordsForFlashcards.count)")
                        if isReviewPhase {
                            Text("Review Phase")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    Spacer()

                    Button(action: nextCard) {
                        Image(systemName: "chevron.right")
                            .font(.title)
                    }
                    .disabled(currentIndex == wordsForFlashcards.count - 1)
                }
                .padding(.horizontal)

                if showControls {
                    VStack(spacing: 8) {
                        ProgressView(value: Double(currentIndex + 1), total: Double(wordsForFlashcards.count))
                            .tint(.blue)
                        HStack(spacing: 16) {
                            Toggle("Show example", isOn: $showExample)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                            Spacer()
                            Button(isShuffled ? "Unshuffle" : "Shuffle") {
                                withAnimation(.easeInOut) {
                                    isShuffled.toggle()
                                    reshuffleIfNeeded()
                                }
                            }
                        }
                        Button(action: { showHelp.toggle() }) {
                            Label("How to use", systemImage: "questionmark.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .sheet(isPresented: $showHelp) {
                            NavigationView {
                                VStack(alignment: .leading, spacing: 16) {
                                    Label("Swipe right → mark as known", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Label("Swipe left → mark for review", systemImage: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Label("Tap card → flip to definition", systemImage: "arrow.left.and.right.circle")
                                        .foregroundColor(.blue)
                                    Label("Use buttons to skip cards", systemImage: "chevron.left.and.right.circle")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding()
                                .navigationTitle("How to use")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Close") { showHelp = false }
                                    }
                                }
                            }
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
            }
        }
        .navigationTitle("Flashcards")
        .onAppear {
            wordStorage.addLogEntry("Opened Flashcards tab")
        }
        .task {
            await loadWordsForFlashcards()
            // reset animations
            cardOffset = .zero
            cardRotation = 0
            swipeState = .none
        }
    }

    private func loadWordsForFlashcards() async {
        isLoading = true
        let loadedWords = await wordStorage.generateWordsForFlashcards()
        sessionWords = loadedWords
        wordsForFlashcards = loadedWords
        if isShuffled {
            wordsForFlashcards.shuffle()
        }
        // Reset session state
        knownWords.removeAll()
        reviewWords.removeAll()
        isReviewPhase = false
        isSessionComplete = false
        currentIndex = 0
        isLoading = false
        wordStorage.addLogEntry("Loaded \(wordsForFlashcards.count) flashcards for new session")
        print("Flashcards log: Loaded \(wordsForFlashcards.count) flashcards for new session")
    }

    private func nextCard() {
        if currentIndex < wordsForFlashcards.count - 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                currentIndex += 1
            }
            showDefinition = false
            wordStorage.addLogEntry("Swiped to next card: \(wordsForFlashcards[currentIndex].text)")
            print("Flashcards log: Swiped to next card: \(wordsForFlashcards[currentIndex].text)")
        }
    }

    private func previousCard() {
        if currentIndex > 0 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                currentIndex -= 1
            }
            showDefinition = false
            wordStorage.addLogEntry("Swiped to previous card: \(wordsForFlashcards[currentIndex].text)")
            print("Flashcards log: Swiped to previous card: \(wordsForFlashcards[currentIndex].text)")
        }
    }

    private func reshuffleIfNeeded() {
        if isShuffled {
            wordsForFlashcards.shuffle()
            currentIndex = 0
            showDefinition = false
        } else {
            // regenerate in original order
            Task {
                await loadWordsForFlashcards()
            }
        }
    }
    
    private func markWordAsKnown() {
        let currentWord = wordsForFlashcards[currentIndex]
        knownWords.insert(currentWord.id.uuidString)
        treeService.awardStudyProgress()
        advanceToNextWord()
    }
    
    private func markWordAsUnknown() {
        let currentWord = wordsForFlashcards[currentIndex]
        if !reviewWords.contains(where: { $0.id == currentWord.id }) {
            reviewWords.append(currentWord)
        }
        treeService.awardStudyProgress()
        advanceToNextWord()
    }
    
    private func advanceToNextWord() {
        if currentIndex < wordsForFlashcards.count - 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                currentIndex += 1
            }
            showDefinition = false
            wordStorage.addLogEntry("Advanced to next card: \(wordsForFlashcards[currentIndex].text)")
            print("Flashcards log: Advanced to next card: \(wordsForFlashcards[currentIndex].text)")
        } else {
            // End of current deck, check if we have review words
            if !reviewWords.isEmpty && !isReviewPhase {
                startReviewPhase()
            } else {
                isSessionComplete = true
                treeService.awardStudyProgress()
                wordStorage.addLogEntry("Flashcard session complete. Known: \(knownWords.count), Review: \(reviewWords.count)")
                print("Flashcards log: Session complete. Known: \(knownWords.count), Review: \(reviewWords.count)")
            }
        }
    }
    
    private func startReviewPhase() {
        isReviewPhase = true
        wordsForFlashcards = reviewWords
        reviewWords = []
        currentIndex = 0
        showDefinition = false
        wordStorage.addLogEntry("Starting review phase with \(wordsForFlashcards.count) words")
        print("Flashcards log: Starting review phase with \(wordsForFlashcards.count) words")
    }
    
    private var sessionCompletionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Session Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text("✅ Known: \(knownWords.count) words")
                    .font(.headline)
                    .foregroundColor(.green)
                
                if isReviewPhase {
                    Text("📝 Reviewed: \(wordsForFlashcards.count) words")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
            
            Button("Start New Session") {
                Task {
                    await loadWordsForFlashcards()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct FlashcardsView_Previews: PreviewProvider {
    static var previews: some View {
        FlashcardsView()
            .environmentObject(WordStorage())
            .environmentObject(TreeService())
            .preferredColorScheme(.light)
    }
}
