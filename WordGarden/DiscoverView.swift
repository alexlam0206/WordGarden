import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @State private var wordOfTheDay: Word?
    @State private var isLoadingWordOfDay = false
    @State private var randomWords: [Word] = []
    @State private var isLoadingRandom = false
    @State private var dailyTasks: [String] = [
        "Add 3 new words to your garden",
        "Review 5 flashcards",
        "Complete a focus session",
        "Explore the word tree"
    ]
    @State private var completedTasks: Set<String> = []
    @State private var showingPhotoVocab = false
    @State private var showingCategories = false
    @State private var navigateToPhotoVocab = false
    @State private var navigateToCategories = false
    @State private var navigateToRandom = false
    
    // Layout configuration
    @State private var isCompactLayout = false
    @State private var gridColumns: [GridItem] = []
    
    // Accessibility
    @AccessibilityFocusState private var isWordOfDayFocused: Bool

    // UserDefaults keys
    private let completedTasksKey = "completedTasks"
    private let lastResetDateKey = "lastResetDate"

    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background with dark mode support
                AdaptiveGradientBackground()
                    .accessibilityHidden(true)
                
                ScrollView {
                    ResponsiveBentoGrid {
                        // Word of the Day - Featured Item
                        FeaturedBentoCard(
                            title: "Word of the Day",
                            icon: "star.fill",
                            color: .yellow,
                            isLoading: isLoadingWordOfDay
                        ) {
                            if let word = wordOfTheDay {
                                WordOfDayContent(word: word)
                            } else {
                                EmptyWordContent()
                            }
                        }
                        .gridCellColumns(featuredItemColumns)
                        .accessibilityLabel("Word of the day")
                        .accessibilityHint(isLoadingWordOfDay ? "Loading today's featured word" : "Tap to view word details and examples")
                        .accessibilityAddTraits(.isButton)
                        
                        // Daily Tasks - Interactive Card
                        InteractiveBentoCard(
                            title: "Daily Tasks",
                            icon: "checklist",
                            color: .orange,
                            progress: Double(completedTasks.count) / Double(dailyTasks.count)
                        ) {
                            DailyTasksContent(
                                tasks: dailyTasks,
                                completedTasks: completedTasks,
                                onTaskToggle: toggleTask
                            )
                        }
                        .gridCellColumns(featuredItemColumns)
                        .accessibilityLabel("Daily tasks")
                        .accessibilityHint("\(completedTasks.count) of \(dailyTasks.count) tasks completed. Tap to view and manage tasks.")
                        
                        // Action Cards Row
                        ActionBentoCard(
                            title: "From Photo",
                            icon: "camera.fill",
                            color: .blue,
                            action: { navigateToPhotoVocab = true }
                        )
                        .accessibilityLabel("Photo vocabulary")
                        .accessibilityHint("Take a photo to learn new words from the image")
                        
                        ActionBentoCard(
                            title: "Random",
                            icon: "shuffle",
                            color: .green,
                            action: { 
                                generateRandomWords()
                                navigateToRandom = true 
                            },
                            isLoading: isLoadingRandom
                        )
                        .accessibilityLabel("Random words")
                        .accessibilityHint(isLoadingRandom ? "Loading random words" : "Generate random words to learn")
                        
                        ActionBentoCard(
                            title: "Categories",
                            icon: "list.bullet",
                            color: .purple,
                            action: { navigateToCategories = true }
                        )
                        .accessibilityLabel("Word categories")
                        .accessibilityHint("Browse words organized by categories")
                        
                        // Random Words Card
                        if !randomWords.isEmpty || isLoadingRandom {
                            DynamicBentoCard(
                                title: "Random Words",
                                icon: "dice.fill",
                                color: .pink,
                                isLoading: isLoadingRandom
                            ) {
                                RandomWordsContent(words: randomWords)
                            }
                            .gridCellColumns(featuredItemColumns)
                            .accessibilityLabel("Random words list")
                            .accessibilityHint(isLoadingRandom ? "Loading random words" : "\(randomWords.count) words available. Tap to view details.")
                        }
                    }
                    .accessibilityLabel("Discover content grid")
                    .accessibilityHint("Contains word of the day, daily tasks, and learning activities")
                    .accessibilitySortPriority(1)
                    .accessibilityElement(children: .contain)
                    .padding(.horizontal, gridPadding)
                    .padding(.vertical, gridPadding * 0.5)
                    .accessibilityElement(children: .contain)
                }
                // Hidden navigation links
                NavigationLink(destination: PhotoVocabView(), isActive: $navigateToPhotoVocab) { EmptyView() }
                    .hidden()
                NavigationLink(destination: CategoriesView(), isActive: $navigateToCategories) { EmptyView() }
                    .hidden()
                NavigationLink(destination: RandomWordsView(randomWords: $randomWords, isLoading: $isLoadingRandom, onRefresh: generateRandomWords), isActive: $navigateToRandom) { EmptyView() }
                    .hidden()
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(.systemBackground).opacity(0.95), for: .navigationBar)
            .accessibilityLabel("Discover learning content")
            .accessibilityHint("Explore word of the day, daily tasks, and learning activities")
            .navigationViewStyle(.stack)
            .onAppear {
                wordStorage.addLogEntry("Opened Discover tab")
                loadCompletedTasks()
                checkAndResetDailyTasks()
                loadWordOfTheDay()
                setupResponsiveLayout()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                checkAndResetDailyTasks()
            }
        }
    }
    
    // MARK: - Responsive Layout Configuration
    
    private var featuredItemColumns: Int {
        isCompactLayout ? 1 : 2
    }
    
    private var gridPadding: CGFloat {
        isCompactLayout ? 12 : 20
    }
    
    private func setupResponsiveLayout() {
        let horizontalSizeClass = UIScreen.main.traitCollection.horizontalSizeClass
        isCompactLayout = horizontalSizeClass == .compact
    }
    
    private func getWordOfTheDay() -> String {
        if !wordStorage.words.isEmpty {
            let calendar = Calendar.current
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
            let index = dayOfYear % wordStorage.words.count
            return wordStorage.words[index].text
        } else {
            // Fallback to predefined words if user has no words
            let words = ["serendipity", "ephemeral", "lucid", "resilient", "ethereal", "pragmatic", "eloquent", "tenacious", "ubiquitous", "voracious"]
            let calendar = Calendar.current
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
            return words[dayOfYear % words.count]
        }
    }
    
    private func generateRandomWords() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoadingRandom = true
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            randomWords.removeAll()
        }

        let randomWordTexts = ["curious", "brilliant", "mysterious", "vibrant", "whimsical", "profound", "radiant", "intriguing"]
        var newWords: [Word] = []
        for wordText in randomWordTexts.shuffled().prefix(3) {
            let word = Word(
                text: wordText,
                definition: "Add your own definition.",
                example: ""
            )
            newWords.append(word)
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            randomWords = newWords
            isLoadingRandom = false
        }
    }
    
    private func toggleTask(_ task: String) {
        if completedTasks.contains(task) {
            completedTasks.remove(task)
        } else {
            completedTasks.insert(task)
        }
        saveCompletedTasks()
        wordStorage.addLogEntry("Toggled task: \(task) - \(completedTasks.contains(task) ? "completed" : "uncompleted")")
    }
    
    private func saveCompletedTasks() {
        UserDefaults.standard.set(Array(completedTasks), forKey: completedTasksKey)
        // Also save to shared UserDefaults for widgets
        let sharedDefaults = UserDefaults(suiteName: "group.com.nok.WordGarden")
        sharedDefaults?.set(Array(completedTasks), forKey: completedTasksKey)
    }
    
    private func loadCompletedTasks() {
        if let savedTasks = UserDefaults.standard.array(forKey: completedTasksKey) as? [String] {
            completedTasks = Set(savedTasks)
        }
    }
    
    private func checkAndResetDailyTasks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastResetDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date {
            let lastResetDay = calendar.startOfDay(for: lastResetDate)

            // If it's a new day, reset the tasks
            if today > lastResetDay {
                completedTasks.removeAll()
                saveCompletedTasks()
                UserDefaults.standard.set(today, forKey: lastResetDateKey)
                wordStorage.addLogEntry("Daily tasks reset for new day")
            }
        } else {
            // First time - set today's date
            UserDefaults.standard.set(today, forKey: lastResetDateKey)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadWordOfTheDay() {
        isLoadingWordOfDay = true
        let wordOfDayText = getWordOfTheDay()
        if let word = wordStorage.words.first(where: { $0.text.lowercased() == wordOfDayText.lowercased() }) {
            withAnimation(.easeInOut(duration: 0.25)) {
                wordOfTheDay = word
            }
        } else {
            let newWord = Word(
                text: wordOfDayText,
                definition: "Add your own definition.",
                example: ""
            )
            withAnimation(.easeInOut(duration: 0.25)) {
                wordOfTheDay = newWord
            }
        }
        isLoadingWordOfDay = false
    }
    


// MARK: - Supporting Views

struct RandomWordsView: View {
    @Binding var randomWords: [Word]
    @Binding var isLoading: Bool
    var onRefresh: () -> Void

    var body: some View {
        List {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                ForEach(randomWords) { word in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(word.text.capitalized)
                            .font(.headline)
                        if !word.definition.isEmpty {
                            Text(word.definition)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Random Words")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    onRefresh()
                }
            }
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
            .environmentObject(WordStorage())
    }
}

struct CategoriesView: View {
    let categories = [
        ("Nature", ["forest", "mountain", "ocean", "sunset"]),
        ("Emotions", ["joy", "melancholy", "serenity", "passion"]),
        ("Abstract", ["time", "space", "infinity", "eternity"]),
        ("Colors", ["crimson", "azure", "emerald", "amber"])
    ]
    @State private var selectedWord: Word?

    var body: some View {
        List {
            ForEach(categories, id: \.0) {
                category, words in
                Section(header: Text(category).font(.system(size: 18, weight: .semibold, design: .rounded))) {
                    ForEach(words, id: \.self) {
                        word in
                        Button(action: {
                            selectedWord = Word(text: word, definition: "", example: "")
                        }) {
                            HStack {
                                Text(word.capitalized)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
        }
        .navigationTitle("Word Categories")
        .listStyle(InsetGroupedListStyle())
        .sheet(item: $selectedWord) { word in
            WordDetailView(word: .constant(word))
        }
    }
}

struct BentoBox<Content: View>: View {
    let content: Content
    var title: String
    var icon: String
    var color: Color

    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            VStack(alignment: .leading, spacing: 8) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}


// MARK: - Adaptive Components

struct AdaptiveGradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.5),
                colorScheme == .dark ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ResponsiveBentoGrid<Content: View>: View {
    let content: Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var hasAppeared = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        let isCompact = horizontalSizeClass == .compact
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: isCompact ? 1 : 2)
        LazyVGrid(columns: columns, spacing: 12) {
            content
                .opacity(hasAppeared ? 1.0 : 0.0)
                .scaleEffect(hasAppeared ? 1.0 : 0.95)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }
}

struct FeaturedBentoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let content: Content
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(title: String, icon: String, color: Color, isLoading: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isLoading = isLoading
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolEffect(.pulse, isActive: isLoading)
                    .scaleEffect(isLoading ? 1.1 : (isHovered ? 1.1 : 1.0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isLoading)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                Spacer()
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .transition(.scale.combined(with: .opacity))
            } else {
                content
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(color.opacity(isHovered || isPressed ? 0.4 : 0.2), lineWidth: isHovered || isPressed ? 2 : 1)
        )
        .shadow(color: color.opacity(isHovered || isPressed ? 0.2 : 0.1), radius: isHovered || isPressed ? 12 : 8, x: 0, y: isHovered || isPressed ? 6 : 4)
        .scaleEffect(isLoading ? 0.95 : (isPressed ? 0.98 : (isHovered ? 1.02 : 1.0)))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isLoading)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onTapGesture {
            if !isLoading {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isPressed = false
                    }
                }
            }
        }
        .onHover { hovering in
            if !isLoading {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) card")
        .accessibilityHint(isLoading ? "Loading content" : "Dynamic content card")
        .accessibilityAddTraits(.isButton)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct InteractiveBentoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let progress: Double
    let content: Content
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(title: String, icon: String, color: Color, progress: Double = 0.0, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.progress = progress
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                Spacer()
            }
            
            if progress > 0 {
                ProgressView(value: progress)
                    .tint(color)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
            
            content
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(color.opacity(isHovered || isPressed ? 0.4 : 0.2), lineWidth: isHovered || isPressed ? 2 : 1)
        )
        .shadow(color: color.opacity(isHovered || isPressed ? 0.2 : 0.1), radius: isHovered || isPressed ? 12 : 8, x: 0, y: isHovered || isPressed ? 6 : 4)
        .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onTapGesture {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) card")
        .accessibilityHint("Interactive card with progress tracking")
        .accessibilityAddTraits(.isButton)
    }
}

struct ActionBentoCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let isLoading: Bool
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(title: String, icon: String, color: Color, action: @escaping () -> Void, isLoading: Bool = false) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                withAnimation {
                    isPressed = false
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .symbolEffect(.pulse, isActive: isLoading)
                        .scaleEffect(isLoading ? 1.1 : 1.0)
                    Spacer()
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(16)
            .frame(minHeight: 100)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(isHovered || isPressed ? 0.4 : 0.2), lineWidth: isHovered || isPressed ? 2 : 1)
            )
            .shadow(color: color.opacity(isHovered || isPressed ? 0.2 : 0.1), radius: isHovered || isPressed ? 8 : 6, x: 0, y: isHovered || isPressed ? 4 : 3)
            .scaleEffect(isLoading ? 0.95 : (isPressed ? 0.92 : (isHovered ? 1.05 : 1.0)))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "Tap to perform action")
        .accessibilityAddTraits(isLoading ? [] : .isButton)
    }
}

struct DynamicBentoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let content: Content
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(title: String, icon: String, color: Color, isLoading: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isLoading = isLoading
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolEffect(.pulse, isActive: isLoading)
                    .scaleEffect(isLoading ? 1.1 : (isHovered ? 1.1 : 1.0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isLoading)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                Spacer()
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                content
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(color.opacity(isHovered || isPressed ? 0.4 : 0.2), lineWidth: isHovered || isPressed ? 2 : 1)
        )
        .shadow(color: color.opacity(isHovered || isPressed ? 0.2 : 0.1), radius: isHovered || isPressed ? 12 : 8, x: 0, y: isHovered || isPressed ? 6 : 4)
        .scaleEffect(isLoading ? 0.95 : (isPressed ? 0.98 : (isHovered ? 1.02 : 1.0)))
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isLoading)
        .onTapGesture {
            if !isLoading {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isPressed = false
                    }
                }
            }
        }
        .onHover { hovering in
            if !isLoading {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Content Components

struct WordOfDayContent: View {
    let word: Word
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(word.text.capitalized)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Text(word.definition)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .accessibilityLabel("Definition: \(word.definition)")
            
            if !word.example.isEmpty {
                Text("Example: \(word.example)")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
                    .italic()
                    .accessibilityLabel("Example usage: \(word.example)")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Word of the day: \(word.text.capitalized)")
        .accessibilityHint("\(word.definition)" + (word.example.isEmpty ? "" : " Example: \(word.example)"))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyWordContent: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text("Loading word of the day...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
        .accessibilityLabel("Loading word of the day")
        .accessibilityHint("Please wait while we fetch today's word")
    }
}

struct DailyTasksContent: View {
    let tasks: [String]
    let completedTasks: Set<String>
    let onTaskToggle: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(tasks, id: \.self) { task in
                HStack {
                    Image(systemName: completedTasks.contains(task) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(completedTasks.contains(task) ? .green : .secondary)
                        .font(.title3)
                    
                    Text(task)
                        .font(.body)
                        .strikethrough(completedTasks.contains(task))
                        .foregroundColor(completedTasks.contains(task) ? .secondary : .primary)
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        onTaskToggle(task)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(completedTasks.contains(task) ? "Completed: \(task)" : "Not completed: \(task)")
                .accessibilityAddTraits(completedTasks.contains(task) ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

struct RandomWordsContent: View {
    let words: [Word]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(words.prefix(3), id: \.id) { word in
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.text.capitalized)
                        .font(.headline)
                        .fontWeight(.medium)
                        .accessibilityAddTraits(.isHeader)
                    
                    if !word.definition.isEmpty {
                        Text(word.definition)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .accessibilityLabel("Definition: \(word.definition)")
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(word.text.capitalized): \(word.definition)")
            }
        }
        .accessibilityLabel("Random words list")
    }
}

// MARK: - Legacy Components

struct DiscoverActionCard: View {
    var title: String
    var icon: String
    var color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                Spacer()
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}



struct CategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CategoriesView()
        }
        .preferredColorScheme(.light)
    }
}

struct RandomWordsView_Previews: PreviewProvider {
    static var previews: some View {
        RandomWordsPreviewContainer()
            .preferredColorScheme(.light)
    }
}

struct RandomWordsPreviewContainer: View {
        @State var randomWords: [Word] = [
            Word(text: "curious", definition: "Eager to know or learn something.", example: ""),
            Word(text: "radiant", definition: "Sending out light; shining or glowing brightly.", example: "")
        ]
        @State var isLoading: Bool = false

        var body: some View {
            NavigationView {
                RandomWordsView(randomWords: $randomWords, isLoading: $isLoading, onRefresh: {})
            }
        }
    }
}
