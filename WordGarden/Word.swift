
import Foundation

// Represents a single word in the user's garden.
struct Word: Identifiable, Codable {
    var id = UUID()
    var text: String // The word itself
    var definition: String // This will store the fetched definition or a placeholder
    var manualDefinition: String? // Optional: for user-entered definitions
    var example: String
    var growthLevel: Int = 0 // Represents the growth of the plant
    var lastWatered: Date = Date()

    // "Watering" the plant increases its growth level.
    mutating func water() {
        if growthLevel < 5 {
            growthLevel += 1
        }
    }
}
