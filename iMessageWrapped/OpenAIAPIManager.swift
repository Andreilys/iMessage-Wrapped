import Foundation
import Security
import AppKit

// MARK: - OpenAI API Manager

/// Manages OpenAI API authentication and requests.
/// Supports GPT-4o, GPT-4o-mini, and GPT-4 Turbo models.
@MainActor
class OpenAIAPIManager: ObservableObject {
    @Published var isConfigured = false
    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var accountInfo: OpenAIAccountInfo?
    
    private let keychainKey = "com.imessagewrapped.openai-api-key"
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let platformURL = URL(string: "https://platform.openai.com")!
    private let apiKeysURL = URL(string: "https://platform.openai.com/api-keys")!
    
    // Context windows vary by model - see OpenAIModel enum
    static let defaultContextWindow = 128_000 // tokens (GPT-4o default)
    static let maxContextWindow = 1_000_000 // tokens (GPT-4.1 series)
    
    init() {
        isConfigured = getAPIKey() != nil
        if isConfigured {
            Task {
                await fetchAccountInfo()
            }
        }
    }
    
    // MARK: - Quick Setup Flow
    
    /// Opens OpenAI Platform for the user to get/create an API key
    func openOpenAIPlatform() {
        NSWorkspace.shared.open(platformURL)
    }
    
    /// Opens directly to the API keys page
    func openAPIKeysPage() {
        NSWorkspace.shared.open(apiKeysURL)
    }
    
    /// Validates and saves an API key, fetching account info on success
    func setupWithKey(_ key: String) async -> SetupResult {
        guard key.hasPrefix("sk-") else {
            return .failure("Invalid key format. OpenAI API keys start with 'sk-'")
        }
        
        // Test the key
        do {
            let isValid = try await validateAPIKey(key)
            if isValid {
                if saveAPIKey(key) {
                    await fetchAccountInfo()
                    return .success
                } else {
                    return .failure("Failed to save key to Keychain")
                }
            } else {
                return .failure("API key is invalid or expired")
            }
        } catch {
            return .failure(error.localizedDescription)
        }
    }
    
    enum SetupResult {
        case success
        case failure(String)
    }
    
    // MARK: - Account Info
    
    func fetchAccountInfo() async {
        guard let apiKey = getAPIKey() else { return }
        
        // Test with a minimal request
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "."]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                accountInfo = OpenAIAccountInfo(
                    isValid: httpResponse.statusCode == 200,
                    keyPrefix: String(apiKey.prefix(8)) + "..."
                )
            }
        } catch {
            accountInfo = nil
        }
    }
    
    private func validateAPIKey(_ key: String) async throws -> Bool {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "test"]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        return false
    }
    
    // MARK: - API Key Management (Keychain)
    
    func saveAPIKey(_ key: String) -> Bool {
        let data = key.data(using: .utf8)!
        
        // Delete existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new key
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        isConfigured = status == errSecSuccess
        return isConfigured
    }
    
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(query as CFDictionary)
        isConfigured = false
        accountInfo = nil
    }
    
    // MARK: - OpenAI API Calls
    
    func analyze(
        messages: [Message],
        analytics: MessageAnalytics,
        model: OpenAIModel = .gpt4o
    ) async throws -> OpenAIAnalysisResult {
        guard let apiKey = getAPIKey() else {
            throw OpenAIAPIError.noAPIKey
        }
        
        isProcessing = true
        lastError = nil
        defer { isProcessing = false }
        
        // Format messages for OpenAI - use model's specific context capacity
        let maxMessages = min(messages.count, model.estimatedMessagesCapacity)
        let sampled = messages.count > maxMessages
            ? messages.sampledForAI(maxCount: maxMessages)
            : messages
        
        let formattedMessages = formatMessagesForAnalysis(sampled)
        let statsContext = formatStatsContext(analytics)
        
        let systemPrompt = """
        You are an expert at analyzing communication patterns with warmth and insight.
        You're creating a "Spotify Wrapped" style year-in-review for someone's iMessage history.
        
        Be specific to the data provided. Be warm, insightful, and occasionally witty.
        Focus on positive patterns while being honest about communication styles.
        
        Your analysis should feel personal and meaningful, not generic.
        """
        
        let userPrompt = """
        Analyze these iMessage conversations and create a personalized "iMessage AI" experience.
        
        ## Statistics Overview
        \(statsContext)
        
        ## Message History (\(sampled.count) messages)
        \(formattedMessages)
        
        ---
        
        Please provide a comprehensive analysis in the following JSON format:
        {
            "narrative": {
                "openingHook": "A catchy, personalized opening line about their messaging year",
                "keyMoments": ["3-5 specific observations from the messages"],
                "relationshipHighlights": "Insights about their key relationships",
                "closingReflection": "A warm, thoughtful closing about their communication style"
            },
            "themes": ["Main conversation themes discovered"],
            "emotionalTone": "Overall emotional tone of their messaging",
            "funFacts": ["3-5 quirky or interesting observations"],
            "personalityInsights": {
                "type": "Their messaging personality type with emoji",
                "description": "Why this fits them",
                "strengths": ["Communication strengths"],
                "style": "Their unique communication style"
            },
            "yearInEmojis": "A sequence of 5-10 emojis that represent their year"
        }
        """
        
        let requestBody: [String: Any] = [
            "model": model.rawValue,
            "max_tokens": 4096,
            "temperature": 0.7,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ]
        ]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 120
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIAPIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw OpenAIAPIError.invalidAPIKey
        }
        
        if httpResponse.statusCode == 429 {
            throw OpenAIAPIError.rateLimited
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIAPIError.apiError(message)
            }
            throw OpenAIAPIError.requestFailed(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIAPIError.invalidResponse
        }
        
        // Parse JSON content
        guard let jsonData = content.data(using: .utf8),
              let analysis = try? JSONDecoder().decode(OpenAIAnalysisResult.self, from: jsonData) else {
            // If parsing fails, return raw text
            return OpenAIAnalysisResult(
                narrative: OpenAINarrative(
                    openingHook: "Your messaging year was unique!",
                    keyMoments: [content],
                    relationshipHighlights: "",
                    closingReflection: ""
                ),
                themes: [],
                emotionalTone: "",
                funFacts: [],
                personalityInsights: nil,
                yearInEmojis: "💬"
            )
        }
        
        return analysis
    }
    
    // MARK: - Streaming Analysis
    
    func analyzeStreaming(
        messages: [Message],
        analytics: MessageAnalytics,
        model: OpenAIModel = .gpt4o,
        onPartial: @escaping (String) -> Void
    ) async throws -> String {
        guard let apiKey = getAPIKey() else {
            throw OpenAIAPIError.noAPIKey
        }
        
        isProcessing = true
        lastError = nil
        defer { isProcessing = false }
        
        // Use model's specific context capacity
        let maxMessages = min(messages.count, model.estimatedMessagesCapacity)
        let sampled = messages.count > maxMessages
            ? messages.sampledForAI(maxCount: maxMessages)
            : messages
        
        let formattedMessages = formatMessagesForAnalysis(sampled)
        let statsContext = formatStatsContext(analytics)
        
        let prompt = """
        Create a fun, engaging "iMessage AI" narrative for this person based on their message history.
        Write it like Spotify Wrapped - punchy, personal, and memorable.
        
        Stats:
        \(statsContext)
        
        Sample messages (\(sampled.count) of \(messages.count)):
        \(formattedMessages)
        
        Write the narrative directly, no JSON. Include:
        1. A catchy opening hook
        2. Their top contacts and what makes those relationships special
        3. Interesting patterns you noticed
        4. Fun facts and quirky observations
        5. Their "messaging personality" type
        6. A warm closing reflection
        """
        
        let requestBody: [String: Any] = [
            "model": model.rawValue,
            "max_tokens": 2048,
            "stream": true,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        var fullResponse = ""
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OpenAIAPIError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" { break }
                
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    fullResponse += content
                    onPartial(fullResponse)
                }
            }
        }
        
        return fullResponse
    }
    
    // MARK: - Helpers
    
    private func formatMessagesForAnalysis(_ messages: [Message]) -> String {
        messages
            .sorted { $0.date < $1.date }
            .compactMap { msg -> String? in
                guard let text = msg.text, !text.isEmpty else { return nil }
                let direction = msg.isFromMe ? "→" : "←"
                let contact = msg.displayName
                let date = msg.date.formatted(.dateTime.month(.abbreviated).day())
                let truncated = String(text.prefix(200))
                return "[\(date)] \(direction) \(contact): \(truncated)"
            }
            .joined(separator: "\n")
    }
    
    private func formatStatsContext(_ analytics: MessageAnalytics) -> String {
        let topContacts = analytics.topContacts
            .prefix(5)
            .map { "\($0.displayName): \($0.totalMessages) messages (\($0.messagesSent) sent, \($0.messagesReceived) received)" }
            .joined(separator: "\n")
        
        let topEmojis = analytics.topEmojis
            .prefix(10)
            .map { "\($0.emoji): \($0.count) times" }
            .joined(separator: ", ")
        
        return """
        Time period: \(analytics.timePeriodDays) days
        Total messages: \(analytics.totalMessages)
        Sent: \(analytics.messagesSent), Received: \(analytics.messagesReceived)
        Messages per day: \(Int(analytics.messagesPerDay))
        
        Top contacts:
        \(topContacts)
        
        Top emojis: \(topEmojis)
        
        Busiest hour: \(analytics.busiestHour.map { formatHour($0) } ?? "Unknown")
        Late night messages (10pm-2am): \(analytics.lateNightMessages)
        Early morning messages (5am-8am): \(analytics.earlyMorningMessages)
        Weekend messages: \(analytics.weekendMessages)
        Weekday messages: \(analytics.weekdayMessages)
        
        Average message length: \(Int(analytics.averageMessageLength)) characters
        Total characters typed: \(analytics.totalCharacters)
        Attachments shared: \(analytics.attachmentCount)
        
        Computed personality type: \(analytics.personalityType)
        """
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(from: DateComponents(hour: hour))!
        return formatter.string(from: date)
    }
}

// MARK: - Models

enum OpenAIModel: String, CaseIterable {
    // GPT-5.2 series (December 2025 - Latest)
    case gpt4o = "gpt-4o"
    case gpt52 = "gpt-5.2"
    case gpt52Pro = "gpt-5.2-pro"
    // GPT-5 series (August 2025)
    case gpt5 = "gpt-5"
    case gpt5Mini = "gpt-5-mini"
    case gpt5Nano = "gpt-5-nano"
    
    var displayName: String {
        switch self {
        case .gpt4o: return "GPT-4o"
        case .gpt52: return "GPT-5.2 (Latest Flagship)"
        case .gpt52Pro: return "GPT-5.2 Pro (Max Intelligence)"
        case .gpt5: return "GPT-5 (Coding & Agents)"
        case .gpt5Mini: return "GPT-5 Mini (Fast)"
        case .gpt5Nano: return "GPT-5 Nano (Cheapest)"
        }
    }
    
    var description: String {
        switch self {
        case .gpt4o: return "Fast and accurate"
        case .gpt52: return "Best for coding & agentic tasks"
        case .gpt52Pro: return "More compute, better reasoning"
        case .gpt5: return "State-of-the-art coding, 400K context"
        case .gpt5Mini: return "Cost-efficient for defined tasks"
        case .gpt5Nano: return "Summarization & classification"
        }
    }
    
    var contextWindow: Int {
        switch self {
        case .gpt4o, .gpt52, .gpt52Pro, .gpt5, .gpt5Mini, .gpt5Nano:
            return 400_000 // 400K context for all GPT-5 models
        }
    }
    
    var estimatedMessagesCapacity: Int {
        return contextWindow / 50 // ~50 tokens per message
    }
}

// MARK: - Response Types

struct OpenAIAnalysisResult: Codable {
    let narrative: OpenAINarrative
    let themes: [String]
    let emotionalTone: String
    let funFacts: [String]
    let personalityInsights: OpenAIPersonalityInsights?
    let yearInEmojis: String
}

struct OpenAINarrative: Codable {
    let openingHook: String
    let keyMoments: [String]
    let relationshipHighlights: String
    let closingReflection: String
}

struct OpenAIPersonalityInsights: Codable {
    let type: String
    let description: String
    let strengths: [String]
    let style: String
}

// MARK: - Account Info

struct OpenAIAccountInfo {
    let isValid: Bool
    let keyPrefix: String
}

// MARK: - Errors

enum OpenAIAPIError: LocalizedError {
    case noAPIKey
    case invalidAPIKey
    case rateLimited
    case requestFailed(Int)
    case invalidResponse
    case apiError(String)
    case insufficientQuota
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Add your OpenAI API key in settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API key."
        case .rateLimited:
            return "Rate limited. Please wait a moment and try again."
        case .requestFailed(let code):
            return "Request failed with status \(code)"
        case .invalidResponse:
            return "Received invalid response from OpenAI"
        case .apiError(let message):
            return "API error: \(message)"
        case .insufficientQuota:
            return "Insufficient API quota. Please add credits at platform.openai.com"
        }
    }
}

// MARK: - Usage Cost Estimation

struct OpenAIUsageEstimate {
    let inputTokens: Int
    let outputTokens: Int
    let model: OpenAIModel
    
    var estimatedCost: Double {
        // Pricing as of December 2025 (per million tokens)
        // Source: platform.openai.com/docs/pricing
        let (inputPrice, outputPrice): (Double, Double) = {
            switch model {
            case .gpt52: return (1.75, 14.00)       // GPT-5.2 flagship
            case .gpt4o: return (5.00, 15.00)       // GPT-4o
            case .gpt52Pro: return (21.00, 168.00)  // GPT-5.2 Pro (max intelligence)
            case .gpt5: return (1.25, 10.00)        // GPT-5
            case .gpt5Mini: return (0.25, 2.00)     // GPT-5 Mini
            case .gpt5Nano: return (0.05, 0.40)     // GPT-5 Nano (cheapest)
            }
        }()
        
        let inputCost = Double(inputTokens) / 1_000_000 * inputPrice
        let outputCost = Double(outputTokens) / 1_000_000 * outputPrice
        return inputCost + outputCost
    }
    
    var formattedCost: String {
        if estimatedCost < 0.01 {
            return "< $0.01"
        }
        return String(format: "$%.2f", estimatedCost)
    }
    
    static func estimate(messageCount: Int, model: OpenAIModel) -> OpenAIUsageEstimate {
        let inputTokens = messageCount * 50 + 500
        let outputTokens = 2000
        return OpenAIUsageEstimate(inputTokens: inputTokens, outputTokens: outputTokens, model: model)
    }
}
