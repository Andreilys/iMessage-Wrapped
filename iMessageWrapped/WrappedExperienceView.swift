import SwiftUI

struct WrappedExperienceView: View {

    @ObservedObject var viewModel: WrappedViewModel
    
    // Helper to find relationship dynamics for a contact
    private func relationshipDynamics(for contact: ContactStats) -> RelationshipDynamics? {
        viewModel.wrappedInsights?.relationshipDynamics.first { $0.contactIdentifier == contact.identifier }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background based on slide
                slideBackground(for: viewModel.currentSlide)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentSlide)
                
                // Content
                VStack {
                    // Progress indicator
                    ProgressBar(current: viewModel.currentSlide, total: viewModel.totalSlides)
                        .padding(.top, geometry.safeAreaInsets.top + 20)
                        .padding(.horizontal, 20)
                    
                    // Slide content
                    ZStack {
                        ForEach(0..<viewModel.totalSlides, id: \.self) { index in
                            if index == viewModel.currentSlide {
                                slideContent(for: index)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }
                    }
                    .frame(maxWidth: min(geometry.size.width - 40, 600), maxHeight: .infinity)
                    .frame(maxWidth: .infinity) // Center the content
                    
                    // Navigation
                    HStack {
                        if viewModel.currentSlide > 0 {
                            NavigationButton(direction: .back) {
                                viewModel.previousSlide()
                            }
                        }
                        
                        Spacer()
                        
                        if viewModel.currentSlide < viewModel.totalSlides - 1 {
                            NavigationButton(direction: .forward) {
                                viewModel.nextSlide()
                            }
                        } else {
                            Button(action: viewModel.reset) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Start Over")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.2))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(30)
                }
                // Keyboard Controls (Invisible)
                Group {
                    Button("Next") { viewModel.nextSlide() }
                        .keyboardShortcut(.rightArrow, modifiers: [])
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        
                    Button("Prev") { viewModel.previousSlide() }
                        .keyboardShortcut(.leftArrow, modifiers: [])
                        .opacity(0)
                        .frame(width: 0, height: 0)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        if value.translation.width < -50 {
                            viewModel.nextSlide()
                        } else if value.translation.width > 50 {
                            viewModel.previousSlide()
                        }
                    }
            )
        }
        .sheet(item: $viewModel.selectedContact) { contact in
            ConversationDeepDiveView(
                contact: contact,
                messages: viewModel.messages,
                relationshipDynamics: relationshipDynamics(for: contact)
            )
        }
    }
    
    func slideBackground(for index: Int) -> some View {
        let gradients: [[Color]] = [
            [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.05, green: 0.05, blue: 0.15)],
            [Color(red: 0.2, green: 0.1, blue: 0.3), Color(red: 0.1, green: 0.05, blue: 0.2)],
            [Color(red: 0.1, green: 0.2, blue: 0.3), Color(red: 0.05, green: 0.1, blue: 0.2)],
            [Color(red: 0.3, green: 0.1, blue: 0.2), Color(red: 0.15, green: 0.05, blue: 0.1)],
            [Color(red: 0.1, green: 0.3, blue: 0.2), Color(red: 0.05, green: 0.15, blue: 0.1)],
            [Color(red: 0.2, green: 0.2, blue: 0.1), Color(red: 0.1, green: 0.1, blue: 0.05)],
            [Color(red: 0.3, green: 0.2, blue: 0.1), Color(red: 0.15, green: 0.1, blue: 0.05)],
            [Color(red: 0.1, green: 0.2, blue: 0.3), Color(red: 0.05, green: 0.1, blue: 0.2)],
            [Color(red: 0.2, green: 0.1, blue: 0.3), Color(red: 0.1, green: 0.05, blue: 0.2)],
            [Color(red: 0.1, green: 0.3, blue: 0.3), Color(red: 0.05, green: 0.15, blue: 0.15)],
        ]
        
        let colors = gradients[index % gradients.count]
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    @ViewBuilder
    func slideContent(for index: Int) -> some View {
        if let analytics = viewModel.analytics {
            // Check if we have advanced AI insights
            if let insights = viewModel.wrappedInsights {
                // Consolidated 6-slide flow
                // Expanded 10-slide flow
                switch index {
                case 0:
                    IntroStatsSlide(analytics: analytics)
                case 1:
                    ActivitySlide(insights: insights)
                case 2:
                    CrewSlide(insights: insights)
                case 3:
                    TopConnectionSlide(analytics: analytics, insights: insights)
                case 4:
                    SemanticVibeSlide(insights: insights)
                case 5:
                    YourWorldSlide(insights: insights)
                case 6:
                    EmojiDeepDiveSlide(insights: insights)
                case 7:
                    StyleSlide(insights: insights)
                case 8:
                    PersonaSlide(insights: insights)
                case 9:
                    ShareSlide(insights: insights, analytics: analytics, messages: viewModel.messages)
                default:
                    EmptyView()
                }
            } else {
               Text("No AI Insights Available - Please Check Logs")
                   .foregroundColor(.red)
            }

        }
    }
}

struct ProgressBar: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.white : Color.white.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

struct NavigationButton: View {
    enum Direction { case back, forward }
    let direction: Direction
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: direction == .back ? "chevron.left" : "chevron.right")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isHovered ? .white.opacity(0.3) : .white.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Slide Views

struct IntroSlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "message.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(appear ? 1 : 0.5)
                .opacity(appear ? 1 : 0)
            
            VStack(spacing: 10) {
                Text("Your iMessage")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                Text("Wrapped")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .foregroundColor(.white)
            .offset(y: appear ? 0 : 30)
            .opacity(appear ? 1 : 0)
            
            Text("Last \(analytics.timePeriodDays) days")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)
            
            Spacer()
            
            Text("Tap anywhere to continue →")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .opacity(appear ? 1 : 0)
                .padding(.bottom, 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                appear = true
            }
        }
    }
}

struct TotalMessagesSlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    @State private var countUp = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 10) {
                Text("You exchanged")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(countUp)")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .cyan],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())
                
                Text("messages")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .offset(y: appear ? 0 : 50)
            .opacity(appear ? 1 : 0)
            
            HStack(spacing: 40) {
                StatBox(value: analytics.messagesSent, label: "Sent", icon: "arrow.up.circle.fill", color: .blue)
                StatBox(value: analytics.messagesReceived, label: "Received", icon: "arrow.down.circle.fill", color: .green)
            }
            .offset(y: appear ? 0 : 30)
            .opacity(appear ? 1 : 0)
            
            Text("That's about \(Int(analytics.messagesPerDay)) messages per day!")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
            animateCount()
        }
    }
    
    func animateCount() {
        let target = analytics.totalMessages
        let steps = 30
        let stepDuration = 0.03
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                withAnimation {
                    countUp = Int(Double(target) * Double(i) / Double(steps))
                }
            }
        }
    }
}

struct StatBox: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
        )
    }
}

struct TopContactSlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Filter out empty display names and get first valid contact
            let validContacts = analytics.topContacts.filter { 
                !$0.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                $0.displayName != "Unknown"
            }
            
            if let topContact = validContacts.first {
                VStack(spacing: 20) {
                    Text("Your #1 contact")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .orange.opacity(0.5), radius: 20)
                        
                        Text(String(topContact.displayName.prefix(1)).uppercased())
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(appear ? 1 : 0.5)
                    
                    Text(topContact.displayName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("\(topContact.totalMessages) messages")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 20) {
                        Label("\(topContact.messagesSent) sent", systemImage: "arrow.up")
                        Label("\(topContact.messagesReceived) received", systemImage: "arrow.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                }
                .offset(y: appear ? 0 : 30)
                .opacity(appear ? 1 : 0)
            } else {
                // No valid contacts
                VStack(spacing: 16) {
                    Text("📱")
                        .font(.system(size: 60))
                    Text("Start texting!")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("No contacts with enough data yet.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
}

struct TopContactsListSlide: View {
    let analytics: MessageAnalytics
    var onContactTap: ((ContactStats) -> Void)? = nil
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Your Top Conversations")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                Text("Tap a contact to explore")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(analytics.topContacts.prefix(5).enumerated()), id: \.element.id) { index, contact in
                        ContactRow(rank: index + 1, contact: contact, onTap: onContactTap)
                            .offset(x: appear ? 0 : 100)
                            .opacity(appear ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: appear)
                    }
                }
                .padding(.horizontal, 30)
            }
        }
        .onAppear {
            withAnimation {
                appear = true
            }
        }
    }
}

struct ContactRow: View {
    let rank: Int
    let contact: ContactStats
    var onTap: ((ContactStats) -> Void)? = nil
    
    @State private var isHovered = false
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white.opacity(0.5)
        }
    }
    
    var body: some View {
        Button(action: { onTap?(contact) }) {
            HStack(spacing: 16) {
                Text("#\(rank)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(rankColor)
                    .frame(width: 40)
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text(String(contact.displayName.prefix(1)).uppercased())
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(contact.messagesSent) sent · \(contact.messagesReceived) received")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(contact.totalMessages)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                    
                    if onTap != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isHovered ? .white.opacity(0.15) : .white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isHovered ? .white.opacity(0.2) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct EmojiSlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Your Top Emojis")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            if analytics.topEmojis.isEmpty {
                Text("📭")
                    .font(.system(size: 80))
                Text("No emojis found!")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                if let topEmoji = analytics.topEmojis.first {
                    Text(topEmoji.emoji)
                        .font(.system(size: 100))
                        .scaleEffect(appear ? 1 : 0.3)
                    
                    Text("Used \(topEmoji.count) times")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 20) {
                    ForEach(Array(analytics.topEmojis.dropFirst().prefix(5).enumerated()), id: \.offset) { index, emoji in
                        VStack {
                            Text(emoji.emoji)
                                .font(.system(size: 40))
                            Text("\(emoji.count)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .scaleEffect(appear ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1 + 0.3), value: appear)
                    }
                }
                .padding(.top, 20)
            }
            
            Spacer()
        }
        .foregroundColor(.white)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
}

struct TimePatternSlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("When You Message")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            if let busiestHour = analytics.busiestHour {
                VStack(spacing: 10) {
                    Image(systemName: hourIcon(busiestHour))
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: hourColors(busiestHour),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(appear ? 1 : 0.5)
                    
                    Text(formatHour(busiestHour))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("is your busiest hour")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Hour distribution chart
            HourlyChart(distribution: analytics.hourlyDistribution)
                .frame(height: 100)
                .padding(.horizontal, 30)
                .opacity(appear ? 1 : 0)
            
            HStack(spacing: 30) {
                VStack {
                    Text("🌙")
                        .font(.title)
                    Text("\(analytics.lateNightMessages)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Late night")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack {
                    Text("🌅")
                        .font(.title)
                    Text("\(analytics.earlyMorningMessages)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Early morning")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.top, 20)
            .offset(y: appear ? 0 : 30)
            .opacity(appear ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
    
    func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(from: DateComponents(hour: hour))!
        return formatter.string(from: date)
    }
    
    func hourIcon(_ hour: Int) -> String {
        switch hour {
        case 5..<12: return "sun.horizon.fill"
        case 12..<17: return "sun.max.fill"
        case 17..<21: return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }
    
    func hourColors(_ hour: Int) -> [Color] {
        switch hour {
        case 5..<12: return [.orange, .yellow]
        case 12..<17: return [.yellow, .orange]
        case 17..<21: return [.orange, .pink]
        default: return [.purple, .blue]
        }
    }
}

struct HourlyChart: View {
    let distribution: [Int: Int]
    
    var maxValue: Int {
        distribution.values.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<24, id: \.self) { hour in
                let value = distribution[hour] ?? 0
                let height = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.green, .cyan],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: max(4, height * 80))
            }
        }
    }
}

struct WeekdaySlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    
    let weekdayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let weekdayEmoji = ["", "🌅", "💼", "📝", "🐪", "🎯", "🎉", "🌴"]
    
    var busiestDay: Int {
        analytics.weekdayDistribution.max(by: { $0.value < $1.value })?.key ?? 1
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Your Busiest Day")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            Text(weekdayEmoji[busiestDay])
                .font(.system(size: 80))
                .scaleEffect(appear ? 1 : 0.3)
            
            Text(weekdayNames[busiestDay])
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Weekday chart
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let value = analytics.weekdayDistribution[day] ?? 0
                    let maxValue = analytics.weekdayDistribution.values.max() ?? 1
                    let height = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
                    
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                day == busiestDay ?
                                LinearGradient(colors: [.yellow, .orange], startPoint: .bottom, endPoint: .top) :
                                LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.1)], startPoint: .bottom, endPoint: .top)
                            )
                            .frame(width: 40, height: max(20, height * 120))
                        
                        Text(weekdayNames[day].prefix(1))
                            .font(.caption.weight(.medium))
                            .foregroundColor(day == busiestDay ? .yellow : .white.opacity(0.6))
                    }
                    .scaleEffect(appear ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(day) * 0.05), value: appear)
                }
            }
            .padding(.top, 20)
            
            HStack(spacing: 30) {
                VStack {
                    Text("\(analytics.weekdayMessages)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("Weekday")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text("vs")
                    .foregroundColor(.white.opacity(0.4))
                
                VStack {
                    Text("\(analytics.weekendMessages)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Text("Weekend")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
}

struct MessagingStyleSlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Your Messaging Style")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 24) {
                StyleStat(
                    icon: "character.cursor.ibeam",
                    value: "\(Int(analytics.averageMessageLength))",
                    label: "avg characters per message",
                    appear: appear,
                    delay: 0
                )
                
                StyleStat(
                    icon: "text.alignleft",
                    value: formatNumber(analytics.totalCharacters),
                    label: "total characters typed",
                    appear: appear,
                    delay: 0.1
                )
                
                StyleStat(
                    icon: "photo.fill",
                    value: "\(analytics.attachmentCount)",
                    label: "attachments shared",
                    appear: appear,
                    delay: 0.2
                )
            }
            .padding(.horizontal, 40)
            
            if let longest = analytics.longestMessage, longest.count > 100 {
                VStack(spacing: 8) {
                    Text("Longest message: \(longest.count) characters")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("That's like a mini essay! 📝")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.top, 20)
                .opacity(appear ? 1 : 0)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
    
    func formatNumber(_ num: Int) -> String {
        if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fK", Double(num) / 1_000)
        }
        return "\(num)"
    }
}

struct StyleStat: View {
    let icon: String
    let value: String
    let label: String
    let appear: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan)
                .frame(width: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
        )
        .offset(x: appear ? 0 : 50)
        .opacity(appear ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: appear)
    }
}

struct PersonalitySlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Your Messaging Personality")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            Text(analytics.personalityType)
                .font(.system(size: 60))
                .scaleEffect(appear ? pulseScale : 0.3)
            
            Text(personalityDescription)
                .font(.title3)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(appear ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
    
    var personalityDescription: String {
        switch analytics.personalityType {
        case "🦉 Night Owl":
            return "You thrive when the world sleeps. Your best conversations happen under the stars."
        case "🌅 Early Bird":
            return "Rise and shine! You start your day with meaningful connections."
        case "🎉 Weekend Warrior":
            return "TGIF is your motto. You save the best conversations for the weekend."
        case "💬 Conversation Starter":
            return "You're the one who keeps the conversation going. Your friends love your energy!"
        case "👂 Great Listener":
            return "You give everyone space to share. Your thoughtful responses mean the world."
        case "📝 Novelist":
            return "Why use few words when you can paint a picture? Your messages are mini-masterpieces."
        case "⚡ Quick Responder":
            return "Short, sweet, and to the point. You value efficiency in communication."
        default:
            return "You've mastered the art of balanced communication. A true messaging diplomat!"
        }
    }
}

struct SummarySlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Your \(analytics.timePeriodDays)-Day Summary")
                .font(.title.weight(.bold))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                SummaryListRow(emoji: "💬", text: "\(analytics.totalMessages) messages exchanged")
                SummaryListRow(emoji: "👥", text: "\(analytics.topContacts.count) conversations")
                
                if let top = analytics.topContacts.first {
                    SummaryListRow(emoji: "⭐", text: "Top contact: \(top.displayName)")
                }
                
                if let topEmoji = analytics.topEmojis.first {
                    SummaryListRow(emoji: topEmoji.emoji, text: "Favorite emoji (\(topEmoji.count)x)")
                }
                
                SummaryListRow(emoji: "📊", text: "\(Int(analytics.messagesPerDay)) messages/day average")
                SummaryListRow(emoji: analytics.personalityType.prefix(2).description, text: String(analytics.personalityType.dropFirst(3)))
            }
            .padding(.horizontal, 30)
            .offset(y: appear ? 0 : 30)
            .opacity(appear ? 1 : 0)
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Thanks for using")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("iMessage AI")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.bottom, 40)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
}

struct SummaryListRow: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.title2)
                .frame(width: 40)
            
            Text(text)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
    }
}

#Preview {
    WrappedExperienceView(viewModel: WrappedViewModel())
}
