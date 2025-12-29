import SwiftUI

// MARK: - Single Welcome Screen Onboarding

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var appear = false
    @State private var showFeatures = false
    @State private var iconPulse = false
    
    var body: some View {
        ZStack {
            // Premium dark gradient background
            LinearGradient(
                colors: [
                    Color(hex: "0F0F23"),
                    Color(hex: "1a1a3e"),
                    Color(hex: "0F172A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Ambient glow orbs
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -80, y: -200)
                
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 350, height: 350)
                    .blur(radius: 90)
                    .offset(x: 100, y: 150)
                
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .offset(x: -120, y: 200)
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Hero Section
                VStack(spacing: 24) {
                    // Animated Icon
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 140, height: 140)
                            .scaleEffect(iconPulse ? 1.1 : 1.0)
                            .opacity(iconPulse ? 0.5 : 0.8)
                        
                        // Inner glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.blue.opacity(0.2), .clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 130, height: 130)
                        
                        // Message icon
                        Image(systemName: "message.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 15)
                    }
                    .scaleEffect(appear ? 1 : 0.5)
                    .opacity(appear ? 1 : 0)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("iMessage Wrapped")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Your Year in Messages")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .offset(y: appear ? 0 : 20)
                    .opacity(appear ? 1 : 0)
                }
                
                Spacer().frame(height: 50)
                
                // Feature Cards
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "chart.bar.fill",
                        title: "Beautiful Analytics",
                        description: "Stunning visualizations of your messaging patterns",
                        gradient: [.blue, .cyan]
                    )
                    .offset(x: showFeatures ? 0 : -50)
                    .opacity(showFeatures ? 1 : 0)
                    
                    FeatureCard(
                        icon: "sparkles",
                        title: "AI-Powered Insights",
                        description: "Deep analysis using Apple's Neural Engine",
                        gradient: [.purple, .pink]
                    )
                    .offset(x: showFeatures ? 0 : -50)
                    .opacity(showFeatures ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.1), value: showFeatures)
                    
                    FeatureCard(
                        icon: "lock.shield.fill",
                        title: "100% Private",
                        description: "Everything stays on your device, always",
                        gradient: [.green, .mint]
                    )
                    .offset(x: showFeatures ? 0 : -50)
                    .opacity(showFeatures ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.2), value: showFeatures)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Get Started Button
                VStack(spacing: 16) {
                    Button(action: completeOnboarding) {
                        HStack(spacing: 10) {
                            Text("Get Started")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .purple.opacity(0.4), radius: 15, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 30)
                    .offset(y: showFeatures ? 0 : 30)
                    .opacity(showFeatures ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.4), value: showFeatures)
                    
                    Text("Full Disk Access required to read messages")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .opacity(showFeatures ? 1 : 0)
                        .animation(.easeOut.delay(0.5), value: showFeatures)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
            
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                iconPulse = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showFeatures = true
                }
            }
        }
    }
    
    func completeOnboarding() {
        withAnimation(.spring()) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - AI Option Enum (kept for compatibility)

enum AIOption: String, CaseIterable {
    case none = "none"
    case local = "local"
    case claude = "claude"
    case openai = "openai"
    
    var displayName: String {
        switch self {
        case .none: return "No AI"
        case .local: return "Local AI"
        case .claude: return "Claude"
        case .openai: return "OpenAI"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "chart.bar.fill"
        case .local: return "desktopcomputer"
        case .claude: return "sparkles"
        case .openai: return "brain.head.profile"
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
