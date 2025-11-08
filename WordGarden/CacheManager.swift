
import Foundation

class CacheManager {
    static let shared = CacheManager()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Create a directory for caching
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = urls[0].appendingPathComponent("WordCache")
        try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    func cache(data: Data, for key: String) {
        let url = cacheDirectory.appendingPathComponent(key)
        try? data.write(to: url)
    }

    func getCachedData(for key: String) -> Data? {
        let url = cacheDirectory.appendingPathComponent(key)
        return try? Data(contentsOf: url)
    }

    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
}
