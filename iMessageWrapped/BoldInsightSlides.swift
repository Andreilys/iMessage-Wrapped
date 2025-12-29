import SwiftUI

// MARK: - Redesigned Slides for Spotify Wrapped Aesthetic

// MARK: - Bold Emoji Deep Dive

struct BoldEmojiDeepDiveSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Spacer()
                
                if let topEmoji = insights.emojiDeepDive.topEmojis.first {
                    // Massive emoji reveal
                    VStack(spacing: 20) {
                        Text(topEmoji.emoji)
                            .font(.system(size: 200))
                            .scaleEffect(appear ? 1 : 0.3)
                            .glow(color: .yellow, radius: 40)
                            .rotation3DEffect(
                                .degrees(appear ? 0 : 360),
                                axis: (x: 0, y: 1, z: 0)
                            )
                        
                        Text("Your emoji of the year")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                            .offset(y: appear ? 0 : 20)
                            .opacity(appear ? 1 : 0)
                        
                        // Count reveal
                        HStack(spacing: 8) {
                            Text("Used")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            CountUpText(
                                value: topEmoji.count,
                                font: .system(size: 48, weight: .black, design: .rounded),
                                color: .yellow
                            )
                            .glow(color: .yellow, radius: 15)
                            
                            Text("times")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .offset(y: appear ? 0 : 30)
                        .opacity(appear ? 1 : 0)
                        
                        // Percentage stat
                        Text("That's \(Int(topEmoji.percentOfTotal))% of all your emojis")
                            .font(.headline)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(y: appear ? 0 : 20)
                            .opacity(appear ? 1 : 0)
                    }
                    
                    // Runner-ups
                    if insights.emojiDeepDive.topEmojis.count > 1 {
                        VStack(spacing: 8) {
                            Text("Runner-ups")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                            
                            HStack(spacing: 16) {
                                ForEach(Array(insights.emojiDeepDive.topEmojis.dropFirst().prefix(4)), id: \.id) { emoji in
                                    VStack(spacing: 4) {
                                        Text(emoji.emoji)
                                            .font(.system(size: 36))
                                        Text("\(emoji.count)")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                        .offset(y: appear ? 0 : 20)
                        .opacity(appear ? 1 : 0)
                    }
                }
                
                Spacer()
            }
            
            // Confetti explosion
            if showConfetti {
                ParticleSystem(type: .confetti)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
                appear = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Bold Temporal Fingerprint

struct BoldTemporalFingerprintSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    @State private var showParticles = false
    
    var isNightOwl: Bool {
        insights.temporalFingerprint.nightOwlScore > insights.temporalFingerprint.earlyBirdScore
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Bold proclamation
                VStack(spacing: 20) {
                    Text(isNightOwl ? "🦉" : "🌅")
                        .font(.system(size: 140))
                        .scaleEffect(appear ? 1 : 0.3)
                        .glow(color: isNightOwl ? .purple : .orange, radius: 30)
                    
                    Text("You're a")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                        .offset(y: appear ? 0 : 20)
                        .opacity(appear ? 1 : 0)
                    
                    Text(isNightOwl ? "Night Owl" : "Early Bird")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isNightOwl ? [.purple, .indigo] : [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(y: appear ? 0 : 30)
                        .opacity(appear ? 1 : 0)
                        .shimmer(duration: 2.5)
                }
                
                // Peak time
                VStack(spacing: 12) {
                    if let peakHour = insights.temporalFingerprint.hourlyDistribution.max(by: { $0.value < $1.value })?.key {
                        PunchyStat(
                            text: peakHourText(peakHour),
                            icon: isNightOwl ? "moon.stars.fill" : "sun.max.fill",
                            color: isNightOwl ? .purple : .orange
                        )
                        .offset(x: appear ? 0 : -50)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.3), value: appear)
                    }
                    
                    PunchyStat(
                        text: weekendVibe,
                        icon: "calendar",
                        color: .cyan
                    )
                    .offset(x: appear ? 0 : 50)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.5), value: appear)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            
            // Particles
            if showParticles {
                ParticleSystem(type: isNightOwl ? .stars : .sparkles)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showParticles = true
            }
        }
    }
    
    func peakHourText(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        if let date = Calendar.current.date(from: DateComponents(hour: hour)) {
            let timeString = formatter.string(from: date)
            if hour >= 22 || hour < 4 {
                return "\(timeString) was your witching hour"
            } else if hour >= 4 && hour < 8 {
                return "\(timeString) - you're up with the sun"
            } else {
                return "Peak activity at \(timeString)"
            }
        }
        return "Your peak messaging time"
    }
    
    var weekendVibe: String {
        let ratio = insights.temporalFingerprint.weekendVsWeekdayRatio
        if ratio > 1.5 {
            return "Weekend warrior — you live for Saturday"
        } else if ratio < 0.7 {
            return "Weekday grinder — you go MIA on weekends"
        } else {
            return "Balanced—you text every day"
        }
    }
}

// MARK: - Bold Relationship Dynamics

struct BoldRelationshipSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var topRelationship: RelationshipDynamics? {
        insights.relationshipDynamics
            .filter { !$0.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .first
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if let top = topRelationship {
                // Main character spotlight
                VStack(spacing: 20) {
                    Text("Your Main Character")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                        .offset(y: appear ? 0 : 20)
                        .opacity(appear ? 1 : 0)
                    
                    // Huge avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 180, height: 180)
                            .glow(color: .pink, radius: 30)
                        
                        Text(String(top.displayName.prefix(1)).uppercased())
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(appear ? 1 : 0.3)
                    
                    Text(top.displayName)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .offset(y: appear ? 0 : 30)
                        .opacity(appear ? 1 : 0)
                    
                    // Count reveal
                    HStack(spacing: 8) {
                        CountUpText(
                            value: top.totalMessages,
                            font: .system(size: 48, weight: .black, design: .rounded),
                            color: .pink
                        )
                        .glow(color: .pink, radius: 15)
                        
                        Text("messages")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .offset(y: appear ? 0 : 30)
                    .opacity(appear ? 1 : 0)
                    
                    Text("You talked to them more than anyone else")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .offset(y: appear ? 0 : 20)
                        .opacity(appear ? 1 : 0)
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
