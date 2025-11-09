// All changes after that commit have been discarded, and the working directory is now at that state.

import SwiftUI

struct TreeView: View {
    @EnvironmentObject var treeService: TreeService
    @EnvironmentObject var wordStorage: WordStorage

    var body: some View {
        VStack {
            Text("My Tree")
                .font(.largeTitle)
                .padding()

            Text(treeImage(for: treeService.tree.level, maxLevel: treeService.maxTreeLevel))
                .font(.system(size: 200))
                .padding()

            Text("Level \(treeService.tree.level) / \(treeService.maxTreeLevel)")
                .font(.title)
                .padding(.bottom, 5)

            ProgressView(value: treeService.wateringProgress) {
                Text("Watering Progress")
            } currentValueLabel: {
                Text("\(Int(treeService.wateringProgress * 100))%")
            }
            .padding()

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
                    .font(.title)
                    .padding()
                    .background(treeService.canWaterTree() || treeService.tree.level == treeService.maxTreeLevel ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!treeService.canWaterTree() && treeService.tree.level < treeService.maxTreeLevel)
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
