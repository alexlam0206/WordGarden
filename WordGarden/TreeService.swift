
import Foundation
import Combine

enum TreeGrowthPhase: String, CaseIterable {
    case seed = "Seed"
    case sprout = "Sprout"
    case sapling = "Sapling"
    case youngTree = "Young Tree"
    case matureTree = "Mature Tree"
    
    var imageName: String {
        switch self {
        case .seed: return "tree_seed"
        case .sprout: return "tree_sprout"
        case .sapling: return "tree_sapling"
        case .youngTree: return "tree_young"
        case .matureTree: return "tree_mature"
        }
    }
}

class TreeService: ObservableObject {
    @Published var tree: Tree
    @Published var wateringLogs: [WateringLog]
    @Published var treesGrown: Int = 0 // New: Tracks the number of fully grown trees

    private let treeKey = "tree"
    private let wateringLogsKey = "wateringLogs"
    private let treesGrownKey = "treesGrown"

    // New XP system constants
    let maxXP = 100 // Maximum XP per tree
    let maxTreeLevel = 5 // Simplified: only 5 levels (0-4)
    let xpPerAction = 10 // XP gained per study action or watering

    init() {
        self.tree = Tree()
        self.wateringLogs = []
        load()
    }

    var xpProgress: Float {
        // Calculate XP progress (0.0 to 1.0)
        return Float(tree.xp) / Float(maxXP)
    }
    
    var currentPhase: TreeGrowthPhase {
        // Define growth phases based on XP
        let xp = tree.xp
        switch xp {
        case 0..<20: return .seed
        case 20..<40: return .sprout
        case 40..<60: return .sapling
        case 60..<80: return .youngTree
        case 80..<100: return .matureTree
        default: return .seed
        }
    }
    
    var isTreeFullyGrown: Bool {
        return tree.xp >= maxXP
    }

    func waterTree() {
        guard !isTreeFullyGrown else { return } // Cannot water a fully grown tree
        
        // Add XP for watering
        tree.xp = min(tree.xp + xpPerAction, maxXP)
        wateringLogs.append(WateringLog())
        
        // Update level based on XP
        updateLevelFromXP()
        
        tree.lastWatered = Date()
        save()
    }

    func awardStudyProgress() {
        guard !isTreeFullyGrown else { return }
        
        // Add XP for study progress
        tree.xp = min(tree.xp + xpPerAction, maxXP)
        wateringLogs.append(WateringLog())
        
        // Update level based on XP
        updateLevelFromXP()
        
        tree.lastWatered = Date()
        save()
    }

    func plantNewTree() {
        guard isTreeFullyGrown else { return } // Only plant new tree if current is fully grown

        treesGrown += 1
        tree = Tree() // Reset tree to a new one
        wateringLogs = [] // Clear watering logs for the new tree
        save()
    }
    
    private func updateLevelFromXP() {
        // Update level based on XP thresholds
        let xp = tree.xp
        if xp >= 80 {
            tree.level = 4 // Mature Tree
        } else if xp >= 60 {
            tree.level = 3 // Young Tree
        } else if xp >= 40 {
            tree.level = 2 // Sapling
        } else if xp >= 20 {
            tree.level = 1 // Sprout
        } else {
            tree.level = 0 // Seed
        }
    }

    func canWaterTree() -> Bool {
        guard !isTreeFullyGrown else { return false } // Cannot water a fully grown tree

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

        // Also save to shared UserDefaults for widgets
        updateSharedDefaults()
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

    // Updates shared UserDefaults for widgets
    private func updateSharedDefaults() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.nok.WordGarden")
        sharedDefaults?.set(tree.level, forKey: "treeLevel")
        sharedDefaults?.set(tree.xp, forKey: "treeXP")
        sharedDefaults?.set(treesGrown, forKey: "treesGrown")
        sharedDefaults?.set(currentPhase.rawValue, forKey: "treePhase")
        // Calculate next watering time (24 hours from last watering)
        if let lastWatering = wateringLogs.last?.date {
            let nextWatering = lastWatering.addingTimeInterval(24 * 3600)
            sharedDefaults?.set(nextWatering.timeIntervalSince1970, forKey: "nextWatering")
        }
    }


}
