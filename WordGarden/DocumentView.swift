// All changes after that commit have been discarded, and the working directory is now at that state.
import SwiftUI

struct DocumentView: View {
    var title: String
    var content: String

    var body: some View {
        ScrollView {
            Text(content)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
