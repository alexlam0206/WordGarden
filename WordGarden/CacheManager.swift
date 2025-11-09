// All changes after that commit have been discarded, and the working directory is now at that state.

import Foundation
import UIKit // Import UIKit for UIImage

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
