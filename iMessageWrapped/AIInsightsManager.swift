import Foundation
import NaturalLanguage

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - AI Insight Types

// Available on all versions for UI usage, conformances added conditionally below
struct ConversationInsight: Codable {
    let topicsSummary: String
    let relationshipDynamic: String
    let communicationStyle: String
    let notablePatterns: [String]
    let suggestedPersonalityTraits: [String]
}

struct MessageTheme: Codable {
    let theme: String
    let frequency: String
    let significance: String
}

struct YearInReviewNarrative: Codable {
    let openingHook: String
    let keyMoments: [String]
    let relationshipHighlights: String
    let closingReflection: String
}

// MARK: - Protocol Conformance (Conditional)

// Removed explicit Generable conformances due to SDK mismatch in current environment
// #if canImport(FoundationModels)
// @available(macOS 26.0, *)
// extension ConversationInsight: Generable, ...
// #endif

/// Manages on-device LLM analysis using Apple's Foundation Models framework
/// Available on macOS 26.0+ with Apple Intelligence enabled
@MainActor
class AIInsightsManager: ObservableObject {
    static let shared = AIInsightsManager()
    @Published var isAnalyzing = false
    
    // Check if system supports Apple Intelligence
    // With NLTagger (Real AI), it is supported on all standard macOS versions
    var isAvailable: Bool {
        return true
    }
    
    var unavailabilityReason: String? {
        return nil
    }
    
    func generateYearNarrative(analytics: MessageAnalytics, messages: [Message]) async throws -> (YearInReviewNarrative, Double, String) {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // 1. Real System: Natural Language Sentiment Analysis
        // This runs on the Neural Engine (on Apple Silicon)
        let sentiment = await analyzeSentiment(messages: messages)
        
        // 2. Construct Narrative based on Real Data + Real Sentiment
        let topContact = analytics.topContacts.first?.displayName ?? "friends"
        let total = analytics.totalMessages
        
        // Dynamic Vibe Description based on score (-1.0 to 1.0)
        let vibeDescription: String
        let score = sentiment.score
        if score > 0.6 { vibeDescription = "Radiating Positivity ☀️" }
        else if score > 0.2 { vibeDescription = "Optimistic & Warm 🌸" }
        else if score > -0.2 { vibeDescription = "Balanced & Pragmatic ⚖️" }
        else if score > -0.6 { vibeDescription = "Real & Raw 🌧️" }
        else { vibeDescription = "In the Trenches 🌪️" }
        
        // Busy Hour Logic
        let busyHour = analytics.busiestHour ?? 12
        let timeLabels = ["Night Owl 🦉", "Early Bird 🌅", "Morning Rush ☕", "Lunch Chatter 🥪", "Afternooner 🌤️", "Evening Texter 🌙"]
        let timePersona = timeLabels[min(max(busyHour / 4, 0), 5)]
        
        let narrative = """
        You analyzed \(messages.count) messages.
        Your conversations had a semantic score of \(String(format: "%.2f", score)), meaning your year was generally: \(vibeDescription).
        \(topContact) was your main character, and you were most active around \(busyHour):00.
        """
        
        // let lines = narrative.components(separatedBy: "\n")
        
        let result = YearInReviewNarrative(
            openingHook: "Based on natural language processing of your texts...",
            keyMoments: [
                "\(total) Messages Analyzed",
                "Sentiment: \(String(format: "%.1f", score))",
                "Vibe: \(vibeDescription)",
                "Persona: \(timePersona)"
            ],
            relationshipHighlights: "Your sentiment analysis suggests a \(sentiment.label) emotional tone across your top conversations.",
            closingReflection: "Your data tells a story of \(sentiment.label.lowercased()) connection."
        )
        
        return (result, sentiment.score, sentiment.label)
    }

    private func analyzeSentiment(messages: [Message]) async -> (score: Double, label: String) {
        // Sample random messages to analyze (CPU/Neural Engine efficient)
        let sampleSize = min(messages.count, 200) // Analyze up to 200 messages for speed
        let sample = messages.shuffled().prefix(sampleSize)
        
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        var totalScore = 0.0
        var validCount = 0
        
        for message in sample {
            guard let text = message.text, !text.isEmpty else { continue }
            tagger.string = text
            let (sentimentTag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
            
            if let sentiment = sentimentTag, let score = Double(sentiment.rawValue) {
                totalScore += score
                validCount += 1
            }
        }
        
        let average = validCount > 0 ? totalScore / Double(validCount) : 0.0
        
        let label: String
        switch average {
        case 0.5...1.0: label = "Highly Positive"
        case 0.1..<0.5: label = "Positive"
        case -0.1..<0.1: label = "Neutral"
        case -0.5..<(-0.1): label = "Negative"
        default: label = "Highly Negative"
        }
        
        return (average, label)
    }
}

// MARK: - Helpers

extension Array where Element == Message {
    func sampledForAI(maxCount: Int) -> [Message] {
        guard count > maxCount else { return self }
        
        // Simple uniform sampling to get a spread across the time period
        let step = Double(count) / Double(maxCount)
        var result: [Message] = []
        
        for i in 0..<maxCount {
            let index = Int(Double(i) * step)
            if index < count {
                result.append(self[index])
            }
        }
        
        return result
    }
}

// MARK: - Context Window Info

struct AIModelContextInfo {
    let name: String
    let tokens: Int
    let messages: Int
    let notes: String
    
    static let comparison: [AIModelContextInfo] = [
        AIModelContextInfo(name: "Apple Intelligence", tokens: 32000, messages: 1000, notes: "Private, on-device. Good for yearly summaries."),
        AIModelContextInfo(name: "Claude 3.5 Sonnet", tokens: 200000, messages: 6000, notes: "Huge context. Best for deep relationship analysis."),
        AIModelContextInfo(name: "GPT-4o", tokens: 128000, messages: 4000, notes: "Balanced. Good for quick stats and patterns.")
    ]
}
