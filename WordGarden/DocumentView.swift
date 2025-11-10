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