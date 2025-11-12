
import SwiftUI

struct TreeView: View {
    @EnvironmentObject var treeService: TreeService
    @EnvironmentObject var wordStorage: WordStorage

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Text("My Tree")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                HStack {
                    Text("XP: \(Int(treeService.wateringProgress * 100))%")
                        .font(.headline)
                    ProgressView(value: treeService.wateringProgress)
                        .frame(width: 100)
                }
            }
            .padding()

            // Main Tree Area (Scrollable)
            ScrollView {
                VStack {
                    Spacer()
                    Text(treeImage(for: treeService.tree.level, maxLevel: treeService.maxTreeLevel))
                        .font(.system(size: 250))
                        .padding()
                    Spacer()
                }
                .frame(minHeight: 400)
            }

            // Bottom Toolbar / Stats Panel
            VStack(spacing: 10) {
                HStack {
                    VStack {
                        Text("Words Learned")
                            .font(.caption)
                        Text("\(wordStorage.words.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack {
                        Text("Daily Streak")
                            .font(.caption)
                        Text("7") // Placeholder, need to implement streak
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack {
                        Text("Level / XP")
                            .font(.caption)
                        Text("\(treeService.tree.level) / \(Int(treeService.wateringProgress * 100))")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    if treeService.tree.level == treeService.maxTreeLevel {
                        wordStorage.addLogEntry("Planted new tree")
                        treeService.plantNewTree()
                    } else {
                        wordStorage.addLogEntry("Watered tree")
                        treeService.waterTree()
                    }
                }) {
                    Text(treeService.tree.level == treeService.maxTreeLevel ? "Plant New Tree" : "Water Tree")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(treeService.canWaterTree() || treeService.tree.level == treeService.maxTreeLevel ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!treeService.canWaterTree() && treeService.tree.level < treeService.maxTreeLevel)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
        }
        .onAppear {
            wordStorage.addLogEntry("Opened Tree tab")
        }
    }

    private func treeImage(for level: Int, maxLevel: Int) -> String {
        let progress = Double(level) / Double(maxLevel)
        switch progress {
        case 0..<0.2: return "🌱"
        case 0.2..<0.5: return "🌿"
        case 0.5..<0.8: return "🌳"
        case 0.8..<1.0: return "🌳🌳"
        case 1.0: return "🌳🌳🌳"
        default: return "🌱"
        }
    }
}

struct TreeView_Previews: PreviewProvider {
    static var previews: some View {
        TreeView()
            .environmentObject(TreeService())
    }
}
