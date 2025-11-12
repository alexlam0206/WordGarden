import CoreML
import Foundation

// For parsing OpenAI models list
struct OpenAIModelsResponse: Codable {
    let data: [OpenAIModel]
}

struct OpenAIModel: Codable, Identifiable {
    let id: String
}


enum AIProvider {
    case gemini
    case openai
    case openrouter
    case localAI
    case onDevice
}

class AIService {
    private let geminiApiKey: String
    private let openaiApiKey: String
    private let openrouterApiKey: String
    private let localAIAPIKey: String
    
    // On-device model
    private var onDeviceModel: MLModel?
    
    // Initializer is no longer failable, as on-device model doesn't require a key.
    // The availability of a service is handled by each specific call.
    init(geminiApiKey: String, openaiApiKey: String, openrouterApiKey: String, localAIAPIKey: String) {
        self.geminiApiKey = geminiApiKey
        self.openaiApiKey = openaiApiKey
        self.openrouterApiKey = openrouterApiKey
        self.localAIAPIKey = localAIAPIKey
        
        // Load the on-device model
        loadOnDeviceModel()
    }

    private func loadOnDeviceModel() {
        // Note: The model name should match the name of the .mlpackage file you add to the project.
        // You will need to convert a model (e.g., distilgpt2) to Core ML format first.
        guard let modelURL = Bundle.main.url(forResource: "distilgpt2", withExtension: "mlpackage") else {
            print("On-device model not found.")
            return
        }
        do {
            let config = MLModelConfiguration()
            onDeviceModel = try MLModel(contentsOf: modelURL, configuration: config)
        } catch {
            print("Failed to load on-device model: \(error)")
        }
    }

    func generateExplanation(for word: String, provider: AIProvider) async throws -> String {
        let promptTemplate = UserDefaults.standard.string(forKey: "promptExplanation") ?? "Explain the word '{word}' in a fun and simple way for a 13-year-old learner."
        let prompt = promptTemplate.replacingOccurrences(of: "{word}", with: word)
        return try await generateResponse(prompt: prompt, provider: provider)
    }

    func generateExampleSentence(for word: String, provider: AIProvider) async throws -> String {
        let promptTemplate = UserDefaults.standard.string(forKey: "promptExample") ?? "Create a simple example sentence using the word '{word}'."
        let prompt = promptTemplate.replacingOccurrences(of: "{word}", with: word)
        return try await generateResponse(prompt: prompt, provider: provider)
    }
    
    func identifyImage(imageData: Data) async throws -> String {
        guard !geminiApiKey.isEmpty else {
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Gemini API key not set."])
        }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=\(geminiApiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Image = imageData.base64EncodedString()
        let prompt = "Identify the main object in this image. Respond with only a single noun, in lowercase."

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("Gemini Vision API failed with status code: \(statusCode). Body: \(responseBody)")
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(statusCode)"])
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            // Clean up the response to get a single word
            return text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines).first ?? "unknown"
        } else {
            throw NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])
        }
    }


    private func generateResponse(prompt: String, provider: AIProvider) async throws -> String {
        switch provider {
        case .gemini:
            return try await callGeminiAPI(prompt: prompt)
        case .openai:
            return try await callOpenAIAPI(prompt: prompt)
        case .openrouter:
            return try await callOpenRouterAPI(prompt: prompt)
        case .localAI:
            return try await callLocalAIAPI(prompt: prompt)
        case .onDevice:
            return try await callOnDeviceAPI(prompt: prompt)
        }
    }

    func fetchOpenAIModels() async throws -> [String] {
        guard !openaiApiKey.isEmpty else {
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not set"])
        }

        let url = URL(string: "https://api.openai.com/v1/models")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(openaiApiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch models with status \(statusCode)"])
        }

        let decodedResponse = try JSONDecoder().decode(OpenAIModelsResponse.self, from: data)
        return decodedResponse.data.map { $0.id }
    }

    private func callGeminiAPI(prompt: String) async throws -> String {
        guard !geminiApiKey.isEmpty else { throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Gemini API key not set"]) }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(geminiApiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("URLSession failed with error: \(error)")
            throw NSError(domain: "AIService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Network error. Please check your internet connection and try again."])
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("Gemini API failed with status code: \(statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(statusCode)"])
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let text = firstPart["text"] as? String {
            return text
        } else {
            throw NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])
        }
    }

    private func callOpenAIAPI(prompt: String) async throws -> String {
        guard !openaiApiKey.isEmpty else { throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not set"]) }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openaiApiKey)", forHTTPHeaderField: "Authorization")

        let selectedModel = UserDefaults.standard.string(forKey: "selectedOpenAIModel") ?? "gpt-3.5-turbo"

        let body: [String: Any] = [
            "model": selectedModel,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 150
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NSError(domain: "AIService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Network error. Please check your internet connection and try again."])
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(statusCode)"])
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
            throw NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])
        }
    }

    private func callOpenRouterAPI(prompt: String) async throws -> String {
        guard !openrouterApiKey.isEmpty else { throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenRouter API key not set"]) }

        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openrouterApiKey)", forHTTPHeaderField: "Authorization")
        
        let systemPrompt = UserDefaults.standard.string(forKey: "promptSystemOpenRouter") ?? "You are a helpful assistant. Only provide the direct answer to the user's request without any conversational filler."

        let body: [String: Any] = [
            "model": "minimax/minimax-m2:free",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 150,
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NSError(domain: "AIService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Network error. Please check your internet connection and try again."])
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("OpenRouter API failed with status code: \(statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(statusCode)"])
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
            throw NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response"])
        }
    }
    
    private func callLocalAIAPI(prompt: String) async throws -> String {
        let baseURL = UserDefaults.standard.string(forKey: "localAIBaseURL") ?? "http://localhost:1234/v1"
        let modelName = UserDefaults.standard.string(forKey: "localAIModelName")
        let apiKey = UserDefaults.standard.string(forKey: "localAIAPIKey") ?? ""

        guard let model = modelName, !model.isEmpty else {
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Local AI model name not set"])
        }
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw NSError(domain: "AIService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid Local AI Base URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 150
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Local AI request failed with status \(statusCode)"])
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        } else {
            throw NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Local AI API response"])
        }
    }

    private func callOnDeviceAPI(prompt: String) async throws -> String {
        guard let model = onDeviceModel else {
            throw NSError(domain: "AIService", code: 6, userInfo: [NSLocalizedDescriptionKey: "On-device model is not loaded."])
        }

        // --- Placeholder for Tokenization and Inference ---
        // The following is a simplified representation. A real implementation
        // would require a proper tokenizer that matches the model (e.g., GPT-2 tokenizer).
        // You might use a library like Hugging Face's `swift-transformers` for this.

        // 1. Tokenize the prompt (placeholder)
        // In a real scenario, you would use a tokenizer to convert the prompt string to input IDs.
        // let tokenizer = GPT2Tokenizer()
        // let inputIDs = tokenizer.encode(prompt)
        
        // For this placeholder, we'll just return a message.
        // A real implementation would proceed to create an MLMultiArray from inputIDs,
        // run the prediction, and decode the output.

        let outputString = "On-device inference with '\(prompt)' - tokenization and full inference pipeline not yet implemented."
        
        // Simulate async work
        try await Task.sleep(nanoseconds: 100_000_000)

        return outputString
    }
}