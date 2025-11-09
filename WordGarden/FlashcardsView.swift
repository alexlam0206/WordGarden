import SwiftUI

struct FlashcardsView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @EnvironmentObject var treeService: TreeService
    @State private var flashcards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var showDefinition = false
    @State private var isLoading = false
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading flashcards...")
            } else if flashcards.isEmpty {
                Text("No words available for flashcards. Add some words first.")
                    .padding()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 350)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .padding()

                    if showDefinition {
                        VStack {
                            Spacer()
                            Text("Definition")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(flashcards[currentIndex].definition)
                                .font(.title2)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    } else {
                        VStack {
                            Spacer()
                            Text("Word")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(flashcards[currentIndex].word.capitalized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            Spacer()
                        }
                    }
                }
                .rotation3DEffect(.degrees(showDefinition ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .offset(x: dragOffset)
                .scaleEffect(showDefinition ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showDefinition)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height

                            if abs(horizontalAmount) > abs(verticalAmount) {
                                if horizontalAmount > 20 {
                                    previousCard()
                                    treeService.waterTree()
                                } else if horizontalAmount < -20 {
                                    nextCard()
                                    treeService.waterTree()
                                }
                            }
                        }
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showDefinition.toggle()
                    }
                    treeService.waterTree()
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

                    Text("\(currentIndex + 1) / \(flashcards.count)")

                    Spacer()

                    Button(action: nextCard) {
                        Image(systemName: "chevron.right")
                            .font(.title)
                    }
                    .disabled(currentIndex == flashcards.count - 1)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Flashcards")
        .onAppear {
            wordStorage.addLogEntry("Opened Flashcards tab")
        }
        .task {
            await loadFlashcards()
        }
    }

    private func loadFlashcards() async {
        isLoading = true
        flashcards = await wordStorage.generateFlashcards()
        isLoading = false
        wordStorage.addLogEntry("Loaded \(flashcards.count) flashcards")
        print("Flashcards log: Loaded \(flashcards.count) flashcards")
    }

    private func nextCard() {
        if currentIndex < flashcards.count - 1 {
            currentIndex += 1
            showDefinition = false
            wordStorage.addLogEntry("Swiped to next card: \(flashcards[currentIndex].word)")
            print("Flashcards log: Swiped to next card: \(flashcards[currentIndex].word)")
        }
    }

    private func previousCard() {
        if currentIndex > 0 {
            currentIndex -= 1
            showDefinition = false
            wordStorage.addLogEntry("Swiped to previous card: \(flashcards[currentIndex].word)")
            print("Flashcards log: Swiped to previous card: \(flashcards[currentIndex].word)")
        }
    }
}