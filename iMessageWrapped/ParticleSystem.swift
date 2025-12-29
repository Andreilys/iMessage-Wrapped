import SwiftUI

// MARK: - Particle System

/// Reusable particle effect system for confetti, sparkles, and other animations
struct ParticleSystem: View {
    let type: ParticleType
    @State private var particles: [Particle] = []
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ParticleView(particle: particle, type: type)
            }
        }
        .onAppear {
            generateParticles()
            withAnimation(.easeOut(duration: type.duration)) {
                isAnimating = true
            }
        }
    }
    
    private func generateParticles() {
        particles = (0..<type.particleCount).map { _ in
            Particle(
                angle: Double.random(in: 0...360),
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
    case confetti
    case sparkles
    case hearts
    case stars
    
    var particleCount: Int {
        switch self {
        case .confetti: return 50
        case .sparkles: return 30
        case .hearts: return 20
        case .stars: return 25
        }
    }
    
    var speedRange: ClosedRange<Double> {
        switch self {
        case .confetti: return 150...300
        case .sparkles: return 100...200
        case .hearts: return 80...150
        case .stars: return 120...250
        }
    }
    
    var sizeRange: ClosedRange<Double> {
        switch self {
        case .confetti: return 6...12
        case .sparkles: return 4...8
        case .hearts: return 10...16
        case .stars: return 6...12
        }
    }
    
    var distance: Double {
        switch self {
        case .confetti: return 2.0
        case .sparkles: return 1.5
        case .hearts: return 1.2
        case .stars: return 1.8
        }
    }
    
    var duration: Double {
        switch self {
        case .confetti: return 1.2
        case .sparkles: return 1.0
        case .hearts: return 1.5
        case .stars: return 1.3
        }
    }
    
    var shape: AnyShape {
        switch self {
        case .confetti: return AnyShape(RoundedRectangle(cornerRadius: 2))
        case .sparkles: return AnyShape(Circle())
        case .hearts: return AnyShape(Circle())
        case .stars: return AnyShape(Circle())
        }
    }
    
    var color: Color {
        switch self {
        case .confetti: return [.cyan, .purple, .pink, .yellow, .green].randomElement()!
        case .sparkles: return .yellow
        case .hearts: return .pink
        case .stars: return .cyan
        }
    }
}

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ]),
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

extension View {
    func shimmer(duration: Double = 2.0) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
}

// MARK: - Glow Effect

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
    func glow(color: Color = .cyan, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Count Up Animation

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
