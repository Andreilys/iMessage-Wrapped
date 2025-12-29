import Foundation
import SwiftUI

@MainActor
class WrappedViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var hasData = false
    @Published var analytics: MessageAnalytics?
    @Published var wrappedInsights: WrappedInsights?
    @Published var errorMessage: String?
    @Published var currentSlide = 0
    @Published var isAIGenerated = false
    @Published var selectedContact: ContactStats?
    @Published var messages: [Message] = []
    
    private let dbReader = iMessageDatabaseReader()
    
    var totalSlides: Int {
        wrappedInsights != nil ? 10 : 12
    }
    
    func loadData(days: Int, isAI: Bool = false) {
        isLoading = true
        isAIGenerated = isAI
        errorMessage = nil
        
        Task {
            do {
                try dbReader.open()
                let messages = try dbReader.getMessages(fromDaysAgo: days)
                dbReader.close()
                
                var analytics = MessageAnalytics(messages: messages, days: days)
                
                // Run full analysis with NaturalLanguage AI
                let insights = await AdvancedAIAnalyzer.shared.analyzeMessages(messages, days: days)
                
                // Also generate narrative
                do {
                    let (aiResult, score, label) = try await AIInsightsManager.shared.generateYearNarrative(analytics: analytics, messages: messages)
                    analytics.aiNarrative = aiResult
                    analytics.sentimentScore = score
                    analytics.sentimentDescription = label
                } catch {
                    print("AI Narrative generation failed: \(error)")
                }
                
                await MainActor.run {
                    self.messages = messages
                    self.analytics = analytics
                    self.wrappedInsights = insights
                    self.hasData = true
                    self.isLoading = false
                    self.currentSlide = 0
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func nextSlide() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if currentSlide < totalSlides - 1 {
                currentSlide += 1
            }
        }
    }
    
    func previousSlide() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if currentSlide > 0 {
                currentSlide -= 1
            }
        }
    }
    
    func reset() {
        withAnimation {
            hasData = false
            analytics = nil
            wrappedInsights = nil
            currentSlide = 0
            isAIGenerated = false
            messages = []
            selectedContact = nil
        }
    }
}
