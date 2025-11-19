
import Foundation

struct Tree: Identifiable, Codable {
    var id = UUID()
    var level: Int = 0
    var xp: Int = 0 // New: XP out of 100
    var lastWatered: Date = Date()
}
