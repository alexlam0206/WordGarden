import Foundation
import UIKit // Import UIKit for UIImage
import CryptoKit

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

    private func sanitizedKey(for key: String) -> String {
        let data = Data(key.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func cache(data: Data, for key: String) {
        let url = cacheDirectory.appendingPathComponent(sanitizedKey(for: key))
        try? data.write(to: url)
    }

    func getCachedData(for key: String) -> Data? {
        let url = cacheDirectory.appendingPathComponent(sanitizedKey(for: key))
        return try? Data(contentsOf: url)
    }

    // New method to cache UIImage
    func cacheImage(image: UIImage, for key: String) {
        if let data = image.pngData() { // Use pngData for lossless compression
            cache(data: data, for: key)
        }
    }

    // New method to retrieve cached UIImage
    func getCachedImage(for key: String) -> UIImage? {
        if let data = getCachedData(for: key) {
            return UIImage(data: data)
        }
        return nil
    }

    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
}
