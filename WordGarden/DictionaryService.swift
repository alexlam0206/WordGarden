// All changes after that commit have been discarded, and the working directory is now at that state.

import Foundation

// MARK: - Welcome
struct WelcomeElement: Codable, Identifiable {
    let id = UUID()
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]
    let meanings: [Meaning]
    let license: License
    let sourceUrls: [String]

    enum CodingKeys: String, CodingKey {
        case word, phonetic, phonetics, meanings, license, sourceUrls
    }
}

// MARK: - License
struct License: Codable {
    let name: String
    let url: String
}

// MARK: - Meaning
struct Meaning: Codable, Identifiable {
    let id = UUID()
    let partOfSpeech: String
    let definitions: [Definition]
    let synonyms, antonyms: [String]

    enum CodingKeys: String, CodingKey {
        case partOfSpeech, definitions, synonyms, antonyms
    }
}

// MARK: - Definition
struct Definition: Codable, Identifiable {
    let id = UUID()
    let definition: String
    let synonyms, antonyms: [String]
    let example: String?

    enum CodingKeys: String, CodingKey {
        case definition, synonyms, antonyms, example
    }
}

// MARK: - Phonetic
struct Phonetic: Codable, Identifiable {
    let id = UUID()
    let text: String?
    let audio: String
    let sourceURL: String?
    let license: License?

    enum CodingKeys: String, CodingKey {
        case text, audio
        case sourceURL = "sourceUrl"
        case license
    }
}

typealias Welcome = [WelcomeElement]

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case apiError(Int)
    case noData
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL was invalid."
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .apiError(let statusCode):
            if statusCode == 404 {
                return "Word not found. Check the spelling and try again."
            }
            return "An API error occurred with status code: \(statusCode)"
        case .noData:
            return "No data was received from the server."
        case .decodingError:
            return "There was an error decoding the data."
        }
    }
}

class DictionaryService {
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"

    func fetchWord(_ word: String) async throws -> Welcome {
        let cacheKey = word.lowercased()
        
        // Check cache first
        if let cachedData = CacheManager.shared.getCachedData(for: cacheKey) {
            do {
                let decodedResponse = try JSONDecoder().decode(Welcome.self, from: cachedData)
                return decodedResponse
            } catch {
                // If decoding fails, proceed to fetch from API
                print("Failed to decode cached data: \(error)")
            }
        }

        guard let url = URL(string: baseURL + word.lowercased()) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw APIError.apiError(statusCode)
        }

        // Cache the new data
        CacheManager.shared.cache(data: data, for: cacheKey)

        do {
            let decodedResponse = try JSONDecoder().decode(Welcome.self, from: data)
            return decodedResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
