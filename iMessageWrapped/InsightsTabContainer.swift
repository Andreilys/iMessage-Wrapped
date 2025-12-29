import SwiftUI

// MARK: - Insights Tab Container

/// Container that provides tabbed navigation between Cards and Chat views
/// Shows after the report is generated
struct InsightsTabContainer: View {
    @ObservedObject var viewModel: WrappedViewModel
    @State private var selectedTab: InsightsTab = .cards
    
    enum InsightsTab: String, CaseIterable {
        case cards = "Cards"
        case chat = "Chat"
        
        var icon: String {
            switch self {
            case .cards: return "rectangle.stack.fill"
            case .chat: return "bubble.left.and.bubble.right.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar at top
            tabBar
            
            // Content
            ZStack {
                switch selectedTab {
                case .cards:
                    WrappedExperienceView(viewModel: viewModel)
                        .transition(.opacity)
                        
                case .chat:
                    if let insights = viewModel.wrappedInsights {
                        InsightsChatView(
                            insights: insights,
                            messages: viewModel.messages
                        )
                        .transition(.opacity)
                    } else {
                        // Fallback if no insights
                        VStack(spacing: 20) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Chat requires AI analysis")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Complete the report first to unlock chat")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "0F0F23"))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(InsightsTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .background(
            Color(hex: "0F0F23")
                .ignoresSafeArea()
        )
    }
    
    private func tabButton(for tab: InsightsTab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.subheadline)
                
                Text(tab.rawValue)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                selectedTab == tab
                ? LinearGradient(colors: [.cyan.opacity(0.3), .purple.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Final Report View with Tabs

/// The final slide that shows summary with option to go to chat
struct FinalReportSlide: View {
    let insights: WrappedInsights
    var onOpenChat: () -> Void
    
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Celebration
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.green)
                        .scaleEffect(appear ? 1 : 0.5)
                }
                
                Text("Your Report is Ready!")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("\(insights.totalMessagesAnalyzed) messages analyzed")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .opacity(appear ? 1 : 0)
            
            Spacer().frame(height: 20)
            
            // Quick stats
            HStack(spacing: 20) {
                QuickStatPill(
                    icon: "person.2.fill",
                    value: "\(insights.relationshipDynamics.count)",
                    label: "Contacts"
                )
                

                
                if let topEmoji = insights.emojiDeepDive.topEmojis.first {
                    QuickStatPill(
                        icon: nil,
                        emoji: topEmoji.emoji,
                        value: "\(topEmoji.count)",
                        label: "Top Emoji"
                    )
                }
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
            
            Spacer()
            
            // Chat CTA
            VStack(spacing: 12) {
                Button(action: onOpenChat) {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("Chat with Your Insights")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                
                Text("Ask questions about your messaging patterns")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                appear = true
            }
        }
    }
}

// MARK: - Quick Stat Pill

private struct QuickStatPill: View {
    var icon: String?
    var emoji: String?
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            if let emoji = emoji {
                Text(emoji)
                    .font(.title)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.cyan)
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview("Insights Tab Container") {
    InsightsTabContainer(viewModel: WrappedViewModel())
}

#Preview("Final Report Slide") {
    FinalReportSlide(
        insights: .preview,
        onOpenChat: {}
    )
    .frame(width: 500, height: 700)
    .background(Color(hex: "0F0F23"))
}
