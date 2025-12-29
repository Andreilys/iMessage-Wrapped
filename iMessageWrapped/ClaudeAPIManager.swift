import Foundation
import Security
import AuthenticationServices

// MARK: - Claude API Manager

/// Manages Claude API authentication and requests.
///
/// **Important Note on Authentication:**
/// As of 2025, Anthropic does not offer public OAuth for third-party apps.
/// Claude Code has OAuth, but tokens are restricted: "This credential is only
/// authorized for use with Claude Code and cannot be used for other API requests."
///
/// Therefore, this app uses API key authentication with a streamlined setup flow
/// that opens the Anthropic Console directly.
///
/// Claude Pro/Max subscription credits cannot be used via API - you need separate
/// API credits from console.anthropic.com.
@MainActor
class ClaudeAPIManager: ObservableObject {
    @Published var isConfigured = false
    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var accountInfo: AnthropicAccountInfo?
    
    private let keychainKey = "com.imessagewrapped.claude-api-key"
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let consoleURL = URL(string: "https://console.anthropic.com")!
    private let apiKeysURL = URL(string: "https://console.anthropic.com/settings/keys")!
    
    // Claude's context window - much larger than local options!
    static let contextWindow = 200_000 // tokens
    static let estimatedMessagesCapacity = 4_000 // ~50 tokens per message
    
    init() {
        isConfigured = getAPIKey() != nil
        if isConfigured {
            Task {
                await fetchAccountInfo()
            }
        }
    }
    
    // MARK: - Quick Setup Flow
    
    /// Opens Anthropic Console for the user to get/create an API key
    func openAnthropicConsole() {
        NSWorkspace.shared.open(consoleURL)
    }
    
    /// Opens directly to the API keys page
    func openAPIKeysPage() {
        NSWorkspace.shared.open(apiKeysURL)
    }
    
    /// Validates and saves an API key, fetching account info on success
    func setupWithKey(_ key: String) async -> SetupResult {
        guard key.hasPrefix("sk-ant-") else {
            return .failure("Invalid key format. Claude API keys start with 'sk-ant-'")
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
        // The Anthropic API doesn't have a direct "account info" endpoint,
        // but we can verify the key works and get some info from headers
        guard let apiKey = getAPIKey() else { return }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-3-5-haiku-latest",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "."]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                // Extract any useful headers
                let requestId = httpResponse.value(forHTTPHeaderField: "request-id")
                accountInfo = AnthropicAccountInfo(
                    isValid: httpResponse.statusCode == 200,
                    keyPrefix: String(apiKey.prefix(12)) + "...",
                    requestId: requestId
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
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": "claude-3-5-haiku-latest",
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
    }
    
    // MARK: - Claude API Calls
    
    func analyze(
        messages: [Message],
        analytics: MessageAnalytics,
        model: ClaudeModel = .sonnet
    ) async throws -> ClaudeAnalysisResult {
        guard let apiKey = getAPIKey() else {
            throw ClaudeAPIError.noAPIKey
        }
        
        isProcessing = true
        lastError = nil
        defer { isProcessing = false }
        
        // Format messages for Claude
        // With 200K context, we can include MANY more messages than local LLMs
        let maxMessages = min(messages.count, Self.estimatedMessagesCapacity)
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
            "topContactInsights": [
                {
                    "contact": "contact name/number",
                    "relationshipType": "e.g., close friend, family, colleague",
                    "communicationStyle": "how they communicate with this person",
                    "notablePatterns": ["specific patterns observed"]
                }
            ],
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
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 120 // Claude can take a while for large analyses
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw ClaudeAPIError.invalidAPIKey
        }
        
        if httpResponse.statusCode == 429 {
            throw ClaudeAPIError.rateLimited
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ClaudeAPIError.apiError(message)
            }
            throw ClaudeAPIError.requestFailed(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw ClaudeAPIError.invalidResponse
        }
        
        // Extract JSON from response (Claude might wrap it in markdown)
        let jsonString = extractJSON(from: text)
        
        guard let jsonData = jsonString.data(using: .utf8),
              let analysis = try? JSONDecoder().decode(ClaudeAnalysisResult.self, from: jsonData) else {
            // If parsing fails, return raw text
            return ClaudeAnalysisResult(
                narrative: ClaudeNarrative(
                    openingHook: "Your messaging year was unique!",
                    keyMoments: [text],
                    relationshipHighlights: "",
                    closingReflection: ""
                ),
                topContactInsights: [],
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
        model: ClaudeModel = .sonnet,
        onPartial: @escaping (String) -> Void
    ) async throws -> String {
        guard let apiKey = getAPIKey() else {
            throw ClaudeAPIError.noAPIKey
        }
        
        isProcessing = true
        lastError = nil
        defer { isProcessing = false }
        
        let maxMessages = min(messages.count, Self.estimatedMessagesCapacity)
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
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        var fullResponse = ""
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ClaudeAPIError.requestFailed((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" { break }
                
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let delta = json["delta"] as? [String: Any],
                   let text = delta["text"] as? String {
                    fullResponse += text
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
    
    private func extractJSON(from text: String) -> String {
        // Try to extract JSON from markdown code blocks
        if let start = text.range(of: "```json"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let start = text.range(of: "```"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to find JSON object directly
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        
        return text
    }
}

// MARK: - Models

enum ClaudeModel: String, CaseIterable {
    // Claude 4.5 series (Late 2025 - Latest)
    case sonnet = "claude-3-5-sonnet-20240620"
    case opus45 = "claude-opus-4-5-20251101"
    case sonnet45 = "claude-sonnet-4-5-20250929"
    case haiku45 = "claude-haiku-4-5-20251001"
    
    var displayName: String {
        switch self {
        case .sonnet: return "Claude 3.5 Sonnet"
        case .opus45: return "Claude Opus 4.5 (Best)"
        case .sonnet45: return "Claude Sonnet 4.5 (Balanced)"
        case .haiku45: return "Claude Haiku 4.5 (Fast)"
        }
    }
    
    var description: String {
        switch self {
        case .sonnet: return "Previous best model"
        case .opus45: return "Most intelligent, 67% cheaper than Opus 4"
        case .sonnet45: return "Best for coding & agents, 1M context"
        case .haiku45: return "Ultra-fast, cost-efficient"
        }
    }
    
    var contextWindow: Int {
        switch self {
        case .sonnet, .sonnet45:
            return 1_000_000 // 1M context (beta)
        case .opus45, .haiku45:
            return 200_000 // 200K context
        }
    }
    
    var estimatedMessagesCapacity: Int {
        return contextWindow / 50 // ~50 tokens per message
    }
}

struct ClaudeAnalysisResult: Codable {
    let narrative: ClaudeNarrative
    let topContactInsights: [ContactInsight]
    let themes: [String]
    let emotionalTone: String
    let funFacts: [String]
    let personalityInsights: PersonalityInsights?
    let yearInEmojis: String
}

struct ClaudeNarrative: Codable {
    let openingHook: String
    let keyMoments: [String]
    let relationshipHighlights: String
    let closingReflection: String
}

struct ContactInsight: Codable {
    let contact: String
    let relationshipType: String
    let communicationStyle: String
    let notablePatterns: [String]
}

struct PersonalityInsights: Codable {
    let type: String
    let description: String
    let strengths: [String]
    let style: String
}

// MARK: - Errors

enum ClaudeAPIError: LocalizedError {
    case noAPIKey
    case invalidAPIKey
    case rateLimited
    case requestFailed(Int)
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Add your Claude API key in settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your Claude API key."
        case .rateLimited:
            return "Rate limited. Please wait a moment and try again."
        case .requestFailed(let code):
            return "Request failed with status \(code)"
        case .invalidResponse:
            return "Received invalid response from Claude"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - Account Info

struct AnthropicAccountInfo {
    let isValid: Bool
    let keyPrefix: String
    let requestId: String?
}

// MARK: - Usage Cost Estimation

struct ClaudeUsageEstimate {
    let inputTokens: Int
    let outputTokens: Int
    let model: ClaudeModel
    
    var estimatedCost: Double {
        // Pricing as of December 2025 (per million tokens)
        // Source: platform.claude.com/docs/en/about-claude/pricing
        let (inputPrice, outputPrice): (Double, Double) = {
            switch model {
            case .opus45: return (5.0, 25.0)     // Opus 4.5 (67% cheaper than Opus 4!)
            case .sonnet: return (3.0, 15.0)
            case .sonnet45: return (3.0, 15.0)  // Sonnet 4.5
            case .haiku45: return (1.0, 5.0)    // Haiku 4.5
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
    
    static func estimate(messageCount: Int, model: ClaudeModel) -> ClaudeUsageEstimate {
        // Rough estimates: 50 tokens per message input, 2000 tokens output
        let inputTokens = messageCount * 50 + 500 // messages + prompt
        let outputTokens = 2000
        return ClaudeUsageEstimate(inputTokens: inputTokens, outputTokens: outputTokens, model: model)
    }
}

// MARK: - OAuth Status (for transparency)

/// Explains why we use API keys instead of OAuth login
struct OAuthStatus {
    static let explanation = """
    **Why API Key instead of "Login with Claude"?**
    
    Anthropic currently restricts OAuth to first-party apps like Claude Code. 
    When third-party apps try to use OAuth tokens, they get:
    "This credential is only authorized for use with Claude Code."
    
    Your Claude Pro/Max subscription and API credits are separate:
    • **Pro/Max**: For claude.ai and Claude apps
    • **API Credits**: For developers building apps (like this one)
    
    API usage is pay-as-you-go and very affordable for iMessage analysis 
    (~$0.01-0.50 depending on your message count and model choice).
    """
    
    static let learnMoreURL = URL(string: "https://console.anthropic.com/settings/plans")!
}
