// All changes after that commit have been discarded, and the working directory is now at that state.

import Foundation

struct Tree: Identifiable, Codable {
    var id = UUID()
    var level: Int = 0
    var lastWatered: Date = Date()
}
