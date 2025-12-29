import SwiftUI

// MARK: - Insights Chat View

/// Rule-based chat interface where users select from pre-populated options
/// No typing - users navigate through topics by tapping response options
struct InsightsChatView: View {
    let insights: WrappedInsights
    let messages: [Message]
    
    @State private var chatMessages: [ChatMessage] = []
    @State private var currentOptions: [ChatOption] = []
    @State private var conversationPath: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            chatHeader
            
            Divider().background(Color.white.opacity(0.1))
            
            // Messages and options
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Welcome section at start
                        if chatMessages.isEmpty {
                            welcomeSection
                        }
                        
                        // Chat messages
                        ForEach(chatMessages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Current options (only shown after initial message or response)
                        if !currentOptions.isEmpty {
                            optionsSection
                                .id("options")
                        }
                    }
                    .padding()
                }
                .onChange(of: chatMessages.count) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo("options", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color(hex: "0F0F23"))
        .onAppear {
            // Initialize with welcome options
            currentOptions = getInitialOptions()
        }
    }
    
    // MARK: - Header
    
    private var chatHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "sparkles")
                    .foregroundColor(.white)
                    .font(.body.bold())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Message Insights")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Tap a topic to explore")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Reset button
            if !chatMessages.isEmpty {
                Button(action: resetChat) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
    
    // MARK: - Welcome Section
    
    private var welcomeSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Explore Your Message Insights")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("I've analyzed \(insights.totalMessagesAnalyzed) messages from \(insights.timePeriodDays) days")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 30)
            .padding(.bottom, 10)
            
            Text("TAP A TOPIC TO START")
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 10)
        }
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(currentOptions) { option in
                OptionChip(option: option) {
                    handleOptionSelected(option)
                }
            }
        }
    }
    
    // MARK: - Option Selection Handler
    
    private func handleOptionSelected(_ option: ChatOption) {
        // Add user's selection as a message
        let userMessage = ChatMessage(role: .user, content: option.displayText)
        chatMessages.append(userMessage)
        
        // Track path
        conversationPath.append(option.id)
        
        // Generate response
        let response = generateResponse(for: option)
        let assistantMessage = ChatMessage(role: .assistant, content: response)
        chatMessages.append(assistantMessage)
        
        // Get follow-up options
        currentOptions = getFollowUpOptions(for: option)
    }
    
    // MARK: - Initial Options
    
    private func getInitialOptions() -> [ChatOption] {
        var options: [ChatOption] = []
        
        // Ride or Die (Best Friend)
        options.append(ChatOption(
            id: "ride_or_die",
            displayText: "Who is my 'ride or die'?",
            icon: "heart.fill",
            category: .relationship
        ))
        
        // Ghosting
        if !insights.connectionPatterns.ghostingEvents.isEmpty {
            options.append(ChatOption(
                id: "ghosting_truth",
                displayText: "Do I ghost people?",
                icon: "wind",
                category: .relationship
            ))
        }
        
        // Roast
        options.append(ChatOption(
            id: "roast_me",
            displayText: "Roast my texting style 🌶️",
            icon: "flame.fill",
            category: .roast
        ))
        
        // Best Side
        if insights.relationshipDynamics.count > 0 {
            options.append(ChatOption(
                id: "best_side",
                displayText: "Who brings out my best side?",
                icon: "sparkles",
                category: .relationship
            ))
        }
        
        // Dry Texter
        options.append(ChatOption(
            id: "dry_texter",
            displayText: "Am I a dry texter?",
            icon: "drop.triangle.fill",
            category: .personality
        ))
        
        // Random Fun Fact fallback
        options.append(ChatOption(
            id: "fun_fact",
            displayText: "Give me a random fun fact",
            icon: "dice.fill",
            category: .funFact
        ))
        
        return options
    }
    
    // MARK: - Follow-up Options
    
    private func getFollowUpOptions(for option: ChatOption) -> [ChatOption] {
        switch option.category {
        case .relationship:
            return getRelationshipFollowUps(currentId: option.id)
        case .emoji:
            return getEmojiFollowUps()
        case .personality:
            return getPersonalityFollowUps()
        case .temporal:
            return getTemporalFollowUps()
        case .funFact:
            return getFunFactFollowUps()
        case .roast:
            return getRoastFollowUps()
        case .general:
            return getInitialOptions()
        }
    }
    
    private func getRelationshipFollowUps(currentId: String) -> [ChatOption] {
        var options: [ChatOption] = []
        
        if currentId == "ride_or_die" {
             options.append(ChatOption(
                id: "best_side",
                displayText: "Who brings out my best side?",
                icon: "sparkles",
                category: .relationship
            ))
        } else if currentId == "ghosting_truth" {
            options.append(ChatOption(
                id: "who_ghosts_me",
                displayText: "Wait, do people ghost ME?",
                icon: "wind",
                category: .relationship
            ))
        }
        
        options.append(ChatOption(
            id: "roast_me",
            displayText: "Roast my texting style 🌶️",
            icon: "flame.fill",
            category: .roast
        ))
        
        options.append(ChatOption(
            id: "fun_fact",
            displayText: "Tell me something else!",
            icon: "sparkles",
            category: .funFact
        ))
        
        return options
    }
    
    private func getEmojiFollowUps() -> [ChatOption] {
        var options: [ChatOption] = []
        
        if let topEmoji = insights.emojiDeepDive.topEmojis.first {
            options.append(ChatOption(
                id: "emoji_meaning",
                displayText: "Why do I use \(topEmoji.emoji) so much?",
                icon: "questionmark.circle",
                category: .emoji
            ))
        }
        
        if insights.emojiDeepDive.emojiCombos.count > 0 {
            options.append(ChatOption(
                id: "emoji_combos",
                displayText: "What emoji combos do I use?",
                icon: "plus.circle",
                category: .emoji
            ))
        }
        
        options.append(ChatOption(
            id: "personality",
            displayText: "What's my texting personality?",
            icon: "person.text.rectangle",
            category: .personality
        ))
        
        options.append(ChatOption(
            id: "another_fact",
            displayText: "Give me another insight!",
            icon: "sparkles",
            category: .funFact
        ))
        
        return options
    }
    
    private func getPersonalityFollowUps() -> [ChatOption] {
        var options: [ChatOption] = []
        
        options.append(ChatOption(
            id: "roast_me",
            displayText: "Roast me instead!",
            icon: "flame.fill",
            category: .roast
        ))
        
        options.append(ChatOption(
            id: "ride_or_die",
            displayText: "Who is my ride or die?",
            icon: "heart.fill",
            category: .relationship
        ))
        
        options.append(ChatOption(
            id: "another_fact",
            displayText: "Give me another fact",
            icon: "dice",
            category: .funFact
        ))
        
        return options
    }
    
    private func getTemporalFollowUps() -> [ChatOption] {
        var options: [ChatOption] = []
        
        options.append(ChatOption(
            id: "night_owl",
            displayText: "Am I a night owl?",
            icon: "moon.fill",
            category: .temporal
        ))
        
        options.append(ChatOption(
            id: "weekend_vs_weekday",
            displayText: "Weekend vs weekday texting?",
            icon: "calendar",
            category: .temporal
        ))
        
        options.append(ChatOption(
            id: "emoji_stats",
            displayText: "Show me emoji stats",
            icon: "face.smiling",
            category: .emoji
        ))
        
        options.append(ChatOption(
            id: "another_fact",
            displayText: "Another fun insight!",
            icon: "sparkles",
            category: .funFact
        ))
        
        return options
    }
    
    private func getRoastFollowUps() -> [ChatOption] {
        var options: [ChatOption] = []
        
        options.append(ChatOption(
            id: "best_side",
            displayText: "Okay that hurt. Say something nice.",
            icon: "bandage.fill",
            category: .relationship
        ))
        
        options.append(ChatOption(
            id: "ghosting_truth",
            displayText: "Do I ghost people?",
            icon: "wind",
            category: .relationship
        ))
        
        options.append(ChatOption(
            id: "fun_fact",
            displayText: "New topic please!",
            icon: "arrow.clockwise",
            category: .funFact
        ))
        
        return options
    }
    
    private func getFunFactFollowUps() -> [ChatOption] {
        var options: [ChatOption] = []
        
        options.append(ChatOption(
            id: "another_fact",
            displayText: "Tell me another one!",
            icon: "sparkles",
            category: .funFact
        ))
        
        options.append(ChatOption(
            id: "roast_me",
            displayText: "Okay, enough facts. Roast me!",
            icon: "flame.fill",
            category: .roast
        ))
        
        options.append(ChatOption(
            id: "ride_or_die",
            displayText: "Who is my #1 person?",
            icon: "heart.fill",
            category: .relationship
        ))
        
        return options
    }
    
    // MARK: - Response Generator
    
    private func generateResponse(for option: ChatOption) -> String {
        switch option.id {
        case "ride_or_die":
            return generateRideOrDieResponse()
        case "ghosting_truth":
            return generateGhostingResponse()
        case "who_ghosts_me":
             return generateWhoGhostsMeResponse()
        case "roast_me":
            return generateRoastResponse()
        case "best_side":
            return generateBestSideResponse()
        case "dry_texter":
            return generateDryTexterResponse()
        case "fun_fact", "another_fact":
            return generateRandomFunFact()
        default:
            return generateRandomFunFact()
        }
    }
    
    private func generateTopContactResponse() -> String {
        guard let top = insights.relationshipDynamics.first else {
            return "I couldn't find enough data about your contacts!"
        }
        
        let sentiment = top.averageSentiment > 0.3 ? "positive and warm" : "genuine and comfortable"
        let initiative = top.initiativeScore > 0.3 ? "You're usually the one starting conversations!" : "They often reach out to you first."
        
        return "Your connection with \(top.displayName) is really special! 💫\n\nWith \(top.totalMessages) messages exchanged, you've built a \(sentiment) communication dynamic. \(initiative)\n\nYour peak chatting time together is around \(top.peakHour):00."
    }
    
    private func generateCompareResponse() -> String {
        guard insights.relationshipDynamics.count >= 2 else {
            return "Not enough contacts to compare!"
        }
        
        let first = insights.relationshipDynamics[0]
        let second = insights.relationshipDynamics[1]
        
        let sentimentDiff = first.averageSentiment - second.averageSentiment
        let morePositive = sentimentDiff > 0 ? first.displayName : second.displayName
        
        return "Comparing your top 2 connections:\n\n• \(first.displayName): \(first.totalMessages) messages\n• \(second.displayName): \(second.totalMessages) messages\n\nYour chats with \(morePositive) tend to be slightly more positive! 🌈"
    }
    
    private func generatePeakTimeResponse() -> String {
        guard let top = insights.relationshipDynamics.first else {
            return "No timing data available!"
        }
        
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let peakDay = dayNames[top.peakDayOfWeek]
        
        return "You and \(top.displayName) are most active around \(top.peakHour):00 ⏰\n\nYour peak day together is \(peakDay)! Average conversation length: \(Int(top.averageThreadLength)) messages."
    }
    
    private func generateEmojiStatsResponse() -> String {
        let emojiData = insights.emojiDeepDive
        
        guard let topEmoji = emojiData.topEmojis.first else {
            return "You don't seem to use many emojis! 🤔"
        }
        
        return "Your emoji personality revealed! 🎭\n\nYour signature emoji is \(topEmoji.emoji) — you've used it \(topEmoji.count) times!\n\nTotal emojis used: \(emojiData.totalEmojiCount)\nUnique emojis: \(emojiData.uniqueEmojiCount)\nEmoji rate: \(String(format: "%.0f", emojiData.emojiPercentOfMessages))% of messages have emojis"
    }
    
    private func generateEmojiMeaningResponse() -> String {
        guard let topEmoji = insights.emojiDeepDive.topEmojis.first else {
            return "No top emoji found!"
        }
        
        let meaning: String
        switch topEmoji.emoji {
        case "😂": meaning = "You love to laugh! Your conversations are full of humor and joy."
        case "❤️", "🥰", "😍": meaning = "You're very expressive with love and affection!"
        case "😭": meaning = "You're not afraid to show emotion — either laughing so hard you cry or expressing dramatic feelings!"
        case "🔥": meaning = "You keep it lit! You're enthusiastic about what's happening."
        case "👍": meaning = "You're agreeable and supportive in conversations."
        case "🙏": meaning = "You express gratitude and sincerity often."
        default: meaning = "This emoji perfectly captures your unique communication style!"
        }
        
        return "\(topEmoji.emoji) is your go-to!\n\n\(meaning)\n\nYou've used it \(topEmoji.count) times — that's \(String(format: "%.1f", topEmoji.percentOfTotal))% of all your emojis!"
    }
    
    private func generateEmojiCombosResponse() -> String {
        let combos = insights.emojiDeepDive.emojiCombos
        guard !combos.isEmpty else {
            return "No common emoji combos found!"
        }
        
        var response = "Your favorite emoji combos:\n\n"
        for combo in combos.prefix(3) {
            response += "• \(combo.combo) — used \(combo.count) times\n"
        }
        
        return response + "\nThese combos add extra emphasis to your messages! ✨"
    }
    
    private func generatePersonalityResponse() -> String {
        let dna = insights.communicationDNA
        
        var traits: [String] = []
        
        if dna.averageMessageLength > 100 {
            traits.append("📖 Storyteller — you write detailed, expressive messages")
        } else if dna.averageMessageLength < 30 {
            traits.append("⚡ Quick Communicator — you keep it brief and punchy")
        }
        
        if dna.questionToStatementRatio > 0.3 {
            traits.append("🤔 Curious Mind — you love asking questions")
        }
        
        if dna.emojiDensity > 3 {
            traits.append("🎨 Emoji Artist — you express yourself with emojis")
        }
        
        switch dna.punctuationStyle {
        case .exclamationEnthusiast:
            traits.append("🎉 Enthusiast — you use lots of exclamation marks!")
        case .ellipsisLover:
            traits.append("💭 Thoughtful — you use ellipses for dramatic effect...")
        default:
            break
        }
        
        if traits.isEmpty {
            traits.append("✨ Balanced Communicator — you adapt to each conversation")
        }
        
        return "Your texting DNA:\n\n" + traits.joined(separator: "\n") + "\n\nFormality: \(Int(dna.formality * 100))% | Expressiveness: \(Int(dna.expressiveness * 100))%"
    }
    
    private func generateMessageLengthResponse() -> String {
        let avgLength = insights.communicationDNA.averageMessageLength
        
        let comparison: String
        if avgLength > 100 {
            comparison = "You write novels! Your messages are detailed and thorough."
        } else if avgLength > 50 {
            comparison = "You're a balanced texter — not too short, not too long."
        } else if avgLength > 20 {
            comparison = "Quick and to the point! You value efficiency."
        } else {
            comparison = "Ultra-brief! You're the master of short replies."
        }
        
        return "Your average message is \(Int(avgLength)) characters long.\n\n\(comparison) ✍️"
    }
    
    private func generateQuestionStyleResponse() -> String {
        let questionRatio = insights.communicationDNA.questionToStatementRatio
        let percentage = Int(questionRatio * 100)
        
        let style: String
        if questionRatio > 0.4 {
            style = "You're very inquisitive! You love to learn and understand others."
        } else if questionRatio > 0.2 {
            style = "You balance questions with statements nicely."
        } else {
            style = "You're more of a statement person — you share rather than ask."
        }
        
        return "\(percentage)% of your messages contain questions.\n\n\(style) 🤔"
    }
    
    private func generateTimePatternResponse() -> String {
        let temporal = insights.temporalFingerprint
        
        let chronotype: String
        if temporal.nightOwlScore > 0.6 {
            chronotype = "🦉 Night Owl — you come alive after dark!"
        } else if temporal.earlyBirdScore > 0.6 {
            chronotype = "🌅 Early Bird — you're up and texting early!"
        } else {
            chronotype = "⏰ Steady Texter — you message throughout the day"
        }
        
        let workHours = Int(temporal.workHoursPercent * 100)
        
        return "Your texting rhythm:\n\n\(chronotype)\n\n\(workHours)% of messages during work hours (9-5)\nWeekend activity: \(temporal.weekendVsWeekdayRatio > 1.2 ? "More active" : "About the same") as weekdays"
    }
    
    private func generateNightOwlResponse() -> String {
        let temporal = insights.temporalFingerprint
        
        if temporal.nightOwlScore > 0.6 {
            return "Yes, you're definitely a night owl! 🦉\n\nAbout \(Int(temporal.nightOwlScore * 100))% of your late-night activity suggests you thrive after 10pm.\n\nYour inferred sleep time starts around \(temporal.inferredSleepStart):00."
        } else if temporal.earlyBirdScore > 0.6 {
            return "Actually, you're more of an early bird! 🌅\n\nYou're most active in the morning hours. Night texting isn't really your thing."
        } else {
            return "You're somewhere in between! 🌗\n\nYou text throughout the day without a strong preference for early or late hours."
        }
    }
    
    private func generateWeekendResponse() -> String {
        let temporal = insights.temporalFingerprint
        let ratio = temporal.weekendVsWeekdayRatio
        
        let comparison: String
        if ratio > 1.5 {
            comparison = "You're way more active on weekends! Maybe you're busy during the week."
        } else if ratio > 1.1 {
            comparison = "Slightly more active on weekends — you enjoy that free time."
        } else if ratio > 0.9 {
            comparison = "Pretty consistent throughout the week!"
        } else {
            comparison = "You're actually more active during weekdays — work from home maybe?"
        }
        
        return "Weekend vs Weekday:\n\n\(comparison)\n\nRatio: \(String(format: "%.1fx", ratio)) weekend activity 📅"
    }
    
    private func generateRideOrDieResponse() -> String {
        guard let top = insights.relationshipDynamics.first else {
            return "I need more data to find your ride or die!"
        }
        
        return "🏆 **\(top.displayName)** is your certified Ride or Die.\n\nYou've exchanged **\(top.totalMessages)** messages with them!\n\nThat's \(String(format: "%.0f", top.positiveMessagePercent * 100))% good vibes and a whole lot of history. You reply to each other's messages consistently, making this your strongest connection by far. 💕"
    }
    
    private func generateGhostingResponse() -> String {
        let ghosts = insights.connectionPatterns.ghostingEvents.filter { $0.whoGhosted == .you }
        
        if ghosts.isEmpty {
            return "😇 You're an angel! You rarely leave people on read for long. Your response game is strong."
        } else {
            let topGhost = ghosts.sorted { $0.gapDays > $1.gapDays }.first!
            return "😬 Okay, don't shoot the messenger...\n\nYou left **\(topGhost.displayName)** waiting for **\(topGhost.gapDays) days**! \n\nWe all get busy, but that's a long time to leave someone on read! 👻"
        }
    }
    
    private func generateWhoGhostsMeResponse() -> String {
        let ghosts = insights.connectionPatterns.ghostingEvents.filter { $0.whoGhosted == .them }
        
        if ghosts.isEmpty {
            return "You're lucky! No one has seriously ghosted you recently. Everyone wants to talk to you! 🌟"
        } else {
            let topGhost = ghosts.sorted { $0.gapDays > $1.gapDays }.first!
            return "📉 looking at the data...\n\n**\(topGhost.displayName)** went silent for **\(topGhost.gapDays) days**.\n\nMaybe they were just really, really busy? Or they lost their phone? Let's go with that. 😅"
        }
    }
    
    private func generateRoastResponse() -> String {
        let dna = insights.communicationDNA
        var parts: [String] = []
        
        if dna.averageMessageLength > 100 {
            parts.append("You write essays, not texts. TL;DR is your worst enemy.")
        } else if dna.averageMessageLength < 20 {
            parts.append("Your vocabulary seems limited to 'ok', 'lol', and 'u up?'.")
        }
        
        if dna.emojiDensity > 5 {
             parts.append("You use so many emojis I need a hieroglyphics translator to understand you.")
        }
        
        if dna.questionToStatementRatio > 0.4 {
             parts.append("You ask so many questions. Are you conducting an interrogation? 🕵️")
        }
        
        if parts.isEmpty {
             parts.append("You're actually pretty balanced, which is... boring. Spice it up! 🧂")
        }
        
        return "🔥 **Roast Incoming:**\n\n" + parts.joined(separator: "\n\n")
    }
    
    private func generateBestSideResponse() -> String {
        guard let bestie = insights.relationshipDynamics.max(by: { $0.averageSentiment < $1.averageSentiment }) else {
            return "I need more charts to see who brings out your best side!"
        }
        
        return "✨ **\(bestie.displayName)** brings out the best in you.\n\nYour messages to them are **\(String(format: "%.0f", bestie.averageSentiment * 100))% more positive** than your average.\n\nKeep them close—they're good for your vibes! 🌈"
    }
    
    private func generateDryTexterResponse() -> String {
         let score = insights.communicationDNA.expressiveness
         
         if score < 0.3 {
             return "🌵 Hate to break it to you, but... yeah.\n\nLow emoji usage, short messages, lack of exclamation marks.\n\nIt's giving 'corporate email' energy. Try a GIF once in a while! 😉"
         } else if score > 0.7 {
             return "🌊 Not at all! You're overflowing with personality!\n\nEmojis, caps, punctuation—you use it all. No dryness here! 💦"
         } else {
             return "💧 You're hydrated, but not drowning.\n\nYou have your dry moments, but you generally keep it engaging enough."
         }
    }
    
    // MARK: - Legacy / Helper Generators
    
    private func generateRandomFunFact() -> String {
        let funFacts = [
            generateTopContactFact(),
            generateEmojiFact(),
            generateMessageFact(),
            generateTimeFact()
        ].compactMap { $0 }
        
        return funFacts.randomElement() ?? "You've exchanged \(insights.totalMessagesAnalyzed) messages in \(insights.timePeriodDays) days!"
    }
    
    private func generateTopContactFact() -> String? {
        guard let top = insights.relationshipDynamics.first else { return nil }
        return "Fun fact: You and \(top.displayName) have exchanged \(top.totalMessages) messages! That's your #1 connection. 💬"
    }
    
    private func generateEmojiFact() -> String? {
        guard let emoji = insights.emojiDeepDive.topEmojis.first else { return nil }
        return "Fun fact: You've used \(emoji.emoji) exactly \(emoji.count) times! If each use took 1 second, that's \(emoji.count / 60) minutes of just that emoji! 😄"
    }
    
    private func generateMessageFact() -> String? {
        let perDay = insights.totalMessagesAnalyzed / max(insights.timePeriodDays, 1)
        return "Fun fact: You send about \(perDay) messages per day! That's \(perDay * 7) per week and roughly \(perDay * 30) per month! 📊"
    }
    
    private func generateTimeFact() -> String? {
        let temporal = insights.temporalFingerprint
        if temporal.nightOwlScore > temporal.earlyBirdScore {
            return "Fun fact: You're a night owl! 🦉 Most of your messages are sent late in the evening."
        } else {
            return "Fun fact: You're an early bird! 🌅 You're most active during morning hours."
        }
    }
        
    private func resetChat() {
        chatMessages = []
        conversationPath = []
        currentOptions = getInitialOptions()
    }
}

// MARK: - Chat Option Model

struct ChatOption: Identifiable {
    let id: String
    let displayText: String
    let icon: String
    let category: OptionCategory
    
    enum OptionCategory {
        case relationship
        case emoji
        case personality
        case temporal
        case funFact
        case general
        case roast
    }
}

// MARK: - Option Chip

struct OptionChip: View {
    let option: ChatOption
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: option.icon)
                    .font(.subheadline)
                    .foregroundColor(.cyan)
                    .frame(width: 24)
                
                Text(option.displayText)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cyan.opacity(isHovered ? 0.3 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()
    
    enum Role {
        case user
        case assistant
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    message.role == .user
                    ? LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .cornerRadius(20)
                .frame(maxWidth: 300, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant { Spacer() }
        }
    }
}

// MARK: - Preview

#Preview("Insights Chat") {
    InsightsChatView(
        insights: .preview,
        messages: []
    )
    .frame(width: 500, height: 700)
}
