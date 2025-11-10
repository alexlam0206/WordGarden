import SwiftUI
import SafariServices
import UniformTypeIdentifiers
import CryptoKit

// Backup data structure
struct BackupData: Codable {
    let words: [Word]
    let tree: Tree
    let wateringLogs: [WateringLog]
    let treesGrown: Int
}

// Document for JSON export
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    var suggestedFilename: String

    init(data: Data) {
        self.data = data
        self.suggestedFilename = "WordGarden Backup.json"
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        suggestedFilename = configuration.file.filename ?? "backup.json"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = data
        return FileWrapper(regularFileWithContents: data)
    }
}

// Document for text export
struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var text: String
    var suggestedFilename: String

    init(text: String, filename: String = "ActivityLog.txt") {
        self.text = text
        self.suggestedFilename = filename
    }

    init(configuration: ReadConfiguration) throws {
        text = ""
        suggestedFilename = "ActivityLog.txt"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

// Wrapper for SFSafariViewController
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No update needed
    }
}

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var wordStorage: WordStorage
    @EnvironmentObject var treeService: TreeService
    @EnvironmentObject var cloudSyncManager: CloudSyncManager
    @State private var showingClearCacheAlert = false
    @State private var showingSignOutAlert = false
    @State private var selectedURL: URL?
    @State private var showSafari: Bool = false
    @State private var showOnboarding = false
    @State private var showingExport = false
    @State private var showingImport = false
    @State private var importMessage: String?
    @State private var showingBackupAlert = false
    @State private var backupMessage: String?
    @State private var showingExportLog = false
    @State private var showingAISettings = false

    private static let defaultNotificationTime: TimeInterval = {
        var components = DateComponents()
        components.hour = 16
        components.minute = 0
        return Calendar.current.date(from: components)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
    }()

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notificationTime") private var notificationTime: TimeInterval = SettingsView.defaultNotificationTime
    
    var exportDocument: JSONDocument? {
        guard let data = exportData else { return nil }
        return JSONDocument(data: data)
    }

    var logDocument: TextDocument? {
        let today = Calendar.current.startOfDay(for: Date())
        if let todaysLog = wordStorage.dailyLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            let logText = todaysLog.logs.joined(separator: "\n")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            let filename = "WordGarden_log_\(timestamp).txt"
            return TextDocument(text: logText, filename: filename)
        }
        return nil
    }

    private var exportData: Data? {
        let backup = BackupData(words: wordStorage.words, tree: treeService.tree, wateringLogs: treeService.wateringLogs, treesGrown: treeService.treesGrown)
        guard let jsonData = try? JSONEncoder().encode(backup) else { return nil }
        return jsonData
    }

    var body: some View {
        NavigationView {
            settingsForm
        }
        .onChange(of: notificationsEnabled) { value in
            if value {
                wordStorage.addLogEntry("Enabled notifications")
                NotificationManager.shared.requestAuthorization()
                NotificationManager.shared.scheduleDailyNotification(at: Date(timeIntervalSince1970: notificationTime))
            } else {
                wordStorage.addLogEntry("Disabled notifications")
                NotificationManager.shared.cancelNotifications()
            }
        }
        .onChange(of: notificationTime) { newTime in
            if notificationsEnabled {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeString = timeFormatter.string(from: Date(timeIntervalSince1970: newTime))
                wordStorage.addLogEntry("Changed notification time to \(timeString)")
                NotificationManager.shared.scheduleDailyNotification(at: Date(timeIntervalSince1970: notificationTime))
            }
        }
    }

    private var settingsForm: some View {
        Form {
            Section(header: Text("Account")) {
                if authViewModel.user != nil {
                    NavigationLink(destination: ProfileView()) {
                        Text("View Profile")
                    }
                } else {
                    Button("Sign In") {
                        authViewModel.signIn()
                    }
                }
            }

            Section(header: Text("General")) {
                Button("Show Onboarding") {
                    showOnboarding = true
                }
            }

            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                if notificationsEnabled {
                    DatePicker("Notification Time", selection: Binding(
                        get: { Date(timeIntervalSince1970: notificationTime) },
                        set: { notificationTime = $0.timeIntervalSince1970 }
                    ), displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("AI")) {
                Button("AI Provider Settings") {
                    showingAISettings = true
                }
            }

            Section(header: Text("Cloud Sync")) {
                if cloudSyncManager.isLoggedIn {
                    if cloudSyncManager.syncing {
                        HStack {
                            ProgressView()
                            Text("Syncing...")
                        }
                    } else {
                        Button("Sync Now") {
                            Task {
                                try? await cloudSyncManager.uploadAllData(wordStorage: wordStorage, treeService: treeService)
                            }
                        }
                        .disabled(!cloudSyncManager.isConnected)
                        
                        Button("Restore from Cloud") {
                            Task {
                                try? await cloudSyncManager.downloadAllData(wordStorage: wordStorage, treeService: treeService)
                            }
                        }
                        .disabled(!cloudSyncManager.isConnected)
                    }
                    if !cloudSyncManager.isConnected {
                        Text("Connect to the internet to sync.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Sign in to enable cloud sync.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Data Management")) {
                Button("Export Data") {
                    showingExport = true
                }
                Button("Import Data") {
                    showingImport = true
                }
                if let message = importMessage {
                    Text(message)
                }
                Button("Export Today's Log") {
                    showingExportLog = true
                }
                Button("Clear Word Cache", role: .destructive) {
                    showingClearCacheAlert = true
                }
            }

            Section(header: Text("About")) {
                NavigationLink("About Me") {
                    aboutMeView
                }
                NavigationLink("Terms of Service") {
                    DocumentView(title: "Terms of Service", content: loadTxtFile(name: "terms-of-service"))
                }
                NavigationLink("Privacy Policy") {
                    DocumentView(title: "Privacy Policy", content: loadTxtFile(name: "privacy"))
                }
            }
            
            Section {
                Button("Sign Out", role: .destructive) {
                    showingSignOutAlert = true
                }
                .disabled(authViewModel.user == nil)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            wordStorage.addLogEntry("Opened Settings tab")
        }
        .sheet(isPresented: $showingAISettings) {
            AISettingsModalView()
        }
        .alert(isPresented: $showingClearCacheAlert) {
            Alert(
                title: Text("Clear Cache"),
                message: Text("Are you sure you want to delete all cached word definitions?"),
                primaryButton: .destructive(Text("Clear")) {
                    CacheManager.shared.clearCache()
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showingSignOutAlert) {
            Alert(
                title: Text("Sign Out"),
                message: Text("Are you sure you want to sign out?"),
                 primaryButton: .destructive(Text("Sign Out")) {
                     wordStorage.addLogEntry("Signed out")
                     authViewModel.signOut()
                 },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showSafari) {
            if let url = selectedURL {
                SafariView(url: url)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isOnboarding: $showOnboarding)
        }
        .fileExporter(isPresented: $showingExport, document: exportDocument, contentType: .json, defaultFilename: "WordGarden Backup") { result in
            // Handle export result if needed
        }
        .fileExporter(isPresented: $showingExportLog, document: logDocument, contentType: .plainText) { result in
            // Handle export result if needed
        }
        .fileImporter(isPresented: $showingImport, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                if let fileData = try? Data(contentsOf: url) {
                    if let backup = try? JSONDecoder().decode(BackupData.self, from: fileData) {
                        wordStorage.words = backup.words
                        treeService.tree = backup.tree
                        treeService.wateringLogs = backup.wateringLogs
                        treeService.treesGrown = backup.treesGrown
                        importMessage = "Data imported successfully"
                    } else {
                        importMessage = "Failed to import data"
                    }
                } else {
                    importMessage = "Failed to read file"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    importMessage = nil
                }
            case .failure:
                importMessage = "Import failed"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    importMessage = nil
                }
            }
        }
    }

    private var aboutMeView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("""
                Hello! I’m [Alex Lam](https://nok.is-a.dev/), a passionate student based in Hong Kong. I love crafting beautiful, functional web experiences and exploring the ever‑expanding world of technology.

                My journey in tech is fueled by curiosity, creativity and a commitment to building products that make a difference. When I’m not writing code, you’ll find me contributing to open‑source projects, learning new frameworks.
                """)
                
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
        }
        .navigationTitle("About Me")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadTxtFile(name: String) -> String {
        if let filepath = Bundle.main.path(forResource: name, ofType: "txt") {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return "Could not load file: \(error.localizedDescription)"
            }
        }
        return "File not found. Make sure '\(name).txt' is added to the target's 'Copy Bundle Resources'."
    }
}

// MARK: - AI Settings Modals

private struct AISettingsModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingLocalAISettings = false
    
    @AppStorage("geminiApiKey") private var geminiApiKey = ""
    @AppStorage("openaiApiKey") private var openaiApiKey = ""
    @AppStorage("openrouterApiKey") private var openrouterApiKey = ""
    @AppStorage("selectedOpenAIModel") private var selectedOpenAIModel = "gpt-5"
    

    @AppStorage("promptExplanation") private var promptExplanation = "Explain the word '{word}' in a simple way, in 30 words. DO NOT ADD ANY ADDITIONAL STUFF LIKE GREETINGS. ONLY INCLUDE THE ANSWER."
    @AppStorage("promptExample") private var promptExample = "Create a simple example sentence using the word '{word}'."
    @AppStorage("promptSimplify") private var promptSimplify = "Simplify this definition, ONLY GIVE ANSWER, NO GREETINGS, NO OTHER STUFF: {definition}"
    @AppStorage("promptSystemOpenRouter") private var promptSystemOpenRouter = "You are a helpful assistant of the learning app WordGarden. Only provide the direct answer to the user's request without any conversational filler. SO ONLY GIVE ANSWER, NO GREETINGS OR ANY ADDITIONAL INFORMATION."

    @State private var openAIModels: [String] = []
    @State private var isFetchingModels = false
    @State private var fetchModelsError: String?
    
    private var aiService: AIService {
        let localAIKey = UserDefaults.standard.string(forKey: "localAIAPIKey") ?? ""
        return AIService(geminiApiKey: geminiApiKey, openaiApiKey: openaiApiKey, openrouterApiKey: openrouterApiKey, localAIAPIKey: localAIKey)
    }
    
    private var promptSettings: [(title: String, binding: Binding<String>)] {
        [
            ("Explanation Prompt", $promptExplanation),
            ("Example Sentence Prompt", $promptExample),
            ("Simplify Definition Prompt", $promptSimplify),
            ("System Prompt", $promptSystemOpenRouter)
        ]
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cloud AI Providers")) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gemini")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("API Key", text: $geminiApiKey)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OpenAI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("API Key", text: $openaiApiKey)
                        
                        if isFetchingModels {
                            ProgressView()
                        }
                        
                        if !openAIModels.isEmpty {
                            Picker("Select Model", selection: $selectedOpenAIModel) {
                                ForEach(openAIModels, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        if let error = fetchModelsError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .onChange(of: openaiApiKey) { newValue in
                        guard !newValue.isEmpty else { return }
                        Task {
                            isFetchingModels = true
                            fetchModelsError = nil
                            do {
                                let models = try await aiService.fetchOpenAIModels()
                                self.openAIModels = models.filter { $0.contains("gpt") }.sorted()
                                if !openAIModels.isEmpty, !openAIModels.contains(selectedOpenAIModel) {
                                    selectedOpenAIModel = openAIModels.first!
                                }
                            } catch {
                                fetchModelsError = error.localizedDescription
                            }
                            isFetchingModels = false
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OpenRouter")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("API Key", text: $openrouterApiKey)
                    }
                }
                
                Section(header: Text("Prompt Settings")) {
                    ForEach(promptSettings, id: \.title) { setting in
                        NavigationLink(destination: PromptEditView(title: setting.title, prompt: setting.binding)) {
                            VStack(alignment: .leading) {
                                Text(setting.title)
                                Text(setting.binding.wrappedValue)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("Local AI")) {
                    Button("Local AI Settings...") {
                        showingLocalAISettings = true
                    }
                }
                
                Section(header: Text("On-Device AI")) {
                    Text("On-device inference using a local Core ML model. This feature is a placeholder and is not yet implemented.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("AI Provider Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showingLocalAISettings) {
                LocalAISettingsModalView()
            }
        }
    }
}

private struct LocalAISettingsModalView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("localAIBaseURL") private var localAIBaseURL = "http://localhost:1234/v1"
    @AppStorage("localAIModelName") private var localAIModelName = ""
    @AppStorage("localAIAPIKey") private var localAIAPIKey = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Local AI Settings")) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Base URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., http://localhost:1234/v1", text: $localAIBaseURL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Model Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., llama3:instruct", text: $localAIModelName)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Optional", text: $localAIAPIKey)
                    }
                    Text("For OpenAI-compatible local servers like LM Studio or Ollama.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Local AI Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

private struct PromptEditView: View {
    var title: String
    @Binding var prompt: String

    var body: some View {
        VStack {
            TextEditor(text: $prompt)
                .padding()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}