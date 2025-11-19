
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
                    Text("XP: \(treeService.tree.xp)/100")
                        .font(.headline)
                    ProgressView(value: treeService.xpProgress)
                        .frame(width: 100)
                }
            }
            .padding()

            // Main Tree Area (Scrollable)
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Tree Image or Custom Image
                    if treeService.isTreeFullyGrown {
                        // Show custom image placeholder for fully grown tree
                        Image(systemName: "tree")
                            .font(.system(size: 200))
                            .foregroundColor(.green)
                    } else {
                        // Show emoji based on growth phase
                        Text(treeEmoji(for: treeService.currentPhase))
                            .font(.system(size: 200))
                    }
                    
                    // Growth Phase Text
                    Text(treeService.currentPhase.rawValue)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
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
                    Spacer()
                    VStack {
                        Text("Level")
                            .font(.caption)
                        Text("\(treeService.tree.level + 1)/5") // Show 1-5 instead of 0-4
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)
                
                // Grow New Tree Button (only shows when fully grown)
                if treeService.isTreeFullyGrown {
                    Button(action: {
                        treeService.plantNewTree()
                    }) {
                        HStack {
                            Image(systemName: "leaf.arrow.circlepath")
                            Text("Grow New Tree")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
        }
        .onAppear {
            wordStorage.addLogEntry("Opened Tree tab")
        }
    }

    private func treeEmoji(for phase: TreeGrowthPhase) -> String {
        switch phase {
        case .seed: return "🌰"
        case .sprout: return "🌱"
        case .sapling: return "🌿"
        case .youngTree: return "🌳"
        case .matureTree: return "🌲"
        }
    }
}

struct TreeView_Previews: PreviewProvider {
    static var previews: some View {
        TreeView()
            .environmentObject(TreeService())
            .environmentObject(WordStorage())
            .preferredColorScheme(.light)
    }
}
