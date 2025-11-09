// All changes after that commit have been discarded, and the working directory is now at that state.


import Foundation
import Combine

class TreeService: ObservableObject {
    @Published var tree: Tree
    @Published var wateringLogs: [WateringLog]
    @Published var treesGrown: Int = 0 // New: Tracks the number of fully grown trees

    private let treeKey = "tree"
    private let wateringLogsKey = "wateringLogs"
    private let treesGrownKey = "treesGrown"

    let maxWateringsPerLevel = 5 // How many waterings to level up the tree
    let maxTreeLevel = 20 // The maximum level a tree can reach before being 'fully grown'

    init() {
        self.tree = Tree()
        self.wateringLogs = []
        load()
    }

    var wateringProgress: Float {
        // Calculate progress towards the next level
        let currentWateringsInLevel = wateringLogs.count % maxWateringsPerLevel
        return Float(currentWateringsInLevel) / Float(maxWateringsPerLevel)
    }

    func waterTree() {
        guard tree.level < maxTreeLevel else { return } // Cannot water a fully grown tree

        wateringLogs.append(WateringLog())

        if wateringLogs.count % maxWateringsPerLevel == 0 {
            tree.level += 1
        }

        tree.lastWatered = Date()
        save()
    }

    func plantNewTree() {
        guard tree.level >= maxTreeLevel else { return } // Only plant new tree if current is fully grown

        treesGrown += 1
        tree = Tree() // Reset tree to a new one
        wateringLogs = [] // Clear watering logs for the new tree
        save()
    }

    func canWaterTree() -> Bool {
        guard tree.level < maxTreeLevel else { return false } // Cannot water a fully grown tree

        // Allow watering once per day
        if let lastWatered = wateringLogs.last?.date {
            return !Calendar.current.isDateInToday(lastWatered)
        }
        return true
    }

    private func save() {
        let localDefaults = UserDefaults.standard
        if let encodedTree = try? JSONEncoder().encode(tree) {
            localDefaults.set(encodedTree, forKey: treeKey)
        }
        if let encodedLogs = try? JSONEncoder().encode(wateringLogs) {
            localDefaults.set(encodedLogs, forKey: wateringLogsKey)
        }
        localDefaults.set(treesGrown, forKey: treesGrownKey)
    }

    private func load() {
        let localDefaults = UserDefaults.standard
        if let treeData = localDefaults.data(forKey: treeKey),
            let decodedTree = try? JSONDecoder().decode(Tree.self, from: treeData) {
            self.tree = decodedTree
        }

        if let logsData = localDefaults.data(forKey: wateringLogsKey),
            let decodedLogs = try? JSONDecoder().decode([WateringLog].self, from: logsData) {
            self.wateringLogs = decodedLogs
        }

        self.treesGrown = localDefaults.integer(forKey: treesGrownKey)
    }


}

