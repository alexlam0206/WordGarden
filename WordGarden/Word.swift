import Foundation

// Represents a single word in the user's garden.
struct Word: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String // The word itself
    var definition: String // This will store the fetched definition or a placeholder
    var manualDefinition: String? // Optional: for user-entered definitions
    var example: String
    var growthLevel: Int = 0 // Growth level of the plant (0-5)
}