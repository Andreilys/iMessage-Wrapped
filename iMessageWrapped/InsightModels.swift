import Foundation

// MARK: - Communication DNA

/// Your unique texting fingerprint
struct CommunicationDNA: Codable {
    let averageMessageLength: Double
    let questionToStatementRatio: Double
    let emojiDensity: Double  // Emojis per 100 characters
    let avgResponseTimeMinutes: Double?
    let punctuationStyle: PunctuationStyle
    let expressiveness: Double  // 0-1 scale
    let formality: Double  // 0-1 scale
    let vocabularyComplexity: String // e.g. "College Level"
    
    enum PunctuationStyle: String, Codable {
        case minimal = "Minimal Punctuation"
        case proper = "Proper Grammar"
        case ellipsisLover = "Ellipsis Addict..."
        case exclamationEnthusiast = "Exclamation Enthusiast!"
        case emojiOnly = "Pure Emoji Vibes"
    }
    
    var personalityLabel: String {
        if emojiDensity > 5 && expressiveness > 0.7 {
            return "🎨 Expressive Artist"
        } else if formality > 0.7 && questionToStatementRatio > 0.3 {
            return "🎓 Thoughtful Inquirer"
        } else if averageMessageLength < 20 && avgResponseTimeMinutes ?? 60 < 5 {
            return "⚡ Lightning Responder"
        } else if averageMessageLength > 100 {
            return "📖 Storyteller"
        } else if questionToStatementRatio > 0.4 {
            return "🤔 Curious Mind"
        } else {
            return "💬 Balanced Communicator"
        }
    }
    
    var personalityType: String {
        personalityLabel
    }
}

// MARK: - Relationship Dynamics

/// Per-contact relationship analysis
struct RelationshipDynamics: Codable, Identifiable {
    let id: UUID
    let contactIdentifier: String
    let displayName: String
    
    // Initiative & engagement
    let initiativeScore: Double  // -1 (they always start) to 1 (you always start)
    let engagementBalance: Double  // Ratio of sent to received
    let totalMessages: Int
    let conversationCount: Int
    
    // Emotional analysis
    let averageSentiment: Double
    let sentimentVariance: Double  // High = emotional range
    let positiveMessagePercent: Double
    
    // Patterns
    let averageThreadLength: Double  // Messages before 6hr gap
    let peakHour: Int  // 0-23
    
    // NEW: Vibe & Group Analytics
    let vibeCategory: String
    let chaosScore: Double // Messages per minute during active bursts
    let avgResponseTimeMinutes: Double
    
    // Computed convenience properties
    var sentTotal: Int { Int(Double(totalMessages) * engagementBalance / (1 + engagementBalance)) }
    var receivedTotal: Int { totalMessages - sentTotal }
    var relationshipLabel: String { connectionStrength }
    let peakDayOfWeek: Int  // 1-7
    
    // Computed labels
    var dynamicLabel: String {
        if initiativeScore > 0.3 {
            return "You're the initiator"
        } else if initiativeScore < -0.3 {
            return "They keep the convo going"
        } else {
            return "Balanced dynamic"
        }
    }
    
    var connectionStrength: String {
        // More varied labels based on different metrics
        if initiativeScore > 0.6 && totalMessages > 1000 {
            return "🏃‍♂️ The Chaser"
        } else if initiativeScore < -0.6 && totalMessages > 1000 {
            return "💅 The Pursued"
        } else if averageSentiment > 0.6 && sentimentVariance < 0.2 {
            return "☀️ Ray of Sunshine" // Consistently positive
        } else if sentimentVariance > 0.6 && totalMessages > 500 {
            return "🎢 Emotional Rollercoaster" // High variance
        } else if averageThreadLength > 20 && totalMessages > 500 {
            return "📖 The Novelist" // Long threads
        } else if averageThreadLength < 3 && totalMessages > 1000 {
            return "⚡ Rapid Fire" // Short, fast messages
        } else if peakHour >= 22 || peakHour < 4 {
            return "🦉 After Hours Crew" // Late night text patterns
        } else if peakHour >= 9 && peakHour <= 17 && peakDayOfWeek >= 2 && peakDayOfWeek <= 6 {
            return "💼 Strictly Business" // Work hours only
        } else if averageSentiment < -0.2 && totalMessages > 300 {
            return "🌧️ Trauma Bonding" // Shared negative sentiment
        } else if positiveMessagePercent > 0.8 && totalMessages > 1000 {
            return "💖 Soulmate Material"
        } else if engagementBalance > 2.0 {
            return "📢 The Broadcaster" // You talk way more
        } else if engagementBalance < 0.5 {
            return "👂 The Listener" // They talk way more
        } else if totalMessages > 5000 {
            return "🔥 Die Hard"
        } else if totalMessages > 1000 {
            return "💫 Close Orbit"
        } else {
            return "👋 Casual Chat"
        }
    }
}


// MARK: - Named Entities (Your World)

/// Places, people, and things mentioned in texts
struct WorldMapInsights: Codable {
    let places: [NamedEntity]
    let people: [NamedEntity]  // Names mentioned that aren't contacts
    let organizations: [NamedEntity]
    
    var topPlace: NamedEntity? { places.first }
    var topPerson: NamedEntity? { people.first }
    var topOrganization: NamedEntity? { organizations.first }
}

struct NamedEntity: Codable, Identifiable {
    let id: UUID
    let text: String
    let count: Int
    let type: EntityType
    
    var name: String { text }
    
    enum EntityType: String, Codable {
        case place = "Place"
        case person = "Person"
        case organization = "Organization"
    }
}

// MARK: - Communication Evolution

/// How your messaging style changed over time
struct CommunicationEvolution: Codable {
    let monthlyStats: [MonthlySnapshot]
    let wordCountTrend: TrendDirection
    let emojiUsageTrend: TrendDirection
    let responseTimeTrend: TrendDirection
    let newWordsAdopted: [String]  // Words you started using this year
    
    enum TrendDirection: String, Codable {
        case increasing = "📈 Increasing"
        case decreasing = "📉 Decreasing"
        case stable = "➡️ Stable"
    }
}

struct MonthlySnapshot: Codable, Identifiable {
    let id: UUID
    let month: Date
    let messageCount: Int
    let averageLength: Double
    let emojiCount: Int
    let uniqueContacts: Int
}

// MARK: - Connection Patterns

/// Ghosting, reconnections, and relationship health
struct ConnectionPatterns: Codable {
    let ghostingEvents: [GhostingEvent]
    let reconnections: [ReconnectionEvent]
    let fadeOuts: [FadeOutEvent]
    let longestStreak: ConversationStreak?
    let intenseConversations: [ConversationStreak]
}

// GhostDirection enum moved outside for shared use
enum GhostDirection: String, Codable {
    case you = "You went silent"
    case them = "They went silent"
}

struct GhostingEvent: Codable, Identifiable {
    let id: UUID
    let contactIdentifier: String
    let displayName: String
    let gapDays: Int
    let lastMessageDate: Date
    let whoGhosted: GhostDirection
}

struct ReconnectionEvent: Codable, Identifiable {
    let id: UUID
    let contactIdentifier: String
    let displayName: String
    let gapDays: Int
    let reconnectionDate: Date
    let whoReconnected: GhostDirection
}

struct FadeOutEvent: Codable, Identifiable {
    let id: UUID
    let contactIdentifier: String
    let displayName: String
    let peakMessagesPerWeek: Double
    let currentMessagesPerWeek: Double
    let declinePercent: Double
}

struct ConversationStreak: Codable, Identifiable {
    let id: UUID
    let contactIdentifier: String
    let displayName: String
    let messageCount: Int
    let startDate: Date
    let endDate: Date
    let durationMinutes: Int
    
    init(id: UUID = UUID(), contactIdentifier: String, displayName: String, messageCount: Int, startDate: Date, endDate: Date, durationMinutes: Int) {
        self.id = id
        self.contactIdentifier = contactIdentifier
        self.displayName = displayName
        self.messageCount = messageCount
        self.startDate = startDate
        self.endDate = endDate
        self.durationMinutes = durationMinutes
    }
}

// MARK: - Emoji Deep Dive

/// Advanced emoji analysis
struct EmojiDeepDive: Codable {
    let topEmojis: [EmojiInsight]
    let emojiCombos: [EmojiCombo]
    let emojiSentimentMap: [String: Double]  // Emoji -> average sentiment when used
    let totalEmojiCount: Int
    let uniqueEmojiCount: Int
    let emojiPercentOfMessages: Double
}

struct EmojiInsight: Codable, Identifiable {
    let id: UUID
    let emoji: String
    let count: Int
    let percentOfTotal: Double
    let mostUsedWith: String?  // Contact identifier
    let averageSentimentContext: Double
    
    var percent: Double { percentOfTotal }
    var contextDescription: String { meaning }
    
    var meaning: String {
        switch emoji {
        case "😂", "🤣": return "Your go-to for laughs"
        case "❤️", "💕", "😍": return "Spreading the love"
        case "👍", "👌": return "Quick approvals"
        case "😭": return "Peak drama moments"
        case "🔥": return "Hype machine"
        case "😊", "🙂": return "Friendly vibes"
        case "🤔": return "Deep thoughts"
        case "💀", "☠️": return "Dead from laughter"
        default: return "Your signature"
        }
    }
}

struct EmojiCombo: Codable, Identifiable {
    let id: UUID
    let combo: String  // e.g., "😂❤️"
    let count: Int
}

// MARK: - Temporal Fingerprint

/// When and how you communicate
struct TemporalFingerprint: Codable {
    let hourlyDistribution: [Int: Int]
    let weekdayDistribution: [Int: Int]
    
    // Inferred patterns
    let inferredSleepStart: Int  // Hour (0-23)
    let inferredSleepEnd: Int
    let workHoursPercent: Double  // Messages during 9-5
    let weekendVsWeekdayRatio: Double
    
    let nightOwlScore: Double  // 0-1
    let earlyBirdScore: Double  // 0-1
    
    var isNightOwl: Bool { nightOwlScore > earlyBirdScore }
    var workLifeBalance: Double { 1.0 - workHoursPercent }  // Personal time percentage
    
    var chronotype: String {
        if nightOwlScore > 0.6 { return "🦉 Night Owl" }
        if earlyBirdScore > 0.6 { return "🌅 Early Bird" }
        if workHoursPercent > 0.6 { return "💼 9-to-5er" }
        if weekendVsWeekdayRatio > 1.5 { return "🎉 Weekend Warrior" }
        return "⏰ Consistent Communicator"
    }
}

// MARK: - AI Revelations

/// Mind-blowing AI-generated observations
struct AIRevelation: Codable, Identifiable {
    let id: UUID
    let icon: String
    let headline: String
    let detail: String
    let category: RevealCategory
    
    var text: String { headline }
    var type: RevealCategory { category }
    
    enum RevealCategory: String, Codable {
        case comparison = "comparison"
        case relationship = "relationship"
        case pattern = "pattern"
        case superlative = "superlative"
        case quirk = "quirk"
    }
}

// MARK: - Complete Insights Package

/// All insights bundled together
struct WrappedInsights: Codable {
    let generatedAt: Date
    let timePeriodDays: Int
    let totalMessagesAnalyzed: Int
    
    // Core insights
    let communicationDNA: CommunicationDNA
    let relationshipDynamics: [RelationshipDynamics]

    let worldMap: WorldMapInsights
    let evolution: CommunicationEvolution
    let connectionPatterns: ConnectionPatterns
    let emojiDeepDive: EmojiDeepDive
    let temporalFingerprint: TemporalFingerprint
    let aiRevelations: [AIRevelation]
    
    // MLX-generated narrative insights (optional - requires model download)
    var narrativeInsights: NarrativeInsights?
    
    // Legacy compatibility
    var sentimentScore: Double {
        relationshipDynamics.map(\.averageSentiment).reduce(0, +) / Double(max(relationshipDynamics.count, 1))
    }
}

// MARK: - Shareable Card Data

/// Data for generating share cards
struct ShareCardData: Codable {
    let cardType: CardType
    let userName: String?  // Optional personalization
    let timePeriod: String
    let stats: [String: String]
    let accentColor: String  // Hex color
    
    init(type: CardType, userName: String? = nil, timePeriod: String = String(Calendar.current.component(.year, from: Date())), stats: [String: String] = [:], accentColor: String = "#00D4FF") {
        self.cardType = type
        self.userName = userName
        self.timePeriod = timePeriod
        self.stats = stats
        self.accentColor = accentColor
    }
    
    var type: CardType { cardType }
    
    enum CardType: String, Codable {
        case summary = "Summary"
        case personality = "Personality"
        case topFriends = "Top Friends"
        case emoji = "Emoji"
        case vibe = "Vibe"
    }
}

// MARK: - Preview Helper

extension WrappedInsights {
    static var preview: WrappedInsights {
        WrappedInsights(
            generatedAt: Date(),
            timePeriodDays: 365,
            totalMessagesAnalyzed: 5000,
            communicationDNA: CommunicationDNA(
                averageMessageLength: 45,
                questionToStatementRatio: 0.3,
                emojiDensity: 2.5,
                avgResponseTimeMinutes: 15,
                punctuationStyle: .exclamationEnthusiast,
                expressiveness: 0.7,
                formality: 0.4,
                vocabularyComplexity: "Standard"
            ),
            relationshipDynamics: [],

            worldMap: WorldMapInsights(places: [], people: [], organizations: []),
            evolution: CommunicationEvolution(monthlyStats: [], wordCountTrend: .stable, emojiUsageTrend: .increasing, responseTimeTrend: .stable, newWordsAdopted: []),
            connectionPatterns: ConnectionPatterns(ghostingEvents: [], reconnections: [], fadeOuts: [], longestStreak: nil, intenseConversations: []),
            emojiDeepDive: EmojiDeepDive(
                topEmojis: [
                    EmojiInsight(id: UUID(), emoji: "😂", count: 500, percentOfTotal: 25, mostUsedWith: nil, averageSentimentContext: 0.8)
                ],
                emojiCombos: [],
                emojiSentimentMap: [:],
                totalEmojiCount: 2000,
                uniqueEmojiCount: 50,
                emojiPercentOfMessages: 40
            ),
            temporalFingerprint: TemporalFingerprint(
                hourlyDistribution: [:],
                weekdayDistribution: [:],
                inferredSleepStart: 23,
                inferredSleepEnd: 7,
                workHoursPercent: 0.4,
                weekendVsWeekdayRatio: 1.2,
                nightOwlScore: 0.7,
                earlyBirdScore: 0.3
            ),
            aiRevelations: [
                AIRevelation(id: UUID(), icon: "⚖️", headline: "You and your best friend share 87% semantic similarity!", detail: "You basically speak the same language.", category: .comparison)
            ]
        )
    }
}
