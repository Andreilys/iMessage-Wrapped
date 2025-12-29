import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WrappedViewModel()
    @State private var showingPermissionAlert = false
    @State private var selectedTimeRange: Int = 365 // Default to Year in Review
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                if viewModel.isAIGenerated {
                    AILoadingView()
                } else {
                    LoadingView()
                }
            } else if viewModel.hasData {
                InsightsTabContainer(viewModel: viewModel)
            } else {
                LandingPageView(
                    viewModel: viewModel,
                    showingPermissionAlert: $showingPermissionAlert,
                    selectedTimeRange: $selectedTimeRange
                )
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("Full Disk Access Required", isPresented: $showingPermissionAlert) {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("iMessage Wrapped needs Full Disk Access to read your messages.\n\nGo to System Settings → Privacy & Security → Full Disk Access and enable it for this app.")
        }
        .onAppear {
            if !iMessageDatabaseReader.checkFullDiskAccess() {
                showingPermissionAlert = true
            }
        }
    }
}

// MARK: - Landing Page

struct LandingPageView: View {
    @ObservedObject var viewModel: WrappedViewModel
    @Binding var showingPermissionAlert: Bool
    @Binding var selectedTimeRange: Int
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingResetConfirmation = false
    @State private var iconFloat = false
    
    var body: some View {
        ZStack {
            // Premium Dark Background
            LinearGradient(
                colors: [
                    Color(hex: "0F172A"),
                    Color(hex: "1E1B4B")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Ambient orbs
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: -150, y: -100)
                
                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: 150, y: 200)
            }
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Spacer()
                    Menu {
                        // General Settings
                        Section {
                            Button(action: { hasCompletedOnboarding = false }) {
                                Label("Show Welcome Screen", systemImage: "arrow.counterclockwise")
                            }
                            Button(action: { showingPermissionAlert = true }) {
                                Label("Full Disk Access Help", systemImage: "lock.shield")
                            }
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.3))
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.05)))
                    }
                    .menuStyle(.borderlessButton)
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Hero Section
                VStack(spacing: 12) {
                    // Floating animated icon
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.3), radius: 20)
                        .offset(y: iconFloat ? -8 : 8)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: iconFloat)
                    
                    Text("iMessage Wrapped")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Discover your messaging year in review")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                // Step 1: Range Selection
                VStack(alignment: .leading, spacing: 15) {
                    Label("Select Time Period", systemImage: "calendar")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.leading, 4)
                    
                    HStack(spacing: 12) {
                        TimeRangeButton(days: 7, label: "Last Week", selected: selectedTimeRange == 7) { selectedTimeRange = 7 }
                        TimeRangeButton(days: 30, label: "Last Month", selected: selectedTimeRange == 30) { selectedTimeRange = 30 }
                        TimeRangeButton(days: 365, label: "Year in Review", selected: selectedTimeRange == 365) { selectedTimeRange = 365 }
                    }
                }
                .padding(.horizontal, 40)
                
                // Analyze Button
                Button(action: {
                    viewModel.loadData(days: selectedTimeRange, isAI: true)
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title3)
                        Text("Analyze My Messages")
                            .font(.title3.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.3), radius: 20)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button("Need Full Disk Access?") { showingPermissionAlert = true }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            iconFloat = true
        }
    }
}


// MARK: - Components

struct TimeRangeButton: View {
    let days: Int
    let label: String
    let selected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(selected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selected ? Color.blue.opacity(0.3) : Color.white.opacity(isHovered ? 0.08 : 0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? Color.blue.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

struct AnalysisTypeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isPremium: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var shimmerPhase: CGFloat = 0
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(
                            isPremium
                                ? AnyShapeStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color.white)
                        )
                    
                    Spacer()
                    
                    if isPremium {
                        // Shimmering AI badge
                        Text("AI")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.4), .cyan.opacity(0.4)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.purple, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .overlay(
                                // Shimmer effect
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.clear, .white.opacity(0.3), .clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .offset(x: shimmerPhase * 40 - 20)
                                    .mask(Capsule())
                            )
                            .foregroundStyle(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isHovered ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isPremium && isHovered
                            ? AnyShapeStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.white.opacity(isHovered ? 0.2 : 0.1)),
                        lineWidth: isPremium && isHovered ? 2 : 1
                    )
            )
            .shadow(color: isPremium && isHovered ? Color.purple.opacity(0.3) : .clear, radius: 15)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .onAppear {
            if isPremium {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }
        }
    }
}

// MARK: - AI Loading View

struct AILoadingView: View {
    @StateObject private var analyzer = AdvancedAIAnalyzer.shared
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0
    @State private var particleOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dark background with ambient glow
            Color(hex: "0A0A1A").ignoresSafeArea()
            
            // Animated background orbs
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 350, height: 350)
                    .blur(radius: 80)
                    .offset(x: -100, y: -150)
                    .opacity(pulse)
                
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 300, height: 300)
                    .blur(radius: 70)
                    .offset(x: 120, y: 100)
                    .opacity(pulse)
                
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: -80, y: 180)
                    .opacity(pulse)
            }
            
            VStack(spacing: 50) {
                // Animated Loading Indicator
                ZStack {
                    // Outer rotating rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [.cyan.opacity(0), .cyan, .purple, .purple.opacity(0)],
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 110 + CGFloat(i * 35), height: 110 + CGFloat(i * 35))
                            .rotationEffect(.degrees(i % 2 == 0 ? rotation : -rotation))
                            .opacity(0.4 + (0.2 * Double(2 - i)))
                    }
                    
                    // Inner pulsing circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.cyan.opacity(0.3), .purple.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulse)
                    
                    // Center icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(pulse * 0.9 + 0.1)
                }
                
                // Status Text
                VStack(spacing: 16) {
                    Text(analyzer.currentStep.isEmpty ? "Initializing Neural Engine..." : analyzer.currentStep)
                        .font(.title3.weight(.medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.3), value: analyzer.currentStep)
                    
                    // Progress bar
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Background track
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)
                                
                                // Progress fill
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.cyan, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * analyzer.progress, height: 6)
                                    .animation(.easeInOut(duration: 0.5), value: analyzer.progress)
                            }
                        }
                        .frame(height: 6)
                        .frame(maxWidth: 280)
                        
                        Text("\(Int(analyzer.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .monospacedDigit()
                    }
                    
                    Text("Analyzing your messages with on-device AI")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(40)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = 1.15
            }
        }
    }
}

// MARK: - Standard Loading View

struct LoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A1A").ignoresSafeArea()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotation))
                }
                
                Text("Loading Analytics...")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    ContentView()
}
