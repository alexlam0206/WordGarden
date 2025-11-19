import SwiftUI
import AVFoundation

struct WordDetailView: View {
    @Binding var word: Word // Now a @Binding variable
    @EnvironmentObject var wordStorage: WordStorage
    @EnvironmentObject var treeService: TreeService
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingAlert = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                ProgressView("Fetching definition...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let manualDef = word.manualDefinition, !manualDef.isEmpty {
                // Display manual definition if available
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(word.text.capitalized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: {
                                SpeechService.shared.speak(text: word.text)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                            }
                        }
                        Text("Manual Definition:")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top)
                        Text(manualDef)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(word.text.capitalized)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: {
                                SpeechService.shared.speak(text: word.text)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title2)
                            }
                        }
                        if !word.definition.isEmpty {
                            Text(word.definition)
                        } else {
                            Text("No definition yet. Add your own in Learn tab.")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

        }
        .padding()
        .navigationTitle("Definition")
        .task {
            wordStorage.reviewWord(wordID: word.id)
            treeService.awardStudyProgress()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "An unknown error occurred."), dismissButton: .default(Text("OK")))
        }
    }
}

struct WordDetailView_Previews: PreviewProvider {
    struct Wrapper: View {
        @State var word = Word(text: "ephemeral", definition: "Lasting for a very short time.", example: "An ephemeral joy.")
        var body: some View {
            NavigationView {
                WordDetailView(word: $word)
                    .environmentObject(WordStorage())
            }
        }
    }
    static var previews: some View {
        Wrapper()
            .preferredColorScheme(.light)
    }
}

// AI features removed for offline, non-AI experience.
