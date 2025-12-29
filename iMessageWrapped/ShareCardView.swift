import SwiftUI

// MARK: - Share Card Views

/// Main share card container with different themes
struct ShareCardView: View {
    let cardData: ShareCardData
    let insights: WrappedInsights
    
    var body: some View {
        Group {
            switch cardData.cardType {
            case .summary:
                SummaryCard(insights: insights)
            case .personality:
                PersonalityCard(dna: insights.communicationDNA)
            case .topFriends:
                TopFriendsCard(dynamics: Array(insights.relationshipDynamics.prefix(3)))
            case .emoji:
                EmojiCard(emojiData: insights.emojiDeepDive)
            case .vibe:
                VibeCard(insights: insights)
            }
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let insights: WrappedInsights
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.15, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "message.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .cyan], startPoint: .top, endPoint: .bottom)
                        )
                    Text("iMessage Wrapped")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                
                Spacer()
                
                // Main stats
                VStack(spacing: 24) {
                    StatRow(
                        icon: "💬",
                        value: formatNumber(insights.totalMessagesAnalyzed),
                        label: "Messages"
                    )
                    
                    if let topContact = insights.relationshipDynamics.first {
                        StatRow(
                            icon: "❤️",
                            value: (topContact.displayName.isEmpty || topContact.displayName == "Unknown") ? "Your #1 Contact" : topContact.displayName,
                            label: "#1 Contact"
                        )
                    }
                    
                    StatRow(
                        icon: insights.communicationDNA.personalityLabel.prefix(2).description,
                        value: String(insights.communicationDNA.personalityLabel.dropFirst(2)),
                        label: "Communication Style"
                    )
                    
                    if let topEmoji = insights.emojiDeepDive.topEmojis.first {
                        StatRow(
                            icon: topEmoji.emoji,
                            value: "×\(topEmoji.count)",
                            label: "Top Emoji"
                        )
                    }
                }
                
                Spacer()
                
                // Footer
                HStack {
                    Text("\(insights.timePeriodDays) days of messages")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text(String(Calendar.current.component(.year, from: Date())))
                        .font(.caption.bold())
                        .foregroundColor(.cyan)
                }
            }
            .padding(30)
        }
        .frame(width: 350, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}

struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.08))
        )
    }
}

// MARK: - Personality Card

struct PersonalityCard: View {
    let dna: CommunicationDNA
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.1, blue: 0.4),
                    Color(red: 0.1, green: 0.1, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 24) {
                // Header
                Text("My Communication DNA")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                // Main personality badge
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.8), .purple.opacity(0.2)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    VStack(spacing: 8) {
                        Text(dna.personalityLabel.prefix(2).description)
                            .font(.system(size: 50))
                        Text(String(dna.personalityLabel.dropFirst(2)))
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    DNAStatBadge(label: "Expressiveness", value: dna.expressiveness, color: .pink)
                    DNAStatBadge(label: "Formality", value: dna.formality, color: .cyan)
                    DNAStatBadge(label: "Question Ratio", value: dna.questionToStatementRatio, color: .orange)
                    DNAStatBadge(label: "Emoji Density", value: min(1, dna.emojiDensity / 10), color: .yellow)
                }
                
                // Punctuation style
                Text(dna.punctuationStyle.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white.opacity(0.15)))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("iMessage Wrapped \(String(Calendar.current.component(.year, from: Date())))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(30)
        }
        .frame(width: 350, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct DNAStatBadge: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(value * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Top Friends Card

struct TopFriendsCard: View {
    let dynamics: [RelationshipDynamics]
    
    private let podiumColors: [Color] = [.yellow, .gray, .orange]
    private let podiumEmojis = ["🥇", "🥈", "🥉"]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.15),
                    Color(red: 0.05, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 20) {
                Text("My Inner Circle")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                // Podium
                HStack(alignment: .bottom, spacing: 0) {
                    if dynamics.count > 1 {
                        PodiumEntry(
                            rank: 2,
                            contact: dynamics[1],
                            color: podiumColors[1],
                            emoji: podiumEmojis[1],
                            height: 100
                        )
                    }
                    
                    if !dynamics.isEmpty {
                        PodiumEntry(
                            rank: 1,
                            contact: dynamics[0],
                            color: podiumColors[0],
                            emoji: podiumEmojis[0],
                            height: 140
                        )
                    }
                    
                    if dynamics.count > 2 {
                        PodiumEntry(
                            rank: 3,
                            contact: dynamics[2],
                            color: podiumColors[2],
                            emoji: podiumEmojis[2],
                            height: 80
                        )
                    }
                }
                
                Spacer()
                
                Text("iMessage Wrapped \(String(Calendar.current.component(.year, from: Date())))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(30)
        }
        .frame(width: 350, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct PodiumEntry: View {
    let rank: Int
    let contact: RelationshipDynamics
    let color: Color
    let emoji: String
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 40))
            
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [color.opacity(0.8), color.opacity(0.4)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 60, height: 60)
                
                Text(String(contact.displayName.prefix(1)).uppercased())
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            Text(contact.displayName)
                .font(.caption.bold())
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(contact.totalMessages) msgs")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
            // Podium block
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.3))
                .frame(height: height)
                .overlay(
                    Text("\(rank)")
                        .font(.title.bold())
                        .foregroundColor(color)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Emoji Card

struct EmojiCard: View {
    let emojiData: EmojiDeepDive
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.2, blue: 0.1),
                    Color(red: 0.15, green: 0.1, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 20) {
                Text("My Emoji Story")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                // Big top emoji
                if let topEmoji = emojiData.topEmojis.first {
                    VStack(spacing: 8) {
                        Text(topEmoji.emoji)
                            .font(.system(size: 80))
                        Text("Used \(topEmoji.count) times")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        Text(topEmoji.meaning)
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 40)
                
                // Top 5 grid
                HStack(spacing: 16) {
                    ForEach(emojiData.topEmojis.prefix(5)) { emoji in
                        VStack(spacing: 4) {
                            Text(emoji.emoji)
                                .font(.title)
                            Text("×\(emoji.count)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                // Stats
                HStack(spacing: 24) {
                    VStack {
                        Text("\(emojiData.totalEmojiCount)")
                            .font(.title3.bold())
                            .foregroundColor(.yellow)
                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    VStack {
                        Text("\(emojiData.uniqueEmojiCount)")
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                        Text("Unique")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    VStack {
                        Text("\(Int(emojiData.emojiPercentOfMessages))%")
                            .font(.title3.bold())
                            .foregroundColor(.pink)
                        Text("of msgs")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                Text("iMessage Wrapped \(String(Calendar.current.component(.year, from: Date())))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(30)
        }
        .frame(width: 350, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Vibe Card

struct VibeCard: View {
    let insights: WrappedInsights
    
    var body: some View {
        ZStack {
            // Dynamic gradient based on sentiment
            LinearGradient(
                colors: vibeGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 24) {
                Text("My Vibe Check")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                // Big vibe emoji
                Text(vibeEmoji)
                    .font(.system(size: 100))
                
                Text(vibeLabel)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(vibeDescription)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Sentiment meter
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(colors: [.red, .yellow, .green],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: geo.size.width * meterPosition)
                        }
                    }
                    .frame(height: 16)
                    
                    HStack {
                        Text("😢")
                        Spacer()
                        Text("😐")
                        Spacer()
                        Text("😊")
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Text("iMessage Wrapped \(String(Calendar.current.component(.year, from: Date())))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(30)
        }
        .frame(width: 350, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var sentimentScore: Double {
        insights.sentimentScore
    }
    
    private var meterPosition: Double {
        (sentimentScore + 1) / 2  // Convert -1...1 to 0...1
    }
    
    private var vibeEmoji: String {
        switch sentimentScore {
        case 0.5...: return "🌟"
        case 0.2..<0.5: return "😊"
        case -0.2..<0.2: return "😌"
        case -0.5..<(-0.2): return "😔"
        default: return "🌧️"
        }
    }
    
    private var vibeLabel: String {
        switch sentimentScore {
        case 0.5...: return "Radiating Positivity"
        case 0.2..<0.5: return "Good Vibes"
        case -0.2..<0.2: return "Balanced & Grounded"
        case -0.5..<(-0.2): return "Keeping It Real"
        default: return "In the Trenches"
        }
    }
    
    private var vibeDescription: String {
        switch sentimentScore {
        case 0.5...: return "Your conversations overflow with positive energy!"
        case 0.2..<0.5: return "You bring warmth and optimism to your chats"
        case -0.2..<0.2: return "You keep conversations balanced and pragmatic"
        case -0.5..<(-0.2): return "You're not afraid to have real conversations"
        default: return "You've been through it, but you're still here"
        }
    }
    
    private var vibeGradient: [Color] {
        switch sentimentScore {
        case 0.5...: return [Color(red: 0.2, green: 0.4, blue: 0.2), Color(red: 0.1, green: 0.3, blue: 0.3)]
        case 0.2..<0.5: return [Color(red: 0.2, green: 0.3, blue: 0.2), Color(red: 0.15, green: 0.2, blue: 0.3)]
        case -0.2..<0.2: return [Color(red: 0.2, green: 0.2, blue: 0.25), Color(red: 0.15, green: 0.15, blue: 0.25)]
        default: return [Color(red: 0.25, green: 0.15, blue: 0.2), Color(red: 0.2, green: 0.1, blue: 0.2)]
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleDNA = CommunicationDNA(
        averageMessageLength: 45,
        questionToStatementRatio: 0.3,
        emojiDensity: 3.5,
        avgResponseTimeMinutes: 15,
        punctuationStyle: .exclamationEnthusiast,
        expressiveness: 0.7,
        formality: 0.4,
        vocabularyComplexity: "Standard"
    )
    
    PersonalityCard(dna: sampleDNA)
}
