import SwiftUI

struct WordRowView: View {
    let word: Word

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.text)
                    .font(.headline)
                    .fontWeight(.bold)

                // Use manual definition if available, otherwise the fetched one.
                let displayDefinition = word.manualDefinition ?? word.definition
                if !displayDefinition.isEmpty && displayDefinition != "Couldn't find a definition." {
                    Text(displayDefinition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2) // Don't let it get too long
                }
            }

            Spacer()

            // Show a little growth indicator
            if word.growthLevel > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<word.growthLevel, id: \.self) { _ in
                        Text("🌱")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 8) // Add some vertical padding to each row
    }
}

// A preview to see how it looks
struct WordRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WordRowView(word: Word(text: "Ephemeral", definition: "Lasting for a very short time.", example: "", growthLevel: 1))
            WordRowView(word: Word(text: "Serendipity", definition: "The occurrence and development of events by chance in a happy or beneficial way.", manualDefinition: "Finding something good without looking for it.", example: "", growthLevel: 3))
            WordRowView(word: Word(text: "Nostalgia", definition: "", example: "", growthLevel: 0))
        }
        .padding()
    }
}
