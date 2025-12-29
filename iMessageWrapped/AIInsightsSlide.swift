import SwiftUI

// MARK: - AI Insights Slide

struct AIInsightsSlide: View {
    let analytics: MessageAnalytics
    @StateObject private var aiManager = AIInsightsManager()
    @State private var narrative: YearInReviewNarrative?
    @State private var isLoading = false
    @State private var error: String?
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if aiManager.isAvailable {
                availableContent
            } else {
                unavailableContent
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
            loadInsights()
        }
    }
    
    // MARK: - AI Available Content
    
    @ViewBuilder
    var availableContent: some View {
        if isLoading {
            loadingView
        } else if let narrative = narrative {
            narrativeView(narrative)
        } else if let error = error {
            errorView(error)
        } else {
            initialView
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.cyan)
            
            Text("AI is crafting your story...")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Text("Using Private On-Device Intelligence")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .offset(y: appear ? 0 : 30)
        .opacity(appear ? 1 : 0)
    }
    
    // MARK: - Narrative
    
    func narrativeView(_ narrative: YearInReviewNarrative) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    Text("AI-Powered Insights")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)
                
                // Opening Hook
                Text(narrative.openingHook)
                    .font(.title3)
                    .foregroundColor(.white)
                    .italic()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .pink.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .offset(y: appear ? 0 : 20)
                    .opacity(appear ? 1 : 0)
                
                // Key Moments
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Moments")
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    ForEach(Array(narrative.keyMoments.enumerated()), id: \.offset) { index, moment in
                        HStack(alignment: .top, spacing: 12) {
                            Text("✦")
                                .foregroundColor(.cyan)
                            Text(moment)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .offset(x: appear ? 0 : 50)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(Double(index) * 0.1), value: appear)
                    }
                }
                
                // Relationship Highlights
                VStack(alignment: .leading, spacing: 8) {
                    Text("Relationship Highlights")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text(narrative.relationshipHighlights)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.05))
                )
                
                // Closing
                Text(narrative.closingReflection)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(.horizontal, 30)
        }
    }
    
    func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Couldn't generate AI insights")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                loadInsights()
            }
            .buttonStyle(.bordered)
            .tint(.cyan)
        }
        .padding()
    }
    
    var initialView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .pink, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Generate AI Insights")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Let Private On-Device Intelligence analyze your messaging patterns")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: loadInsights) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Generate")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.cyan, .green], startPoint: .leading, endPoint: .trailing)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .offset(y: appear ? 0 : 30)
        .opacity(appear ? 1 : 0)
    }
    
    // MARK: - Unavailable Content
    
    var unavailableContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("AI Insights Unavailable")
                .font(.headline)
                .foregroundColor(.white)
            
            if let reason = aiManager.unavailabilityReason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            Text("Requires macOS 26+ for Private On-Device Intelligence")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .padding()
        .offset(y: appear ? 0 : 30)
        .opacity(appear ? 1 : 0)
    }
    
    // MARK: - Legacy macOS Content
    
    var legacyContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(colors: [.purple.opacity(0.5), .gray], startPoint: .top, endPoint: .bottom)
                )
            
            Text("AI Insights")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Requires macOS 26 (Tahoe) or later with Apple Intelligence")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical)
            
            // Show alternative: Local LLM option
            VStack(spacing: 12) {
                Text("Alternative: Use Local LLM")
                    .font(.headline)
                    .foregroundColor(.cyan)
                
                Text("Run Ollama or MLX for AI-powered analysis with larger context windows")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(30)
        .offset(y: appear ? 0 : 30)
        .opacity(appear ? 1 : 0)
    }
    
    // MARK: - Load Insights
    
    // MARK: - Load Insights
    
    func loadInsights() {
        if let existingNarrative = analytics.aiNarrative {
            self.narrative = existingNarrative
        } else {
            // If no narrative was generated (e.g. AI failed or disabled), show partial error or empty state
           self.error = "AI Analysis was not performed."
        }
    }
}

// MARK: - Contact AI Insight Card

struct ContactAIInsightCard: View {
    let contact: ContactStats
    let insight: ConversationInsight?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 40, height: 40)
                    
                    Text(String(contact.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading) {
                    Text(contact.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(contact.totalMessages) messages")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if insight != nil {
                    Image(systemName: "sparkles")
                        .foregroundColor(.cyan)
                }
            }
            
            if let insight = insight {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.relationshipDynamic)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(insight.communicationStyle)
                        .font(.caption)
                        .foregroundColor(.cyan)
                    
                    if !insight.suggestedPersonalityTraits.isEmpty {
                        HStack {
                            ForEach(insight.suggestedPersonalityTraits.prefix(3), id: \.self) { trait in
                                Text(trait)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(.white.opacity(0.1)))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            insight != nil ?
                            LinearGradient(colors: [.purple.opacity(0.5), .pink.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Context Window Explainer

struct ContextWindowExplainer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.cyan)
                Text("About AI Context Windows")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text("LLMs have a \"context window\" - the maximum amount of text they can process at once. Here's how different options compare:")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 8) {
                ForEach(AIModelContextInfo.comparison, id: \.name) { option in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(option.name)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Text(option.notes)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(option.tokens / 1000)K tokens")
                                .font(.caption.bold())
                                .foregroundColor(.cyan)
                            Text("~\(option.messages) msgs")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 6)
                    
                    if option.name != AIModelContextInfo.comparison.last?.name {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.3))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        AIInsightsSlide(
            analytics: MessageAnalytics(messages: [], days: 30)
        )
    }
}
