import SwiftUI

struct SentimentSlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    
    var vibeColor: Color {
        let score = analytics.sentimentScore
        if score > 0.5 { return .yellow }
        if score > 0 { return .orange }
        if score > -0.5 { return .purple }
        return .blue
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Your Vibe Check")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            ZStack {
                // Background Glow
                Circle()
                    .fill(vibeColor.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .blur(radius: 40)
                    .scaleEffect(appear ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: appear)
                
                // Ring
                Circle()
                    .stroke(lineWidth: 20)
                    .foregroundColor(.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                // Indicator
                Circle()
                    .trim(from: 0, to: CGFloat((analytics.sentimentScore + 1.0) / 2.0)) // Map -1...1 to 0...1
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .foregroundColor(vibeColor)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: vibeColor.opacity(0.5), radius: 10)
                    .animation(.spring(response: 1.5), value: appear)
                
                VStack {
                    Text(String(format: "%.0f%%", (analytics.sentimentScore + 1.0) * 50))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Positivity")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .scaleEffect(appear ? 1 : 0.5)
            .opacity(appear ? 1 : 0)
            
            VStack(spacing: 12) {
                Text(analytics.sentimentDescription)
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [vibeColor, .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Based on AI sentiment analysis of your messages.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 40)
            }
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
}
