import Foundation
import NaturalLanguage

// MARK: - Advanced AI Analyzer

/// Full-featured on-device AI analysis using Apple's NaturalLanguage framework
@MainActor
class AdvancedAIAnalyzer: ObservableObject {
    static let shared = AdvancedAIAnalyzer()
    
    @Published var isAnalyzing = false
    @Published var progress: Double = 0
    @Published var currentStep: String = ""
    
    private let sentimentTagger = NLTagger(tagSchemes: [.sentimentScore])
    private let lexicalTagger = NLTagger(tagSchemes: [.lexicalClass])
    private let nerTagger = NLTagger(tagSchemes: [.nameType])
    private let lemmaTagger = NLTagger(tagSchemes: [.lemma])
    
    // MARK: - Main Analysis Entry Point
    
    func analyzeMessages(_ messages: [Message], days: Int) async -> WrappedInsights {
        isAnalyzing = true
        progress = 0
        
        defer {
            isAnalyzing = false
            progress = 1.0
        }
        
        // Step 1: Communication DNA
        currentStep = "Analyzing your communication style..."
        let dna = await analyzeCommunicationDNA(messages)
        progress = 0.1
        
        // Step 2: Relationship Dynamics
        currentStep = "Mapping relationship dynamics..."
        let dynamics = await analyzeRelationshipDynamics(messages)
        progress = 0.25
        

        
        // Step 4: Named Entity Recognition
        currentStep = "Exploring your world..."
        let worldMap = await extractNamedEntities(messages)
        progress = 0.5
        
        // Step 5: Communication Evolution
        currentStep = "Tracking your evolution..."
        let evolution = await analyzeEvolution(messages, days: days)
        progress = 0.6
        
        // Step 6: Connection Patterns
        currentStep = "Detecting connection patterns..."
        let connections = await analyzeConnectionPatterns(messages)
        progress = 0.7
        
        // Step 7: Emoji Deep Dive
        currentStep = "Decoding your emoji language..."
        let emojis = await analyzeEmojis(messages)
        progress = 0.8
        
        // Step 8: Temporal Fingerprint
        currentStep = "Reading your temporal rhythms..."
        let temporal = analyzeTemporalPatterns(messages)
        progress = 0.9
        
        // Step 9: AI Revelations
        currentStep = "Generating AI insights..."
        
        // Generate template-based revelations (NaturalLanguage-powered)
        let revelations = generateRevelations(
            dna: dna,
            dynamics: dynamics,
            // topics: topics, // Removed

            emojis: emojis,
            temporal: temporal,
            messages: messages
        )
        // Build final insights
        let insights = WrappedInsights(
            generatedAt: Date(),
            timePeriodDays: days,
            totalMessagesAnalyzed: messages.count,
            communicationDNA: dna,
            relationshipDynamics: dynamics,
            // topicClusters: topics, // Removed
            // REPLACED: topicClusters removed from init

            worldMap: worldMap,
            evolution: evolution,
            connectionPatterns: connections,
            emojiDeepDive: emojis,
            temporalFingerprint: temporal,
            aiRevelations: revelations
        )
        
        progress = 1.0
        return insights
    }
    
    // MARK: - Communication DNA Analysis
    
    private func analyzeCommunicationDNA(_ messages: [Message]) async -> CommunicationDNA {
        let myMessages = messages.filter { $0.isFromMe }
        let texts = myMessages.compactMap { $0.text }.filter { !$0.isEmpty }
        
        // Average message length
        let avgLength = texts.isEmpty ? 0 : Double(texts.reduce(0) { $0 + $1.count }) / Double(texts.count)
        
        // Question to statement ratio
        let questions = texts.filter { $0.contains("?") }.count
        let questionRatio = texts.isEmpty ? 0 : Double(questions) / Double(texts.count)
        
        // Emoji density
        let totalChars = texts.reduce(0) { $0 + $1.count }
        let totalEmojis = texts.reduce(0) { count, text in
            count + text.filter { $0.isEmoji }.count
        }
        let emojiDensity = totalChars > 0 ? Double(totalEmojis) / Double(totalChars) * 100 : 0
        
        // Punctuation style
        let exclamations = texts.filter { $0.contains("!") }.count
        let ellipses = texts.filter { $0.contains("...") || $0.contains("…") }.count
        let periods = texts.filter { $0.hasSuffix(".") && !$0.hasSuffix("...") }.count
        
        let punctuationStyle: CommunicationDNA.PunctuationStyle
        if Double(totalEmojis) / Double(max(texts.count, 1)) > 2 {
            punctuationStyle = .emojiOnly
        } else if Double(exclamations) / Double(max(texts.count, 1)) > 0.4 {
            punctuationStyle = .exclamationEnthusiast
        } else if Double(ellipses) / Double(max(texts.count, 1)) > 0.2 {
            punctuationStyle = .ellipsisLover
        } else if Double(periods) / Double(max(texts.count, 1)) > 0.5 {
            punctuationStyle = .proper
        } else {
            punctuationStyle = .minimal
        }
        
        // Expressiveness (emoji + exclamation + caps usage)
        let capsMessages = texts.filter { text in
            let letters = text.filter { $0.isLetter }
            let caps = letters.filter { $0.isUppercase }
            return letters.count > 3 && Double(caps.count) / Double(letters.count) > 0.5
        }.count
        let expressiveness = min(1.0, (emojiDensity / 10) + (Double(exclamations) / Double(max(texts.count, 1))) + (Double(capsMessages) / Double(max(texts.count, 1))))
        
        // Formality (proper punctuation, capitalization, no slang abbreviations)
        let slangWords = ["lol", "lmao", "omg", "tbh", "ngl", "idk", "brb", "btw", "rn", "fr"]
        let hasSlang = texts.filter { text in
            let lower = text.lowercased()
            return slangWords.contains(where: { lower.contains($0) })
        }.count
        let formality = 1.0 - min(1.0, Double(hasSlang) / Double(max(texts.count, 1)) + (1 - (Double(periods) / Double(max(texts.count, 1)))) * 0.5)
        
        // Response time analysis
        let avgResponseTime = calculateAverageResponseTime(messages)
        
        return CommunicationDNA(
            averageMessageLength: avgLength,
            questionToStatementRatio: questionRatio,
            emojiDensity: emojiDensity,
            avgResponseTimeMinutes: avgResponseTime,
            punctuationStyle: punctuationStyle,
            expressiveness: max(0, expressiveness),
            formality: max(0, formality),
            vocabularyComplexity: "Analyzing..."
        )
    }
    
    private func calculateAverageResponseTime(_ messages: [Message]) -> Double {
        var totalTime: TimeInterval = 0
        var count: Int = 0
        
        // Analyze per contact to respect conversation threads
        let contactThreads = Dictionary(grouping: messages, by: { $0.contactIdentifier })
        
        for (_, thread) in contactThreads {
            let sorted = thread.sorted { $0.date < $1.date }
            var lastReceivedTime: Date?
            
            for msg in sorted {
                if !msg.isFromMe {
                    // Update latest message from them
                    lastReceivedTime = msg.date
                } else if let receivedTime = lastReceivedTime {
                    // This is a response from me
                    let diff = msg.date.timeIntervalSince(receivedTime)
                    
                    // Only count if within reasonable timeframe (e.g. 12 hours)
                    // Otherwise it's likely a new conversation started by me
                    if diff > 0 && diff < 43200 {
                        totalTime += diff
                        count += 1
                    }
                    
                    // Reset so we don't count subsequent messages as new responses
                    lastReceivedTime = nil
                }
            }
        }
        
        guard count > 0 else { return 0 }
        return (totalTime / Double(count)) / 60.0 // Convert to minutes
    }
    
    // MARK: - Relationship Dynamics
    
    private func analyzeRelationshipDynamics(_ messages: [Message]) async -> [RelationshipDynamics] {
        var contactMessages: [String: [Message]] = [:]
        
        for message in messages {
            let contact = message.contactIdentifier
            contactMessages[contact, default: []].append(message)
        }
        
        var results: [RelationshipDynamics] = []
        
        for (contact, msgs) in contactMessages {
            // Filter out unknown contacts
            if contact == "Unknown" || contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            
            let sent = msgs.filter { $0.isFromMe }
            let received = msgs.filter { !$0.isFromMe }
            
            // Initiative score: who starts conversations more
            let conversations = groupIntoConversations(msgs)
            let iStarted = conversations.filter { conv in
                conv.first?.isFromMe == true
            }.count
            let initiativeScore = conversations.isEmpty ? 0 : (Double(iStarted) / Double(conversations.count) - 0.5) * 2
            
            // Engagement balance
            let engagementBalance = received.isEmpty ? 1.0 : Double(sent.count) / Double(received.count)
            
            // Sentiment analysis
            let sentiments = await analyzeSentiments(msgs.compactMap { $0.text })
            let avgSentiment = sentiments.isEmpty ? 0 : sentiments.reduce(0, +) / Double(sentiments.count)
            let sentimentVariance = calculateVariance(sentiments)
            let positivePercent = sentiments.isEmpty ? 0 : Double(sentiments.filter { $0 > 0.1 }.count) / Double(sentiments.count)
            
            // Peak times
            let hours = msgs.map { Calendar.current.component(.hour, from: $0.date) }
            let peakHour = mode(of: hours) ?? 12
            let weekdays = msgs.map { Calendar.current.component(.weekday, from: $0.date) }
            let peakDay = mode(of: weekdays) ?? 1
            
            // Average thread length
            let avgThreadLength = conversations.isEmpty ? 0 : Double(msgs.count) / Double(conversations.count)
            
            // Chaos Score (Burstiness)
            let chaosScore = calculateChaosScore(msgs)
            
            // Response Time (Specific to this contact)
            let contactResponseTime = calculateContactResponseTime(msgs, contactId: contact)
            
            // Vibe Analysis (Semantic)
            let vibe = analyzeSemanticVibe(for: msgs.compactMap { $0.text }.prefix(50).map { String($0) })

            results.append(RelationshipDynamics(
                id: UUID(),
                contactIdentifier: contact,
                displayName: MessageAnalytics.formatContactName(contact),
                initiativeScore: initiativeScore,
                engagementBalance: engagementBalance,
                totalMessages: msgs.count,
                conversationCount: conversations.count,
                averageSentiment: avgSentiment,
                sentimentVariance: sentimentVariance,
                positiveMessagePercent: positivePercent,
                averageThreadLength: avgThreadLength,
                peakHour: peakHour,
                vibeCategory: vibe,
                chaosScore: chaosScore,
                avgResponseTimeMinutes: contactResponseTime,
                peakDayOfWeek: peakDay
            ))
        }
        
        return results.sorted { $0.totalMessages > $1.totalMessages }
    }
    
    // MARK: - Vibe & Analytics Helpers
    
    private func calculateChaosScore(_ messages: [Message]) -> Double {
        guard messages.count > 10 else { return 0 }
        
        // Group by 1-minute buckets
        var minutes: [TimeInterval: Int] = [:]
        for msg in messages {
            let bucket = floor(msg.date.timeIntervalSinceReferenceDate / 60)
            minutes[bucket, default: 0] += 1
        }
        
        // Find peak message rates (Messages Per Minute)
        let peakRate = minutes.values.max() ?? 0
        let avgRate = Double(minutes.values.reduce(0, +)) / Double(minutes.count)
        
        // Chaos = combination of peak burstiness and sustained speed
        // Normalize: if peak > 10 msg/min, that's high chaos.
        return min(1.0, (Double(peakRate) * 0.7 + avgRate * 0.3) / 5.0)
    }
    
    private func calculateContactResponseTime(_ messages: [Message], contactId: String) -> Double {
        let sorted = messages.sorted { $0.date < $1.date }
        var totalResponseTime: TimeInterval = 0
        var responseCount = 0
        
        for i in 1..<sorted.count {
            let prev = sorted[i-1]
            let curr = sorted[i]
            
            // If previous was THEM and current is ME
            if !prev.isFromMe && curr.isFromMe {
                let diff = curr.date.timeIntervalSince(prev.date)
                // Filter out likely "new conversations" (> 2 hours)
                if diff < 7200 {
                    totalResponseTime += diff
                    responseCount += 1
                }
            }
        }
        
        return responseCount > 0 ? (totalResponseTime / Double(responseCount)) / 60.0 : 0
    }
    
    private func analyzeSemanticVibe(for texts: [String]) -> String {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else { return "Neutral" }
        
        // Anchor Vibes
        let anchors: [String: String] = [
            "Hype": "OMG lets go! that is amazing!!! fire emoji hypeeee",
            "Intellectual": "The article discusses the implications of ai philosophy and technology",
            "Supportive": "I am so proud of you, you got this, sending love and support, hope you are okay",
            "Planning": "What time should we meet? lets schedule a call, send me the calendar invite",
            "Chaos": "bruh dead lol what even is this chaotic energy random",
            "Flirty": "miss you, cutie, date night, looking good, heart eyes"
        ]
        
        // Aggregate text content (limit to avoid memory issues)
        let combinedText = texts.joined(separator: " ").prefix(1000)
        
        var bestVibe = "Neutral"
        var bestDistance = 2.0 // Lower is better for cosine distance
        
        for (vibe, anchorText) in anchors {
            let distance = embedding.distance(between: String(combinedText), and: anchorText, distanceType: .cosine)
            if distance < bestDistance {
                bestDistance = distance
                bestVibe = vibe
            }
        }
        
        return bestVibe
    }
    

    
    // MARK: - Named Entity Recognition
    
    private func extractNamedEntities(_ messages: [Message]) async -> WorldMapInsights {
        var places: [String: Int] = [:]
        var people: [String: Int] = [:]
        var organizations: [String: Int] = [:]
        
        let texts = messages.compactMap { $0.text }.prefix(500)  // Limit for performance
        
        for text in texts {
            nerTagger.string = text
            
            nerTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
                guard let tag = tag else { return true }
                let entity = String(text[range])
                
                // Skip very short or common words
                guard entity.count > 2 else { return true }
                
                switch tag {
                case .placeName:
                    places[entity, default: 0] += 1
                case .personalName:
                    people[entity, default: 0] += 1
                case .organizationName:
                    organizations[entity, default: 0] += 1
                default:
                    break
                }
                return true
            }
        }
        
        return WorldMapInsights(
            places: places.sorted { $0.value > $1.value }.prefix(10).map {
                NamedEntity(id: UUID(), text: $0.key, count: $0.value, type: .place)
            },
            people: people.sorted { $0.value > $1.value }.prefix(10).map {
                NamedEntity(id: UUID(), text: $0.key, count: $0.value, type: .person)
            },
            organizations: organizations.sorted { $0.value > $1.value }.prefix(10).map {
                NamedEntity(id: UUID(), text: $0.key, count: $0.value, type: .organization)
            }
        )
    }
    
    // MARK: - Communication Evolution
    
    private func analyzeEvolution(_ messages: [Message], days: Int) async -> CommunicationEvolution {
        // Group messages by month
        var monthlyGroups: [String: [Message]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        for message in messages {
            let key = formatter.string(from: message.date)
            monthlyGroups[key, default: []].append(message)
        }
        
        var snapshots: [MonthlySnapshot] = []
        for (monthKey, msgs) in monthlyGroups.sorted(by: { $0.key < $1.key }) {
            let myMsgs = msgs.filter { $0.isFromMe }
            let texts = myMsgs.compactMap { $0.text }
            let avgLen = texts.isEmpty ? 0 : Double(texts.reduce(0) { $0 + $1.count }) / Double(texts.count)
            let emojiCount = texts.reduce(0) { $0 + $1.filter { $0.isEmoji }.count }
            let uniqueContacts = Set(msgs.map { $0.contactIdentifier }).count
            
            if let date = formatter.date(from: monthKey) {
                snapshots.append(MonthlySnapshot(
                    id: UUID(),
                    month: date,
                    messageCount: msgs.count,
                    averageLength: avgLen,
                    emojiCount: emojiCount,
                    uniqueContacts: uniqueContacts
                ))
            }
        }
        
        // Calculate trends
        let wordCountTrend = calculateTrend(snapshots.map { $0.averageLength })
        let emojiTrend = calculateTrend(snapshots.map { Double($0.emojiCount) })
        
        return CommunicationEvolution(
            monthlyStats: snapshots,
            wordCountTrend: wordCountTrend,
            emojiUsageTrend: emojiTrend,
            responseTimeTrend: .stable,  // Would need more analysis
            newWordsAdopted: []  // Would need historical comparison
        )
    }
    
    // MARK: - Connection Patterns
    
    private func analyzeConnectionPatterns(_ messages: [Message]) async -> ConnectionPatterns {
        var ghostingEvents: [GhostingEvent] = []
        var reconnections: [ReconnectionEvent] = []
        var longestStreak: ConversationStreak?
        var intenseConversations: [ConversationStreak] = []
        
        // Group by contact
        var contactMessages: [String: [Message]] = [:]
        for message in messages {
            contactMessages[message.contactIdentifier, default: []].append(message)
        }
        
        for (contact, msgs) in contactMessages {
            let sorted = msgs.sorted { $0.date < $1.date }
            
            // Find gaps
            for i in 1..<sorted.count {
                let gap = sorted[i].date.timeIntervalSince(sorted[sorted.index(before: i)].date)
                let gapDays = Int(gap / 86400)
                
                if gapDays >= 7 {
                    let prevMsg = sorted[sorted.index(before: i)]
                    let nextMsg = sorted[i]
                    let whoGhosted: GhostDirection = prevMsg.isFromMe ? .them : .you
                    let whoReconnected: GhostDirection = nextMsg.isFromMe ? .you : .them
                    
                    ghostingEvents.append(GhostingEvent(
                        id: UUID(),
                        contactIdentifier: contact,
                        displayName: MessageAnalytics.formatContactName(contact),
                        gapDays: gapDays,
                        lastMessageDate: prevMsg.date,
                        whoGhosted: whoGhosted
                    ))
                    
                    reconnections.append(ReconnectionEvent(
                        id: UUID(),
                        contactIdentifier: contact,
                        displayName: MessageAnalytics.formatContactName(contact),
                        gapDays: gapDays,
                        reconnectionDate: nextMsg.date,
                        whoReconnected: whoReconnected
                    ))
                }
            }
            
            // Find longest streak and intense conversations
            let conversations = groupIntoConversations(sorted)
            for conv in conversations {
                guard conv.count > 10 else { continue }
                if let first = conv.first, let last = conv.last {
                    let duration = Int(last.date.timeIntervalSince(first.date) / 60)
                    let streak = ConversationStreak(
                        contactIdentifier: contact,
                        displayName: MessageAnalytics.formatContactName(contact),
                        messageCount: conv.count,
                        startDate: first.date,
                        endDate: last.date,
                        durationMinutes: max(1, duration)
                    )
                    
                    if longestStreak == nil || conv.count > longestStreak!.messageCount {
                        longestStreak = streak
                    }
                    
                    // Intense conversation: high message rate (>2 per minute)
                    if duration > 0 && Double(conv.count) / Double(duration) > 0.5 {
                        intenseConversations.append(streak)
                    }
                }
            }
        }
        
        return ConnectionPatterns(
            ghostingEvents: Array(ghostingEvents.sorted { $0.gapDays > $1.gapDays }.prefix(10)),
            reconnections: Array(reconnections.sorted { $0.gapDays > $1.gapDays }.prefix(10)),
            fadeOuts: [],  // Would need longer term analysis
            longestStreak: longestStreak,
            intenseConversations: Array(intenseConversations.sorted { $0.messageCount > $1.messageCount }.prefix(5))
        )
    }
    
    // MARK: - Emoji Analysis
    
    private func analyzeEmojis(_ messages: [Message]) async -> EmojiDeepDive {
        var emojiCounts: [String: Int] = [:]
        var emojiByContact: [String: [String: Int]] = [:]
        var emojiContexts: [String: [Double]] = [:]
        var comboCounts: [String: Int] = [:]
        
        for message in messages {
            guard let text = message.text else { continue }
            let contact = message.contactIdentifier
            let sentiment = await analyzeSentiment(text)
            
            var lastEmoji: String?
            for char in text {
                if char.isEmoji {
                    let emoji = String(char)
                    emojiCounts[emoji, default: 0] += 1
                    emojiByContact[emoji, default: [:]][contact, default: 0] += 1
                    emojiContexts[emoji, default: []].append(sentiment)
                    
                    if let last = lastEmoji {
                        comboCounts[last + emoji, default: 0] += 1
                    }
                    lastEmoji = emoji
                } else {
                    lastEmoji = nil
                }
            }
        }
        
        let totalEmojis = emojiCounts.values.reduce(0, +)
        
        let topEmojis = emojiCounts.sorted { $0.value > $1.value }.prefix(15).map { emoji, count -> EmojiInsight in
            let contacts = emojiByContact[emoji] ?? [:]
            let topContact = contacts.max { $0.value < $1.value }?.key
            let sentiments = emojiContexts[emoji] ?? []
            let avgSentiment = sentiments.isEmpty ? 0 : sentiments.reduce(0, +) / Double(sentiments.count)
            
            return EmojiInsight(
                id: UUID(),
                emoji: emoji,
                count: count,
                percentOfTotal: Double(count) / Double(max(totalEmojis, 1)) * 100,
                mostUsedWith: topContact.map { MessageAnalytics.formatContactName($0) },
                averageSentimentContext: avgSentiment
            )
        }
        
        let topCombos = comboCounts.sorted { $0.value > $1.value }.prefix(5).map {
            EmojiCombo(id: UUID(), combo: $0.key, count: $0.value)
        }
        
        let messagesWithEmoji = messages.filter { $0.text?.contains(where: { $0.isEmoji }) ?? false }.count
        
        return EmojiDeepDive(
            topEmojis: Array(topEmojis),
            emojiCombos: Array(topCombos),
            emojiSentimentMap: emojiContexts.mapValues { sentiments in
                sentiments.isEmpty ? 0 : sentiments.reduce(0, +) / Double(sentiments.count)
            },
            totalEmojiCount: totalEmojis,
            uniqueEmojiCount: emojiCounts.count,
            emojiPercentOfMessages: Double(messagesWithEmoji) / Double(max(messages.count, 1)) * 100
        )
    }
    
    // MARK: - Temporal Analysis
    
    private func analyzeTemporalPatterns(_ messages: [Message]) -> TemporalFingerprint {
        var hourly: [Int: Int] = [:]
        var weekday: [Int: Int] = [:]
        
        for message in messages {
            let hour = Calendar.current.component(.hour, from: message.date)
            let day = Calendar.current.component(.weekday, from: message.date)
            hourly[hour, default: 0] += 1
            weekday[day, default: 0] += 1
        }
        
        // Infer sleep hours (find the quietest 6-hour window)
        var minSum = Int.max
        var sleepStart = 2  // Default to 2 AM
        for start in 0..<24 {
            var sum = 0
            for offset in 0..<6 {
                sum += hourly[(start + offset) % 24, default: 0]
            }
            if sum < minSum {
                minSum = sum
                sleepStart = start
            }
        }
        let sleepEnd = (sleepStart + 6) % 24
        
        // Work hours (9-17)
        var workHourMessages = 0
        var totalMessages = 0
        for (hour, count) in hourly {
            totalMessages += count
            if hour >= 9 && hour <= 17 {
                workHourMessages += count
            }
        }
        let workPercent = totalMessages > 0 ? Double(workHourMessages) / Double(totalMessages) : 0
        
        // Weekend vs weekday
        let weekendDays: Set<Int> = [1, 7]
        let weekendMessages = weekendDays.reduce(0) { $0 + (weekday[$1, default: 0]) }
        let weekdayMessages = [2, 3, 4, 5, 6].reduce(0) { $0 + (weekday[$1, default: 0]) }
        let weekendRatio = weekdayMessages > 0 ? Double(weekendMessages) / Double(weekdayMessages) * (5.0/2.0) : 1.0
        
        // Night owl score (messages 10pm - 2am)
        let nightHours = [22, 23, 0, 1]
        let nightMessages = nightHours.reduce(0) { $0 + (hourly[$1, default: 0]) }
        let nightOwlScore = min(1.0, Double(nightMessages) / Double(max(totalMessages, 1)) * 8)
        
        // Early bird score (messages 5am - 8am)
        let earlyHours = [5, 6, 7]
        let earlyMessages = earlyHours.reduce(0) { $0 + (hourly[$1, default: 0]) }
        let earlyBirdScore = min(1.0, Double(earlyMessages) / Double(max(totalMessages, 1)) * 8)
        
        return TemporalFingerprint(
            hourlyDistribution: hourly,
            weekdayDistribution: weekday,
            inferredSleepStart: sleepStart,
            inferredSleepEnd: sleepEnd,
            workHoursPercent: workPercent,
            weekendVsWeekdayRatio: weekendRatio,
            nightOwlScore: nightOwlScore,
            earlyBirdScore: earlyBirdScore
        )
    }
    
    // MARK: - AI Revelations Generator
    
    private func generateRevelations(
        dna: CommunicationDNA,
        dynamics: [RelationshipDynamics],

        emojis: EmojiDeepDive,
        temporal: TemporalFingerprint,
        messages: [Message]
    ) -> [AIRevelation] {
        var revelations: [AIRevelation] = []
        
        // Top friend revelation
        if let topDynamic = dynamics.first {
            // Ensure we have a valid name, fallback to "Your #1 Contact" if empty
            let name = topDynamic.displayName.isEmpty || topDynamic.displayName == "Unknown" ? "Your #1 Contact" : topDynamic.displayName
            
            revelations.append(AIRevelation(
                id: UUID(),
                icon: "❤️",
                headline: "\(name) is your #1",
                detail: "You exchanged \(topDynamic.totalMessages) messages with a \(String(format: "%.0f", topDynamic.positiveMessagePercent * 100))% positive vibe rate",
                category: .relationship
            ))
        }
        
        // Initiative pattern
        if let topDynamic = dynamics.first {
            if topDynamic.initiativeScore > 0.3 {
                revelations.append(AIRevelation(
                    id: UUID(),
                    icon: "🚀",
                    headline: "You're the conversation starter",
                    detail: "You initiate \(Int((topDynamic.initiativeScore + 1) / 2 * 100))% of chats with \(topDynamic.displayName)",
                    category: .pattern
                ))
            }
        }
        
        // Emoji insight
        if let topEmoji = emojis.topEmojis.first {
            revelations.append(AIRevelation(
                id: UUID(),
                icon: topEmoji.emoji,
                headline: "Your signature emoji",
                detail: "You used \(topEmoji.emoji) \(topEmoji.count) times - \(topEmoji.meaning)",
                category: .quirk
            ))
        }
        

        
        // Temporal insight
        revelations.append(AIRevelation(
            id: UUID(),
            icon: temporal.chronotype.prefix(2).description,
            headline: "You're a \(temporal.chronotype.dropFirst(2))",
            detail: temporal.nightOwlScore > 0.5 ? 
                "Peak texting happens after 10pm" : 
                (temporal.earlyBirdScore > 0.5 ? "You're most active before 8am" : "You text steadily throughout the day"),
            category: .pattern
        ))
        
        // Message length insight
        if dna.averageMessageLength > 100 {
            revelations.append(AIRevelation(
                id: UUID(),
                icon: "📖",
                headline: "You write novels, not texts",
                detail: "Average message length: \(Int(dna.averageMessageLength)) characters",
                category: .quirk
            ))
        } else if dna.averageMessageLength < 30 {
            revelations.append(AIRevelation(
                id: UUID(),
                icon: "⚡",
                headline: "Quick and snappy",
                detail: "You keep it brief at \(Int(dna.averageMessageLength)) chars per message",
                category: .quirk
            ))
        }
        
        // Question asker
        if dna.questionToStatementRatio > 0.3 {
            revelations.append(AIRevelation(
                id: UUID(),
                icon: "🤔",
                headline: "Curious mind alert",
                detail: "\(Int(dna.questionToStatementRatio * 100))% of your messages are questions",
                category: .quirk
            ))
        }
        
        // Unique comparisons
        if dynamics.count >= 2 {
            let top2 = dynamics.prefix(2)
            if let first = top2.first, let second = Array(top2).last {
                let sentimentDiff = abs(first.averageSentiment - second.averageSentiment)
                if sentimentDiff > 0.2 {
                    let morePositive = first.averageSentiment > second.averageSentiment ? first : second
                    revelations.append(AIRevelation(
                        id: UUID(),
                        icon: "🌈",
                        headline: "Different vibes for different people",
                        detail: "Your chats with \(morePositive.displayName) are \(Int(sentimentDiff * 100))% more positive",
                        category: .relationship
                    ))
                }
            }
        }
        
        return revelations
    }

    private func parseMLXRevelations(_ text: String) -> [AIRevelation] {
        var revelations: [AIRevelation] = []
        let entryPattern = "REVELATION \\d+:"
        
        // Simple line-based parser
        let lines = text.components(separatedBy: .newlines)
        var currentIcon = "✨"
        var currentHeadline = ""
        var currentDetail = ""
        var currentCategory: AIRevelation.RevealCategory = .pattern
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().starts(with: "icon:") {
                currentIcon = trimmed.replacingOccurrences(of: "Icon:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().starts(with: "headline:") {
                currentHeadline = trimmed.replacingOccurrences(of: "Headline:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().starts(with: "detail:") {
                currentDetail = trimmed.replacingOccurrences(of: "Detail:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().starts(with: "category:") {
                let catStr = trimmed.replacingOccurrences(of: "Category:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces).lowercased()
                if catStr.contains("relationship") { currentCategory = .relationship }
                else if catStr.contains("quirk") { currentCategory = .quirk }
                else { currentCategory = .pattern }
                
                // End of block, append if valid
                if !currentHeadline.isEmpty {
                    revelations.append(AIRevelation(
                        id: UUID(),
                        icon: currentIcon,
                        headline: currentHeadline,
                        detail: currentDetail,
                        category: currentCategory
                    ))
                    // Reset
                    currentIcon = "✨"
                    currentHeadline = ""
                    currentDetail = ""
                }
            }
        }
        
        return revelations
    }
    
    // MARK: - Helper Functions
    
    private func analyzeSentiment(_ text: String) async -> Double {
        sentimentTagger.string = text
        let (tag, _) = sentimentTagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return tag.flatMap { Double($0.rawValue) } ?? 0
    }
    
    private func analyzeSentiments(_ texts: [String]) async -> [Double] {
        var results: [Double] = []
        for text in texts.prefix(100) {  // Limit for performance
            results.append(await analyzeSentiment(text))
        }
        return results
    }
    
    private func extractLemmas(from text: String) -> [String] {
        var lemmas: [String] = []
        lemmaTagger.string = text
        
        lemmaTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma) { tag, range in
            if let lemma = tag?.rawValue {
                lemmas.append(lemma)
            } else {
                lemmas.append(String(text[range]))
            }
            return true
        }
        return lemmas
    }
    
    private func groupIntoConversations(_ messages: [Message]) -> [[Message]] {
        guard !messages.isEmpty else { return [] }
        
        let sorted = messages.sorted { $0.date < $1.date }
        var conversations: [[Message]] = []
        var currentConv: [Message] = [sorted[0]]
        
        for i in 1..<sorted.count {
            let gap = sorted[i].date.timeIntervalSince(sorted[i-1].date)
            if gap > 6 * 3600 {  // 6 hour gap = new conversation
                conversations.append(currentConv)
                currentConv = []
            }
            currentConv.append(sorted[i])
        }
        if !currentConv.isEmpty {
            conversations.append(currentConv)
        }
        
        return conversations
    }
    
    private func mode<T: Hashable>(of array: [T]) -> T? {
        var counts: [T: Int] = [:]
        for item in array {
            counts[item, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let sumSquaredDiffs = values.reduce(0) { $0 + pow($1 - mean, 2) }
        return sumSquaredDiffs / Double(values.count - 1)
    }
    
    private func calculateTrend(_ values: [Double]) -> CommunicationEvolution.TrendDirection {
        guard values.count >= 2 else { return .stable }
        let first = values.prefix(values.count / 2).reduce(0, +) / Double(max(values.count / 2, 1))
        let second = values.suffix(values.count / 2).reduce(0, +) / Double(max(values.count / 2, 1))
        let change = (second - first) / max(abs(first), 1)
        if change > 0.1 { return .increasing }
        if change < -0.1 { return .decreasing }
        return .stable
    }
    
    // Common words to filter out from topic analysis
    private let commonWords: Set<String> = [
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "i",
        "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
        "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
        "or", "an", "will", "my", "one", "all", "would", "there", "their", "what",
        "so", "up", "out", "if", "about", "who", "get", "which", "go", "me",
        "when", "make", "can", "like", "time", "no", "just", "him", "know", "take",
        "people", "into", "year", "your", "good", "some", "could", "them", "see", "other",
        "than", "then", "now", "look", "only", "come", "its", "over", "think", "also",
        "back", "after", "use", "two", "how", "our", "work", "first", "well", "way",
        "even", "new", "want", "because", "any", "these", "give", "day", "most", "us",
        "okay", "yeah", "yes", "got", "going", "really", "thing", "dont", "didnt", "cant",
        "thats", "were", "been", "being", "had", "has", "was", "are", "haha", "lol"
    ]
}

// MARK: - Character Extension

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}
