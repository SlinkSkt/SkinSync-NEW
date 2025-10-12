import Foundation

// MARK: - OpenAI Service
@MainActor
class OpenAIService: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let plistKey = "OpenAI_API_Key"
    
    private var apiKey: String? {
        return getAPIKeyFromPlist()
    }
    
    // MARK: - API Key Management
    func hasAPIKey() -> Bool {
        return apiKey != nil
    }
    
    // MARK: - Info.plist Configuration
    private func getAPIKeyFromPlist() -> String? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist[plistKey] as? String,
              !apiKey.isEmpty else {
            return nil
        }
        return apiKey
    }
    
    // MARK: - OpenAI API
    func sendMessage(_ message: String, conversationHistory: [ChatMessage] = []) async throws -> String {
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }
        
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
        }
        
        // Build conversation messages
        var messages: [[String: String]] = [
            [
                "role": "system",
                "content": """
                You are SyncAI, an expert skincare assistant. You help users with:
                - Skincare routine recommendations
                - Product ingredient analysis
                - Skin concern advice
                - Personalized skincare tips
                - Answering skincare questions
                
                Always provide helpful, accurate, and personalized advice. Keep responses concise but informative.
                """
            ]
        ]
        
        // Add conversation history
        for chatMessage in conversationHistory {
            messages.append([
                "role": chatMessage.role.rawValue,
                "content": chatMessage.content
            ])
        }
        
        // Add current message
        messages.append([
            "role": "user",
            "content": message
        ])
        
        // Create request
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.encodingError
        }
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// MARK: - OpenAI Errors
enum OpenAIError: LocalizedError {
    case noAPIKey
    case invalidURL
    case encodingError
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured. Please add your API key in settings."
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "OpenAI API error: \(message)"
        }
    }
}

