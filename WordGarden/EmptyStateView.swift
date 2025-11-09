import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Your Garden is Empty")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Tap the '+' button below to plant your first word and watch your garden grow!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView()
    }
}
