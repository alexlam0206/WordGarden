
import Foundation

// MARK: - Datamuse Data Model
struct SpellingSuggestion: Codable, Identifiable {
    let id = UUID()
    let word: String
    let score: Int

    enum CodingKeys: String, CodingKey {
        case word, score
    }
}

// MARK: - Datamuse API Service
class DatamuseService {
    private let baseURL = "https://api.datamuse.com/words"

    func fetchSpellingSuggestions(for word: String) async throws -> [SpellingSuggestion] {
        guard let url = URL(string: "\(baseURL)?sp=\(word)&max=20") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw APIError.apiError(statusCode)
        }

        do {
            let suggestions = try JSONDecoder().decode([SpellingSuggestion].self, from: data)
            return suggestions
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
