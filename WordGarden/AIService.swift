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
    
    // Initializer is no longer failable, as on-device model doesn't require a key.
    // The availability of a service is handled by each specific call.
    init(geminiApiKey: String, openaiApiKey: String, openrouterApiKey: String, localAIAPIKey: String) {
        self.geminiApiKey = geminiApiKey
        self.openaiApiKey = openaiApiKey
        self.openrouterApiKey = openrouterApiKey
        self.localAIAPIKey = localAIAPIKey
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

    func simplifyDefinition(_ definition: String, provider: AIProvider = .openrouter) async throws -> String {
        let promptTemplate = UserDefaults.standard.string(forKey: "promptSimplify") ?? "Simplify this definition for a 13-year-old learner: {definition}"
        let prompt = promptTemplate.replacingOccurrences(of: "{definition}", with: definition)
        return try await generateResponse(prompt: prompt, provider: provider)
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

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(geminiApiKey)")!
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
        // This is a placeholder for on-device Core ML model inference.
        // To implement this, you would typically use a library like MLC LLM or directly use Core ML.
        
        // --- Example Steps ---
        
        // 1. Import CoreML and any other necessary frameworks at the top of the file.
        // import CoreML
        
        // 2. Load your compiled Core ML model (`.mlmodelc` file).
        //    You must add the model to your Xcode project first.
        /*
        guard let modelURL = Bundle.main.url(forResource: "YourModelName", withExtension: "mlmodelc") else {
            throw NSError(domain: "AIService", code: 6, userInfo: [NSLocalizedDescriptionKey: "On-device model not found."])
        }
        let mlModel = try MLModel(contentsOf: modelURL)
        */
        
        // 3. Prepare the input for the model.
        //    For LLMs, this involves tokenizing the prompt string into an input tensor.
        //    This step is complex and usually handled by a helper library or a custom tokenizer.
        /*
        let tokenizer = YourTokenizer()
        let inputTokens = tokenizer.encode(prompt)
        let inputTensor = // ... convert inputTokens to an MLMultiArray or other required input format
        */
        
        // 4. Run the prediction.
        /*
        let provider = MLArrayBatchProvider(dictionary: ["input_name": inputTensor])
        let prediction = try mlModel.prediction(from: provider)
        */
        
        // 5. Process the output.
        //    This involves de-tokenizing the output tensor back into a string.
        /*
        guard let outputTensor = prediction.featureValue(for: "output_name")?.multiArrayValue else {
            throw NSError(domain: "AIService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to get model output."])
        }
        let outputTokens = // ... convert outputTensor back to an array of token IDs
        let outputString = tokenizer.decode(outputTokens)
        */

        // For now, simulate work and return a placeholder message.
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate work (0.5 seconds)
        
        // return outputString
        return "On-device inference is not yet implemented. A Core ML model needs to be integrated."
    }
}