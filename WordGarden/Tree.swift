
import Foundation

struct Tree: Identifiable, Codable {
    var id = UUID()
    var level: Int = 0
    var lastWatered: Date = Date()
}
