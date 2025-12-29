import SwiftUI

// MARK: - Conversation Deep Dive View

struct ConversationDeepDiveView: View {
    let contact: ContactStats
    let messages: [Message]
    let relationshipDynamics: RelationshipDynamics?
    @Environment(\.dismiss) private var dismiss
    @State private var appear = false
    
    // Computed properties for this contact's messages
    private var contactMessages: [Message] {
        messages.filter { $0.contactIdentifier == contact.identifier }
    }
    
    private var sentMessages: [Message] {
        contactMessages.filter { $0.isFromMe }
    }
    
    private var receivedMessages: [Message] {
        contactMessages.filter { !$0.isFromMe }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0F172A"), Color(hex: "1E1B4B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                    
                    // Quick Stats
                    quickStatsSection
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.spring(response: 0.6).delay(0.1), value: appear)
                    
                    // Vibe Check
                    vibeCheckSection
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.spring(response: 0.6).delay(0.2), value: appear)
                    
                    // When You Chat
                    temporalSection
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.spring(response: 0.6).delay(0.3), value: appear)
                    
                    // Emoji DNA
                    emojiSection
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.spring(response: 0.6).delay(0.4), value: appear)
                    
                    // Memorable Moments
                    memorableMomentsSection
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.spring(response: 0.6).delay(0.5), value: appear)
                    
                    Spacer(minLength: 40)
                }
                .padding(24)
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .padding(20)
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                appear = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text(contact.displayName.prefix(1).uppercased())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text(contact.displayName)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("\(contact.totalMessages) messages")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                // Relationship badge
                if let dynamics = relationshipDynamics {
                    Text(dynamics.connectionStrength)
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.1)))
                        .foregroundColor(.cyan)
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Stats", icon: "chart.bar.fill")
            
            HStack(spacing: 12) {
                QuickStatCard(
                    title: "You Sent",
                    value: "\(sentMessages.count)",
                    icon: "arrow.up.circle.fill",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "You Received",
                    value: "\(receivedMessages.count)",
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                QuickStatCard(
                    title: "Ratio",
                    value: ratioString,
                    icon: "percent",
                    color: .purple
                )
            }
        }
    }
    
    private var ratioString: String {
        let sent = Double(sentMessages.count)
        let received = Double(max(receivedMessages.count, 1))
        let ratio = sent / received
        if ratio > 1.2 {
            return "You talk more"
        } else if ratio < 0.8 {
            return "They talk more"
        } else {
            return "Balanced"
        }
    }
    
    // MARK: - Vibe Check Section
    
    private var vibeCheckSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Vibe Check", icon: "heart.fill")
            
            HStack(spacing: 16) {
                // Sentiment indicator
                VStack(spacing: 8) {
                    Text(vibeEmoji)
                        .font(.system(size: 50))
                    
                    Text(vibeLabel)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.05))
                )
                
                // Dynamic description
                VStack(alignment: .leading, spacing: 8) {
                    if let dynamics = relationshipDynamics {
                        VibeStat(label: "Dynamic", value: dynamics.dynamicLabel)
                        VibeStat(label: "Positive %", value: "\(Int(dynamics.positiveMessagePercent * 100))%")
                        VibeStat(label: "Peak Hour", value: formatHour(dynamics.peakHour))
                    } else {
                        VibeStat(label: "Messages/Day", value: String(format: "%.1f", messagesPerDay))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var vibeEmoji: String {
        if let dynamics = relationshipDynamics {
            if dynamics.positiveMessagePercent > 0.7 { return "😊" }
            if dynamics.positiveMessagePercent > 0.5 { return "🙂" }
            return "😐"
        }
        return "💬"
    }
    
    private var vibeLabel: String {
        if let dynamics = relationshipDynamics {
            if dynamics.positiveMessagePercent > 0.7 { return "Great Vibes" }
            if dynamics.positiveMessagePercent > 0.5 { return "Good Vibes" }
            return "Neutral"
        }
        return "Unknown"
    }
    
    private var messagesPerDay: Double {
        guard let first = contactMessages.first?.date,
              let last = contactMessages.last?.date else { return 0 }
        let days = max(1, Calendar.current.dateComponents([.day], from: last, to: first).day ?? 1)
        return Double(contactMessages.count) / Double(days)
    }
    
    // MARK: - Temporal Section
    
    private var temporalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "When You Chat", icon: "clock.fill")
            
            // Hourly heatmap
            VStack(alignment: .leading, spacing: 8) {
                Text("Hours of the Day")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                HourlyHeatmap(messages: contactMessages)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - Emoji Section
    
    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your Emoji DNA", icon: "face.smiling.fill")
            
            let topEmojis = getTopEmojis()
            
            if topEmojis.isEmpty {
                Text("No emojis found")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.05))
                    )
            } else {
                HStack(spacing: 12) {
                    ForEach(topEmojis.prefix(5), id: \.emoji) { item in
                        VStack(spacing: 6) {
                            Text(item.emoji)
                                .font(.system(size: 36))
                            Text("\(item.count)")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.05))
                        )
                    }
                }
            }
        }
    }
    
    private func getTopEmojis() -> [(emoji: String, count: Int)] {
        var emojiCounts: [String: Int] = [:]
        for message in sentMessages {
            guard let text = message.text else { continue }
            for char in text where char.isEmoji {
                emojiCounts[String(char), default: 0] += 1
            }
        }
        return emojiCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
    
    // MARK: - Memorable Moments Section
    
    private var memorableMomentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Memorable Moments", icon: "star.fill")
            
            VStack(spacing: 12) {
                if let busiestDay = getBusiestDay() {
                    MomentCard(
                        icon: "calendar.badge.exclamationmark",
                        title: "Busiest Day",
                        value: formatDate(busiestDay.date),
                        detail: "\(busiestDay.count) messages",
                        color: .orange
                    )
                }
                
                if let longestMessage = getLongestMessage() {
                    MomentCard(
                        icon: "text.alignleft",
                        title: "Longest Message",
                        value: "\(longestMessage.count) characters",
                        detail: String(longestMessage.prefix(50)) + "...",
                        color: .cyan
                    )
                }
                
                let lateNightCount = getLateNightCount()
                if lateNightCount > 0 {
                    MomentCard(
                        icon: "moon.stars.fill",
                        title: "Late Night Chats",
                        value: "\(lateNightCount) messages",
                        detail: "Between 10 PM and 2 AM",
                        color: .purple
                    )
                }
            }
        }
    }
    
    private func getBusiestDay() -> (date: Date, count: Int)? {
        var dailyCounts: [String: (date: Date, count: Int)] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for message in contactMessages {
            let key = formatter.string(from: message.date)
            let current = dailyCounts[key] ?? (date: message.date, count: 0)
            dailyCounts[key] = (date: current.date, count: current.count + 1)
        }
        
        return dailyCounts.values.max(by: { $0.count < $1.count })
    }
    
    private func getLongestMessage() -> String? {
        sentMessages.compactMap { $0.text }.max(by: { $0.count < $1.count })
    }
    
    private func getLateNightCount() -> Int {
        contactMessages.filter {
            let hour = Calendar.current.component(.hour, from: $0.date)
            return hour >= 22 || hour < 2
        }.count
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(from: DateComponents(hour: hour)) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing)
                )
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }
}

struct VibeStat: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }
}

struct MomentCard: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }
}

struct HourlyHeatmap: View {
    let messages: [Message]
    
    private var hourlyData: [Int: Int] {
        var counts: [Int: Int] = [:]
        for hour in 0..<24 {
            counts[hour] = 0
        }
        for message in messages {
            let hour = Calendar.current.component(.hour, from: message.date)
            counts[hour, default: 0] += 1
        }
        return counts
    }
    
    private var maxCount: Int {
        hourlyData.values.max() ?? 1
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<24, id: \.self) { hour in
                let count = hourlyData[hour] ?? 0
                let intensity = maxCount > 0 ? Double(count) / Double(maxCount) : 0
                
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(intensity), .purple.opacity(intensity)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    if hour % 6 == 0 {
                        Text("\(hour)")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
    }
}

// Character.isEmoji extension already defined in NovelInsightSlides.swift
