// All changes after that commit have been discarded, and the working directory is now at that state.

import Foundation

struct WateringLog: Identifiable, Codable {
    var id = UUID()
    var date: Date = Date()
}
