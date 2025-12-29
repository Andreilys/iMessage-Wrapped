import SwiftUI
import UniformTypeIdentifiers

struct TextFile: FileDocument {
    static var readableContentTypes = [UTType.plainText]
    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: text.data(using: .utf8)!)
    }
}

// MARK: - Particle System & Effects

/// Reusable particle effect system for confetti, sparkles, and other animations
struct ParticleSystem: View {
    let type: ParticleType
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ParticleView(particle: particle, type: type)
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<type.particleCount).map { _ in
            Particle(
                angle: Double.random(in:  0...360),
                speed: Double.random(in: type.speedRange),
                size: Double.random(in: type.sizeRange),
                opacity: Double.random(in: 0.6...1.0)
            )
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    let angle: Double
    let speed: Double
    let size: Double
    let opacity: Double
}

struct ParticleView: View {
    let particle: Particle
    let type: ParticleType
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1
    
    var body: some View {
        type.shape
            .fill(type.color)
            .frame(width: particle.size, height: particle.size)
            .opacity(opacity * particle.opacity)
            .offset(offset)
            .onAppear {
                let radians = particle.angle * .pi / 180
                let distance = particle.speed * type.distance
                
                withAnimation(.easeOut(duration: type.duration)) {
                    offset = CGSize(
                        width: cos(radians) * distance,
                        height: sin(radians) * distance
                    )
                    opacity = 0
                }
            }
    }
}

enum ParticleType {
    case confetti, sparkles, stars
    
    var particleCount: Int {
        switch self {
        case .confetti: return 50
        case .sparkles: return 30
        case .stars: return 25
        }
    }
    
    var speedRange: ClosedRange<Double> {
        switch self {
        case .confetti: return 150...300
        case .sparkles: return 100...200
        case .stars: return 120...250
        }
    }
    
    var sizeRange: ClosedRange<Double> {
        switch self {
        case .confetti: return 6...12
        case .sparkles: return 4...8
        case .stars: return 6...12
        }
    }
    
    var distance: Double { 2.0 }
    var duration: Double { 1.2 }
    
    var shape: AnyShape {
        AnyShape(RoundedRectangle(cornerRadius: 2))
    }
    
    var color: Color {
        switch self {
        case .confetti: return [.cyan, .purple, .pink, .yellow, .green].randomElement()!
        case .sparkles: return .yellow
        case .stars: return .cyan
        }
    }
}

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
    }
    
    func path(in rect: CGRect) -> Path { _path(rect) }
}

// View Modifiers
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isPulsing ? 0.8 : 0.4), radius: isPulsing ? radius * 1.5 : radius)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 2.0) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
    
    func glow(color: Color = .cyan, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

struct CountUpText: View {
    let value: Int
    let font: Font
    let color: Color
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onAppear {
                animateCount()
            }
    }
    
    private func animateCount() {
        let steps = min(30, value)
        let stepDuration = 0.04
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                withAnimation {
                    displayValue = Int(Double(value) * Double(i) / Double(steps))
                }
            }
        }
    }
}

// MARK: - Communication DNA Slide

struct CommunicationDNASlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Personality reveal with confetti
                VStack(spacing: 20) {
                    Text(personalityEmoji)
                        .font(.system(size: 140))
                        .scaleEffect(appear ? 1 : 0.3)
                        .glow(color: personalityColor, radius: 30)
                    
                    Text("You're")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                        .offset(y: appear ? 0 : 20)
                        .opacity(appear ? 1 : 0)
                    
                    Text(personalityTitle)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: personalityGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .offset(y: appear ? 0 : 30)
                        .opacity(appear ? 1 : 0)
                        .shimmer(duration: 2.5)
                }
                
                // Punchy trait highlights
                VStack(spacing: 12) {
                    PunchyStat(
                        text: emojiTrait,
                        icon: "face.smiling.fill",
                        color: .yellow
                    )
                    .offset(x: appear ? 0 : -50)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.3), value: appear)
                    
                    PunchyStat(
                        text: lengthTrait,
                        icon: "text.bubble.fill",
                        color: .cyan
                    )
                    .offset(x: appear ? 0 : 50)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.5), value: appear)
                    
                    PunchyStat(
                        text: expressivenessTrait,
                        icon: "sparkles",
                        color: .pink
                    )
                    .offset(x: appear ? 0 : -50)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.7), value: appear)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            
            // Confetti explosion
            if showConfetti {
                ParticleSystem(type: .confetti)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showConfetti = true
            }
        }
    }
    
    // MARK: - Personality Logic
    
    var personalityTitle: String {
        let dna = insights.communicationDNA
        
        if dna.emojiDensity > 3.5 {
            return "The Emoji Enthusiast"
        } else if dna.questionToStatementRatio > 0.4 {
            return "The Curious Soul"
        } else if dna.expressiveness > 0.75 {
            return "The Expressive One"
        } else if dna.averageMessageLength > 100 {
            return "The Storyteller"
        } else if dna.formality > 0.7 {
            return "The Professional"
        } else if dna.emojiDensity < 0.5 && dna.formality < 0.3 {
            return "The Minimalist"
        } else {
            return "The Communicator"
        }
    }
    
    var personalityEmoji: String {
        let dna = insights.communicationDNA
        
        if dna.emojiDensity > 3.5 { return "🎨" }
        if dna.questionToStatementRatio > 0.4 { return "🤔" }
        if dna.expressiveness > 0.75 { return "⚡" }
        if dna.averageMessageLength > 100 { return "📖" }
        if dna.formality > 0.7 { return "👔" }
        if dna.emojiDensity < 0.5 { return "🎯" }
        return "💬"
    }
    
    var personalityColor: Color {
        let dna = insights.communicationDNA
        
        if dna.emojiDensity > 3.5 { return .yellow }
        if dna.questionToStatementRatio > 0.4 { return .purple }
        if dna.expressiveness > 0.75 { return .pink }
        if dna.averageMessageLength > 100 { return .cyan }
        if dna.formality > 0.7 { return .blue }
        return .green
    }
    
    var personalityGradient: [Color] {
        let dna = insights.communicationDNA
        
        if dna.emojiDensity > 3.5 { return [.yellow, .orange] }
        if dna.questionToStatementRatio > 0.4 { return [.purple, .pink] }
        if dna.expressiveness > 0.75 { return [.pink, .red] }
        if dna.averageMessageLength > 100 { return [.cyan, .blue] }
        if dna.formality > 0.7 { return [.blue, .indigo] }
        return [.green, .cyan]
    }
    
    var emojiTrait: String {
        let density = insights.communicationDNA.emojiDensity
        if density > 5 {
            return "You use 5x more emojis than average"
        } else if density > 3 {
            return "Every other message has an emoji"
        } else if density < 1 {
            return "Emoji? Never heard of her"
        }
        return "\(String(format: "%.1f", density)) emojis per message"
    }
    
    var lengthTrait: String {
        let length = Int(insights.communicationDNA.averageMessageLength)
        if length > 150 {
            return "You write essays, not texts"
        } else if length > 80 {
            return "You've got a lot to say"
        } else if length < 30 {
            return "Short and sweet is your style"
        }
        return "\(length) characters per message"
    }
    
    var expressivenessTrait: String {
        let expressiveness = insights.communicationDNA.expressiveness
        if expressiveness > 0.8 {
            return "Your energy is THROUGH THE ROOF"
        } else if expressiveness > 0.6 {
            return "You bring the vibes to every chat"
        } else if expressiveness < 0.3 {
            return "Cool, calm, and collected"
        }
        return "\(Int(expressiveness * 100))% expressive"
    }
}

struct PunchyStat: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 30)
    }
}

struct DNAStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
        )
    }
}

// MARK: - Relationship Dynamics Slide

struct RelationshipDynamicsSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var topRelationships: [RelationshipDynamics] {
        insights.relationshipDynamics
            .filter { !$0.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Relationship Dynamics")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Text("Who initiates? Who responds more?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(topRelationships.enumerated()), id: \.element.id) { index, relationship in
                        RelationshipCard(relationship: relationship)
                            .offset(x: appear ? 0 : 100)
                            .opacity(appear ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(Double(index) * 0.1), value: appear)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation {
                appear = true
            }
        }
    }
}

struct RelationshipCard: View {
    let relationship: RelationshipDynamics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    
                    Text(String(relationship.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading) {
                    Text(relationship.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(relationship.relationshipLabel)
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                Text("\(relationship.totalMessages)")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Initiative meter
            VStack(alignment: .leading, spacing: 4) {
                Text("Initiative")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.1))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(LinearGradient(colors: [.green, .cyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat((relationship.initiativeScore + 1) / 2), height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("They start")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text("You start")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            // Stats row
            HStack(spacing: 16) {
                Label("\(relationship.sentTotal) sent", systemImage: "arrow.up")
                Label("\(relationship.receivedTotal) received", systemImage: "arrow.down")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
        )
    }
}


// MARK: - Your World Slide (Named Entities)

struct YourWorldSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Your World")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Text("Places, people, and things you discuss")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            ScrollView {
                VStack(spacing: 20) {
                    // Places
                    if !insights.worldMap.places.isEmpty {
                        EntitySection(
                            title: "🌍 Places",
                            entities: insights.worldMap.places.prefix(5).map { $0 },
                            appear: appear
                        )
                    }
                    
                    // People mentioned
                    if !insights.worldMap.people.isEmpty {
                        EntitySection(
                            title: "👥 People Mentioned",
                            entities: insights.worldMap.people.prefix(5).map { $0 },
                            appear: appear
                        )
                    }
                    
                    // Organizations
                    if !insights.worldMap.organizations.isEmpty {
                        EntitySection(
                            title: "🏢 Organizations",
                            entities: insights.worldMap.organizations.prefix(5).map { $0 },
                            appear: appear
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                appear = true
            }
        }
    }
}

struct EntitySection: View {
    let title: String
    let entities: [NamedEntity]
    let appear: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.cyan)
            
            ForEach(Array(entities.enumerated()), id: \.element.id) { index, entity in
                HStack {
                    Text(entity.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("×\(entity.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.05)))
                .offset(x: appear ? 0 : 50)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5).delay(Double(index) * 0.05), value: appear)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.03))
        )
    }
}

// MARK: - Emoji Deep Dive Slide

struct EmojiDeepDiveSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Emoji Deep Dive")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            // Big emoji stats
            HStack(spacing: 40) {
                VStack {
                    Text("\(insights.emojiDeepDive.totalEmojiCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                    Text("Total Emojis")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack {
                    Text("\(insights.emojiDeepDive.uniqueEmojiCount)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom))
                    Text("Unique")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .scaleEffect(appear ? 1 : 0.5)
            .opacity(appear ? 1 : 0)
            
            // Top emojis with insights
            VStack(spacing: 12) {
                ForEach(Array(insights.emojiDeepDive.topEmojis.prefix(5).enumerated()), id: \.element.id) { index, emoji in
                    HStack {
                        Text(emoji.emoji)
                            .font(.title)
                        
                        VStack(alignment: .leading) {
                            Text("×\(emoji.count)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(emoji.contextDescription)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Text("\(Int(emoji.percent))%")
                            .font(.subheadline)
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
                    .offset(x: appear ? 0 : 100)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(Double(index) * 0.08), value: appear)
                }
            }
            .padding(.horizontal, 30)
            
            // Emoji combos
            if !insights.emojiDeepDive.emojiCombos.isEmpty {
                VStack(spacing: 8) {
                    Text("Your Signature Combos")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    HStack(spacing: 12) {
                        ForEach(insights.emojiDeepDive.emojiCombos.prefix(3)) { combo in
                            Text(combo.combo)
                                .font(.title2)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.1)))
                        }
                    }
                }
                .offset(y: appear ? 0 : 20)
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
}

// MARK: - Temporal Fingerprint Slide

struct TemporalFingerprintSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var chronotype: String {
        insights.temporalFingerprint.isNightOwl ? "🦉 Night Owl" : "🌅 Early Bird"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Your Temporal Rhythms")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            // Chronotype badge
            Text(chronotype)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(appear ? 1 : 0.5)
            
            // Work-life balance meter
            VStack(spacing: 8) {
                Text("Work-Life Balance")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(insights.temporalFingerprint.workLifeBalance))
                    }
                }
                .frame(height: 20)
                
                HStack {
                    Text("Work Hours")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Spacer()
                    Text("Personal Time")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 40)
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)
            
            // Hourly distribution chart
            VStack(spacing: 8) {
                Text("When You're Most Active")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<24, id: \.self) { hour in
                        let value = insights.temporalFingerprint.hourlyDistribution[hour] ?? 0
                        let maxValue = insights.temporalFingerprint.hourlyDistribution.values.max() ?? 1
                        let height = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
                        let isSleep = hour >= insights.temporalFingerprint.inferredSleepStart || hour < insights.temporalFingerprint.inferredSleepEnd
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isSleep ? Color.purple.opacity(0.5) : Color.cyan)
                            .frame(height: max(4, height * 60))
                    }
                }
                .frame(height: 60)
                
                HStack {
                    Text("12am")
                    Spacer()
                    Text("6am")
                    Spacer()
                    Text("12pm")
                    Spacer()
                    Text("6pm")
                    Spacer()
                    Text("12am")
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 30)
            .offset(y: appear ? 0 : 30)
            .opacity(appear ? 1 : 0)
            
            // Sleep inference
            Text("Inferred sleep: \(formatHour(insights.temporalFingerprint.inferredSleepStart)) - \(formatHour(insights.temporalFingerprint.inferredSleepEnd))")
                .font(.caption)
                .foregroundColor(.purple)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(.purple.opacity(0.2)))
            
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
}

// MARK: - Connection Patterns Slide

struct ConnectionPatternsSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Connection Patterns")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Text("Ghosting, reconnections, and more")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            ScrollView {
                VStack(spacing: 20) {
                    // Check if we have any data to show
                    let hasData = !insights.connectionPatterns.ghostingEvents.isEmpty ||
                                  !insights.connectionPatterns.reconnections.isEmpty ||
                                  !insights.connectionPatterns.fadeOuts.isEmpty ||
                                  !insights.connectionPatterns.intenseConversations.isEmpty
                    
                    if !hasData {
                        // Empty state
                        VStack(spacing: 16) {
                            Text("✨")
                                .font(.system(size: 60))
                            Text("No drama detected!")
                                .font(.title3)
                                .foregroundColor(.white)
                            Text("Your conversations flow smoothly without ghosting or reconnection patterns.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(40)
                    } else {
                        // Ghosting events
                        if !insights.connectionPatterns.ghostingEvents.isEmpty {
                            PatternSection(
                                icon: "👻",
                                title: "Ghosting Events",
                                subtitle: "Gaps > 7 days",
                                count: insights.connectionPatterns.ghostingEvents.count,
                                appear: appear
                            )
                        }
                        
                        // Reconnections
                        if !insights.connectionPatterns.reconnections.isEmpty {
                            PatternSection(
                                icon: "🔄",
                                title: "Reconnections",
                                subtitle: "Who reached out after silence",
                                count: insights.connectionPatterns.reconnections.count,
                                appear: appear
                            )
                        }
                        
                        // Fade outs
                        if !insights.connectionPatterns.fadeOuts.isEmpty {
                            PatternSection(
                                icon: "📉",
                                title: "Fade Outs",
                                subtitle: "Gradually decreasing conversations",
                                count: insights.connectionPatterns.fadeOuts.count,
                                appear: appear
                            )
                        }
                        
                        // Intense conversations
                        IntenseConversationsSection(
                            conversations: insights.connectionPatterns.intenseConversations,
                            appear: appear
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                appear = true
            }
        }
    }
}

struct IntenseConversationsSection: View {
    let conversations: [ConversationStreak]
    let appear: Bool
    
    var body: some View {
        if !conversations.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("🔥")
                        .font(.title2)
                    Text("Most Intense Conversations")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ForEach(conversations.prefix(3)) { convo in
                    IntenseConvoRow(convo: convo)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.03)))
            .offset(y: appear ? 0 : 30)
            .opacity(appear ? 1 : 0)
        }
    }
}

struct IntenseConvoRow: View {
    let convo: ConversationStreak
    
    var body: some View {
        HStack {
            Text(convo.displayName)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(convo.messageCount) msgs in \(convo.durationMinutes) min")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(.orange.opacity(0.1)))
    }
}

struct PatternSection: View {
    let icon: String
    let title: String
    let subtitle: String
    let count: Int
    let appear: Bool
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.system(size: 40))
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.title.bold())
                .foregroundColor(.cyan)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
        .offset(x: appear ? 0 : 50)
        .opacity(appear ? 1 : 0)
    }
}

// MARK: - AI Revelations Slide

struct AIRevelationsSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(LinearGradient(colors: [.purple, .pink, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    Text("AI Revelations")
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
                
                Text("Mind-blowing observations from your messages")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 20)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
            
            // Dashboard Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    if !insights.aiRevelations.isEmpty {
                        // First item is full width if we have odd number
                        if insights.aiRevelations.count % 2 != 0, let first = insights.aiRevelations.first {
                            RevelationCard(revelation: first, isLarge: true)
                                .gridCellColumns(2)
                                .offset(y: appear ? 0 : 30)
                                .opacity(appear ? 1 : 0)
                                .animation(.spring(response: 0.6).delay(0.1), value: appear)
                            
                            ForEach(Array(insights.aiRevelations.dropFirst().enumerated()), id: \.element.id) { index, revelation in
                                RevelationCard(revelation: revelation)
                                    .offset(y: appear ? 0 : 30)
                                    .opacity(appear ? 1 : 0)
                                    .animation(.spring(response: 0.6).delay(0.1 + Double(index + 1) * 0.1), value: appear)
                            }
                        } else {
                            ForEach(Array(insights.aiRevelations.enumerated()), id: \.element.id) { index, revelation in
                                RevelationCard(revelation: revelation)
                                    .offset(y: appear ? 0 : 30)
                                    .opacity(appear ? 1 : 0)
                                    .animation(.spring(response: 0.6).delay(Double(index) * 0.1), value: appear)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Text("🔮")
                                .font(.system(size: 60))
                            Text("The crystal ball is cloudy...")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Keep chatting to reveal more secrets.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .gridCellColumns(2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
}

struct RevelationCard: View {
    let revelation: AIRevelation
    var isLarge: Bool = false
    
    var typeEmoji: String {
        switch revelation.type {
        case .comparison: return "⚖️"
        case .relationship: return "💕"
        case .pattern: return "📊"
        case .superlative: return "🏆"
        case .quirk: return "🎭"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(revelation.icon)
                    .font(.system(size: isLarge ? 40 : 32))
                    .padding(12)
                    .background(Circle().fill(.white.opacity(0.1)))
                
                Spacer()
                
                Text(typeEmoji)
                    .font(.caption)
                    .padding(6)
                    .background(Circle().fill(.black.opacity(0.3)))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(revelation.headline)
                    .font(isLarge ? .title3.bold() : .headline)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(revelation.detail)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(isLarge ? 4 : 3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            categoryColor(revelation.type).opacity(0.2),
                            Color(red: 0.1, green: 0.1, blue: 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    func categoryColor(_ type: AIRevelation.RevealCategory) -> Color {
        switch type {
        case .comparison: return .blue
        case .relationship: return .pink
        case .pattern: return .purple
        case .superlative: return .yellow
        case .quirk: return .orange
        }
    }
}

// MARK: - Share Slide

struct ShareSlide: View {
    let insights: WrappedInsights
    let analytics: MessageAnalytics
    let messages: [Message]

    @State private var appear = false
    @State private var showingShareSheet = false
    @State private var selectedCardType: ShareCardData.CardType = .summary
    
    // Export state
    @State private var includeInsights = true
    @State private var includeConversations = false
    @State private var isExportingInsights = false
    @State private var isExportingConversations = false
    @State private var insightsDoc: TextFile?
    @State private var conversationsDoc: TextFile?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Your Wrapped Summary")
                .font(.title.bold())
                .foregroundColor(.white)
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)
            
            // Mini card preview
            ShareCardView(
                cardData: ShareCardData(type: selectedCardType),
                insights: insights
            )
            .scaleEffect(0.6)
            .frame(height: 260)
            .offset(y: appear ? 0 : 30)
            .opacity(appear ? 1 : 0)
            
            // Card type selector
            HStack(spacing: 10) {
                ForEach([ShareCardData.CardType.summary, .personality, .emoji, .vibe], id: \.self) { type in
                    Button {
                        withAnimation { selectedCardType = type }
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(selectedCardType == type ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(selectedCardType == type ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)
            
            // Export Section
            VStack(spacing: 16) {
                Text("Export Your Data")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    Toggle(isOn: $includeInsights) {
                        Text("Insights")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    
                    Toggle(isOn: $includeConversations) {
                        Text("Raw Conversations")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                }
                
                Button(action: startExport) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Download .txt")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [.cyan, .green], startPoint: .leading, endPoint: .trailing)
                        )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!includeInsights && !includeConversations)
                .opacity(!includeInsights && !includeConversations ? 0.5 : 1.0)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.05)))
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)
            
            // Original Share Button
            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Image")
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)
            
            Spacer()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheetView(insights: insights)
        }
        .fileExporter(
            isPresented: $isExportingInsights,
            document: insightsDoc,
            contentType: .plainText,
            defaultFilename: "iMessageInsights.txt"
        ) { result in
            if case .success = result {
                if includeConversations {
                    prepareConversationsExport()
                }
            }
        }
        .fileExporter(
            isPresented: $isExportingConversations,
            document: conversationsDoc,
            contentType: .plainText,
            defaultFilename: "iMessageRawConversations.txt"
        ) { _ in }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
    
    private func startExport() {
        if includeInsights {
            prepareInsightsExport()
        } else if includeConversations {
            prepareConversationsExport()
        }
    }
    
    private func prepareInsightsExport() {
        var text = "iMessage Wrapped: \(analytics.timePeriodDays) Day Review\n"
        text += "========================================\n\n"
        
        text += "--- OVERALL STATS ---\n"
        text += "Total Messages: \(analytics.totalMessages)\n"
        text += "Sent: \(analytics.messagesSent)\n"
        text += "Received: \(analytics.messagesReceived)\n"
        text += "Daily Average: \(String(format: "%.1f", analytics.messagesPerDay))\n\n"
        
        text += "--- TOP CONTACTS ---\n"
        for (index, contact) in analytics.topContacts.prefix(5).enumerated() {
            text += "\(index + 1). \(contact.displayName): \(contact.totalMessages) messages (\(contact.messagesSent) sent, \(contact.messagesReceived) received)\n"
        }
        text += "\n"
        
        text += "--- TOP EMOJIS ---\n"
        for emoji in analytics.topEmojis.prefix(10) {
            text += "\(emoji.emoji): \(emoji.count) times\n"
        }
        text += "\n"
        
        text += "--- COMMUNICATION DNA ---\n"
        text += "Personality Header: \(insights.communicationDNA.personalityLabel)\n"
        text += "Emoji Density: \(String(format: "%.2f", insights.communicationDNA.emojiDensity)) per message\n"
        text += "Avg Message Length: \(String(format: "%.1f", insights.communicationDNA.averageMessageLength)) chars\n"
        text += "Expressiveness: \(Int(insights.communicationDNA.expressiveness * 100))%\n"
        text += "Punctuation Style: \(insights.communicationDNA.punctuationStyle.rawValue)\n\n"
        
        text += "--- YOUR WORLD ---\n"
        text += "Places: \(insights.worldMap.places.prefix(5).map { $0.name }.joined(separator: ", "))\n"
        text += "People Mentioned: \(insights.worldMap.people.prefix(5).map { $0.name }.joined(separator: ", "))\n"
        text += "Organizations: \(insights.worldMap.organizations.prefix(5).map { $0.name }.joined(separator: ", "))\n\n"
        
        text += "--- EMOJI DEEP DIVE ---\n"
        text += "Unique Emojis Used: \(insights.emojiDeepDive.uniqueEmojiCount)\n"
        text += "Total Emojis: \(insights.emojiDeepDive.totalEmojiCount)\n"
        text += "Signature Combos: \(insights.emojiDeepDive.emojiCombos.prefix(3).map { $0.combo }.joined(separator: ", "))\n\n"
        
        insightsDoc = TextFile(text: text)
        isExportingInsights = true
    }
    
    private func prepareConversationsExport() {
        var text = "iMessage Raw Conversation History (\(analytics.timePeriodDays) days)\n"
        text += "========================================\n\n"
        
        let sortedMessages = messages.sorted { $0.date < $1.date }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        for message in sortedMessages {
            let sender = message.isFromMe ? "Me" : (message.chatName ?? message.handleId ?? "Them")
            let timestamp = dateFormatter.string(from: message.date)
            let content = message.text ?? "[Attachment or Empty]"
            text += "[\(timestamp)] \(sender): \(content)\n"
        }
        
        conversationsDoc = TextFile(text: text)
        isExportingConversations = true
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .cyan : .white.opacity(0.3))
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Consolidated Slides (6-Screen Flow)

struct IntroStatsSlide: View {
    let analytics: MessageAnalytics
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Intro Header
            VStack(spacing: 12) {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("iMessage Wrapped")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Text(verbatim: "\(Calendar.current.component(.year, from: Date())) Year in Review")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
                

            }
            .scaleEffect(appear ? 1 : 0.8)
            .opacity(appear ? 1 : 0)
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                StatBox(value: analytics.totalMessages, label: "Total Messages", icon: "bubble.left.fill", color: .blue)
                StatBox(value: Int(analytics.messagesPerDay), label: "Daily Avg", icon: "calendar", color: .green)
                StatBox(value: analytics.messagesSent, label: "Sent", icon: "arrow.up.circle.fill", color: .cyan)
                StatBox(value: analytics.messagesReceived, label: "Received", icon: "arrow.down.circle.fill", color: .purple)
            }
            .padding(.horizontal, 30)
            .offset(y: appear ? 0 : 50)
            .opacity(appear ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { appear = true }
        }
    }
}

struct TopConnectionSlide: View {
    let analytics: MessageAnalytics
    let insights: WrappedInsights
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if let topDynamic = insights.relationshipDynamics.first {
                // Top Friend Header
                VStack(spacing: 16) {
                    Text("Your #1 Connection")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)
                            .shadow(color: .orange.opacity(0.5), radius: 20)
                        
                        Text(String(topDynamic.displayName.prefix(1)).uppercased())
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text(topDynamic.displayName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(topDynamic.totalMessages) messages")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.1)))
                }
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)
                
                // Dynamics Card
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        DynamicStat(label: "Vibe", value: topDynamic.connectionStrength, icon: "sparkles")
                        DynamicStat(label: "Initiative", value: topDynamic.initiativeScore > 0 ? "You Lead" : "They Lead", icon: "arrow.left.arrow.right")
                    }
                    
                    // Fallback for missing/empty relationship label
                    let label = topDynamic.relationshipLabel.isEmpty ? "Bestie" : topDynamic.relationshipLabel
                    Text("Relationship: \(label)")
                        .font(.subheadline)
                        .foregroundColor(.cyan)
                }
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.05)))
                .offset(y: appear ? 0 : 50)
                .opacity(appear ? 1 : 0)
                
            } else {
                Text("No data available")
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { appear = true }
        }
    }
}

struct DynamicStat: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct CrewSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("The Squad")
                .font(.title.bold())
                .foregroundColor(.white)
            
            // Podium
            HStack(alignment: .bottom, spacing: 12) {
                let dynamics = Array(insights.relationshipDynamics.prefix(3))
                if dynamics.count > 1 {
                    PodiumAvatar(contact: dynamics[1], rank: 2, delay: 0.1, appear: appear)
                }
                if let top = dynamics.first {
                    PodiumAvatar(contact: top, rank: 1, delay: 0.2, appear: appear)
                }
                if dynamics.count > 2 {
                    PodiumAvatar(contact: dynamics[2], rank: 3, delay: 0.3, appear: appear)
                }
            }
            .frame(height: 180)
            
            // Insight List
            VStack(spacing: 12) {
                ForEach(Array(insights.relationshipDynamics.prefix(6).enumerated()), id: \.element.id) { index, contact in
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.displayName.isEmpty ? "Unknown" : contact.displayName)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Vibe Badge
                            Text(contact.vibeCategory)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.purple.opacity(0.3)))
                                .foregroundColor(.purple.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(contact.totalMessages) msgs")
                                .font(.subheadline.bold())
                                .foregroundColor(.white.opacity(0.9))
                            
                            HStack(spacing: 6) {
                                // Initiative Badge
                                if abs(contact.initiativeScore) > 0.3 {
                                    Label(contact.initiativeScore > 0 ? "You Lead" : "They Lead", systemImage: "arrow.left.arrow.right")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                // Chaos Badge
                                if contact.chaosScore > 0.6 {
                                    Label("Chaotic", systemImage: "tornado")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
                    .offset(x: appear ? 0 : 50)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.4), value: appear)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { appear = true }
        }
    }
}

struct PodiumAvatar: View {
    let contact: RelationshipDynamics
    let rank: Int
    let delay: Double
    let appear: Bool
    
    var color: Color {
        rank == 1 ? .yellow : (rank == 2 ? .gray : .orange)
    }
    
    var displayName: String {
        contact.displayName.isEmpty ? "Unknown" : contact.displayName
    }
    
    var body: some View {
        VStack {
            Text(displayName)
                .font(.caption.bold())
                .foregroundColor(.white)
                .lineLimit(1)
            
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [color.opacity(0.8), color.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                    .frame(width: rank == 1 ? 80 : 60, height: rank == 1 ? 80 : 60)
                
                Text(String(displayName.prefix(1)))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.3))
                .frame(width: rank == 1 ? 90 : 70, height: rank == 1 ? 80 : 50)
                .overlay(Text("#\(rank)").font(.headline).foregroundColor(color))
        }
        .offset(y: appear ? 0 : 100)
        .opacity(appear ? 1 : 0)
        .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(delay), value: appear)
    }
}

struct ContentSlide: View {
    let insights: WrappedInsights
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Spacer()
            
            // Your World (Named Entities Analysis)
            YourWorldSlide(insights: insights)
                .frame(maxHeight: 400)
            
            Divider().background(Color.white.opacity(0.1))

            
            // Top Emojis
            VStack(spacing: 12) {
                Text("Top Emojis")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 20) {
                    ForEach(insights.emojiDeepDive.topEmojis.prefix(5)) { emoji in
                        Text(emoji.emoji)
                            .font(.system(size: 40))
                    }
                }
            }
            .padding(.bottom, 30)
            
            Spacer()
        }
    }
}

struct IdentitySlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Your Profile")
                .font(.title.bold())
                .foregroundColor(.white)
            
            vibeCheckSection
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)
            
            dnaAnalysisSection
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.05)))
                .offset(y: appear ? 0 : 50)
                .opacity(appear ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { appear = true }
        }
    }
    
    var vibeCheckSection: some View {
        VStack(spacing: 8) {
            Text("Vibe Check")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            Text(vibeEmoji(for: insights.sentimentScore))
                .font(.system(size: 80))
            
            Text("Positivity: \(Int((insights.sentimentScore + 1) / 2 * 100))%")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    var dnaAnalysisSection: some View {
        VStack(spacing: 16) {
            DNAInfoRow(label: "Style", value: insights.communicationDNA.personalityLabel)
            DNAInfoRow(label: "Avg Length", value: "\(Int(insights.communicationDNA.averageMessageLength)) chars")
            DNAInfoRow(label: "Response Time", value: "\(Int(insights.communicationDNA.avgResponseTimeMinutes ?? 0)) mins")
            DNAInfoRow(label: "Chronotype", value: String(insights.temporalFingerprint.chronotype.dropFirst(2)))
        }
    }
    
    func vibeEmoji(for score: Double) -> String {
        switch score {
        case 0.5...: return "🌟"
        case 0.2..<0.5: return "😊"
        case -0.2..<0.2: return "😌"
        case -0.5..<(-0.2): return "😔"
        default: return "🌧️"
        }
    }
}

struct DNAInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
        Divider().background(Color.white.opacity(0.1))
    }
}

// MARK: - Previews

#Preview("Communication DNA") {
    ZStack {
        Color.black.ignoresSafeArea()
        CommunicationDNASlide(insights: WrappedInsights.preview)
    }
}

#Preview("AI Revelations") {
    ZStack {
        Color.black.ignoresSafeArea()
        AIRevelationsSlide(insights: WrappedInsights.preview)
    }
}

// MARK: - New 10-Screen Flow Slides

/// Slide 2: The Grind (Activity Heatmap)
struct ActivitySlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("The Grind")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("When you're most active")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            // Peak Time Stat
            VStack(spacing: 8) {
                Text(insights.temporalFingerprint.isNightOwl ? "🦉 Night Owl" : "🌅 Early Bird")
                    .font(.system(size: 36, weight: .bold))
                
                Text(insights.temporalFingerprint.isNightOwl ? "You come alive after dark" : "You seize the day")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
            .offset(y: appear ? 0 : 30)
            .opacity(appear ? 1 : 0)
            
            // Hourly Heatmap (Simplified)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<24) { hour in
                    let count = insights.temporalFingerprint.hourlyDistribution[hour] ?? 0
                    let maxCount = insights.temporalFingerprint.hourlyDistribution.values.max() ?? 1
                    let height = CGFloat(count) / CGFloat(maxCount) * 100
                    
                    VStack {
                        Spacer()
                        Capsule()
                            .fill(hour >= 9 && hour <= 17 ? Color.blue : Color.purple)
                            .frame(width: 8, height: max(4, height))
                    }
                }
            }
            .frame(height: 120)
            .padding(.horizontal)
            .offset(y: appear ? 0 : 50)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.2), value: appear)
            
            Spacer()
        }
        .onAppear { withAnimation { appear = true } }
    }
}

/// Slide 5: Semantic Vibe Check
struct SemanticVibeSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    // Group relationships by vibe
    var vibeGroups: [String: [RelationshipDynamics]] {
        Dictionary(grouping: insights.relationshipDynamics, by: { $0.vibeCategory })
    }
    
    var dominantVibe: String {
        vibeGroups.max(by: { $0.value.count < $1.value.count })?.key ?? "Neutral"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("The Vibe")
                .font(.title.bold())
                .foregroundColor(.white)
                .padding(.top)
            
            Text("We analyzed the 'Soul' of your chats")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            
            // Dominant Vibe Hero
            VStack(spacing: 16) {
                Text(vibeEmoji(for: dominantVibe))
                    .font(.system(size: 100))
                    .shadow(color: vibeColor(for: dominantVibe).opacity(0.5), radius: 20)
                
                Text(dominantVibe)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [vibeColor(for: dominantVibe), .white], startPoint: .top, endPoint: .bottom))
                
                Text("Your dominant chat energy")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .scaleEffect(appear ? 1 : 0.5)
            .opacity(appear ? 1 : 0)
            
            // Vibe Clusters
            VStack(spacing: 12) {
                ForEach(Array(vibeGroups.prefix(3)), id: \.key) { vibe, contacts in
                    if vibe != dominantVibe {
                        HStack {
                            Text(vibeEmoji(for: vibe))
                                .font(.title)
                            Text(vibe)
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(contacts.count) chats")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.05)))
                        .offset(x: appear ? 0 : 50)
                        .opacity(appear ? 1 : 0)
                    }
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .onAppear { withAnimation(.spring(response: 0.7)) { appear = true } }
    }
    
    func vibeEmoji(for vibe: String) -> String {
        switch vibe {
        case "Hype": return "🔥"
        case "Intellectual": return "🧠"
        case "Supportive": return "🥰"
        case "Planning": return "📅"
        case "Chaos": return "🌪️"
        case "Flirty": return "🫦"
        default: return "✨"
        }
    }
    
    func vibeColor(for vibe: String) -> Color {
        switch vibe {
        case "Hype": return .orange
        case "Intellectual": return .blue
        case "Supportive": return .pink
        case "Planning": return .green
        case "Chaos": return .red
        case "Flirty": return .purple
        default: return .white
        }
    }
}

/// Slide 8: Texting Style (Comm DNA + Analytics)
struct StyleSlide: View {
    let insights: WrappedInsights
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Communication Style")
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                DNAStatCard(icon: "timer", value: "\(Int(insights.communicationDNA.avgResponseTimeMinutes ?? 0))m", label: "Avg Reply", color: .cyan)
                DNAStatCard(icon: "text.bubble", value: "\(Int(insights.communicationDNA.averageMessageLength))", label: "Chars/Msg", color: .green)
                DNAStatCard(icon: "bolt.fill", value: "\(Int((insights.communicationDNA.expressiveness) * 100))%", label: "Energy", color: .yellow)
                DNAStatCard(icon: "questionmark.circle", value: "\(Int(insights.communicationDNA.questionToStatementRatio * 100))%", label: "Curiosity", color: .purple)
            }
            .padding(.horizontal)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
            
            Spacer()
        }
        .onAppear { withAnimation(.spring()) { appear = true } }
    }
}

/// Slide 9: Persona (The Verdict)
struct PersonaSlide: View {
    let insights: WrappedInsights
    
    var body: some View {
        CommunicationDNASlide(insights: insights)
    }
}
