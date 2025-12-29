import Foundation

struct MessageAnalytics {
    let timePeriodDays: Int
    let totalMessages: Int
    let messagesSent: Int
    let messagesReceived: Int
    let topContacts: [ContactStats]
    let hourlyDistribution: [Int: Int]
    let weekdayDistribution: [Int: Int]
    let topEmojis: [(emoji: String, count: Int)]
    let averageMessageLength: Double
    let longestMessage: String?
    let totalCharacters: Int
    let attachmentCount: Int
    let messagesPerDay: Double
    let busiestDay: (date: Date, count: Int)?
    let busiestHour: Int?
    let lateNightMessages: Int
    let earlyMorningMessages: Int
    let weekendMessages: Int
    let weekdayMessages: Int
    var aiNarrative: YearInReviewNarrative? = nil
    var sentimentScore: Double = 0.0
    var sentimentDescription: String = "Neutral"
    
    init(messages: [Message], days: Int) {
        self.timePeriodDays = days
        self.totalMessages = messages.count
        self.messagesSent = messages.filter { $0.isFromMe }.count
        self.messagesReceived = messages.filter { !$0.isFromMe }.count
        
        // Top contacts
        var contactCounts: [String: (sent: Int, received: Int, lastMessage: Date)] = [:]
        for message in messages {
            let contact = message.contactIdentifier
            
            // Filter out unknown contacts
            if contact == "Unknown" || contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            
            let current = contactCounts[contact] ?? (sent: 0, received: 0, lastMessage: message.date)
            if message.isFromMe {
                contactCounts[contact] = (sent: current.sent + 1, received: current.received, lastMessage: max(current.lastMessage, message.date))
            } else {
                contactCounts[contact] = (sent: current.sent, received: current.received + 1, lastMessage: max(current.lastMessage, message.date))
            }
        }
        
        self.topContacts = contactCounts.map { (contact, stats) in
            ContactStats(
                identifier: contact,
                displayName: MessageAnalytics.formatContactName(contact),
                messagesSent: stats.sent,
                messagesReceived: stats.received,
                lastMessage: stats.lastMessage
            )
        }
        .sorted { ($0.messagesSent + $0.messagesReceived) > ($1.messagesSent + $1.messagesReceived) }
        .prefix(10)
        .map { $0 }
        
        // Hourly distribution
        var hourly: [Int: Int] = [:]
        for hour in 0..<24 {
            hourly[hour] = 0
        }
        for message in messages {
            let hour = Calendar.current.component(.hour, from: message.date)
            hourly[hour, default: 0] += 1
        }
        self.hourlyDistribution = hourly
        
        // Weekday distribution
        var weekday: [Int: Int] = [:]
        for day in 1...7 {
            weekday[day] = 0
        }
        for message in messages {
            let day = Calendar.current.component(.weekday, from: message.date)
            weekday[day, default: 0] += 1
        }
        self.weekdayDistribution = weekday
        
        // Emoji analysis
        var emojiCounts: [String: Int] = [:]
        for message in messages {
            guard let text = message.text else { continue }
            for char in text {
                if char.isEmoji {
                    emojiCounts[String(char), default: 0] += 1
                }
            }
        }
        self.topEmojis = emojiCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { ($0.key, $0.value) }
        
        // Message length stats
        let textsWithContent = messages.compactMap { $0.text }.filter { !$0.isEmpty }
        let totalChars = textsWithContent.reduce(0) { $0 + $1.count }
        self.totalCharacters = totalChars
        self.averageMessageLength = textsWithContent.isEmpty ? 0 : Double(totalChars) / Double(textsWithContent.count)
        self.longestMessage = textsWithContent.max(by: { $0.count < $1.count })
        
        // Attachments
        self.attachmentCount = messages.filter { $0.hasAttachments }.count
        
        // Messages per day
        self.messagesPerDay = days > 0 ? Double(messages.count) / Double(days) : 0
        
        // Busiest day
        var dailyCounts: [String: (date: Date, count: Int)] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for message in messages {
            let key = dateFormatter.string(from: message.date)
            let current = dailyCounts[key] ?? (date: message.date, count: 0)
            dailyCounts[key] = (date: current.date, count: current.count + 1)
        }
        self.busiestDay = dailyCounts.values.max(by: { $0.count < $1.count })
        
        // Busiest hour
        self.busiestHour = hourly.max(by: { $0.value < $1.value })?.key
        
        // Time-based categorization
        self.lateNightMessages = messages.filter {
            let hour = Calendar.current.component(.hour, from: $0.date)
            return hour >= 22 || hour < 2
        }.count
        
        self.earlyMorningMessages = messages.filter {
            let hour = Calendar.current.component(.hour, from: $0.date)
            return hour >= 5 && hour < 8
        }.count
        
        let weekendDays: Set<Int> = [1, 7] // Sunday = 1, Saturday = 7
        self.weekendMessages = messages.filter {
            let weekday = Calendar.current.component(.weekday, from: $0.date)
            return weekendDays.contains(weekday)
        }.count
        
        self.weekdayMessages = totalMessages - weekendMessages
    }
    
    static func formatContactName(_ identifier: String) -> String {
        // Format phone numbers nicely
        if identifier.hasPrefix("+") || identifier.allSatisfy({ $0.isNumber || $0 == "+" || $0 == "-" || $0 == " " || $0 == "(" || $0 == ")" }) {
            let digits = identifier.filter { $0.isNumber }
            if digits.count == 10 {
                let areaCode = digits.prefix(3)
                let middle = digits.dropFirst(3).prefix(3)
                let last = digits.suffix(4)
                return "(\(areaCode)) \(middle)-\(last)"
            } else if digits.count == 11 && digits.first == "1" {
                let remaining = digits.dropFirst()
                let areaCode = remaining.prefix(3)
                let middle = remaining.dropFirst(3).prefix(3)
                let last = remaining.suffix(4)
                return "+1 (\(areaCode)) \(middle)-\(last)"
            }
        }
        return identifier
    }
    
    var personalityType: String {
        if lateNightMessages > totalMessages / 4 {
            return "🦉 Night Owl"
        } else if earlyMorningMessages > totalMessages / 5 {
            return "🌅 Early Bird"
        } else if weekendMessages > weekdayMessages {
            return "🎉 Weekend Warrior"
        } else if Double(messagesSent) / Double(max(1, messagesReceived)) > 1.5 {
            return "💬 Conversation Starter"
        } else if Double(messagesReceived) / Double(max(1, messagesSent)) > 1.5 {
            return "👂 Great Listener"
        } else if averageMessageLength > 100 {
            return "📝 Novelist"
        } else if averageMessageLength < 20 {
            return "⚡ Quick Responder"
        } else {
            return "🌟 Balanced Communicator"
        }
    }
}

struct ContactStats: Identifiable {
    let id = UUID()
    let identifier: String
    let displayName: String
    let messagesSent: Int
    let messagesReceived: Int
    let lastMessage: Date
    
    var totalMessages: Int {
        messagesSent + messagesReceived
    }
}
