import SwiftUI

// MARK: - Claude Settings View

struct ClaudeSettingsView: View {
    @ObservedObject var claudeManager: ClaudeAPIManager
    @State private var apiKey = ""
    @State private var showingKey = false
    @State private var selectedModel: ClaudeModel = .sonnet45
    @State private var setupState: SetupState = .idle
    @State private var showOAuthExplanation = false
    @Environment(\.dismiss) private var dismiss
    
    enum SetupState: Equatable {
        case idle
        case testing
        case success
        case failure(String)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if claudeManager.isConfigured {
                        connectedView
                    } else {
                        setupFlowView
                    }
                    
                    Divider()
                    
                    // Model selection (always visible)
                    modelSelectionSection
                    
                    Divider()
                    
                    // Why no OAuth
                    oauthExplanationSection
                }
                .padding(24)
            }
        }
        .frame(width: 520, height: 650)
        .onAppear {
            if let existingKey = claudeManager.getAPIKey() {
                apiKey = existingKey
            }
        }
    }
    
    // MARK: - Header
    
    var headerView: some View {
        HStack {
            HStack(spacing: 12) {
                // Claude logo/icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Text("C")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Claude AI")
                        .font(.title2.bold())
                    Text(claudeManager.isConfigured ? "Connected" : "Not connected")
                        .font(.caption)
                        .foregroundColor(claudeManager.isConfigured ? .green : .secondary)
                }
            }
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.escape)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Connected View
    
    var connectedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connected to Claude API")
                        .font(.headline)
                    
                    if let info = claudeManager.accountInfo {
                        Text("Key: \(info.keyPrefix)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Manage key
            DisclosureGroup("Manage API Key") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if showingKey {
                            TextField("API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                        } else {
                            SecureField("API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.caption, design: .monospaced))
                        }
                        
                        Button(action: { showingKey.toggle() }) {
                            Image(systemName: showingKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    HStack {
                        Button("Update Key") {
                            updateKey()
                        }
                        .disabled(apiKey.isEmpty)
                        
                        Button("Disconnect", role: .destructive) {
                            claudeManager.deleteAPIKey()
                            apiKey = ""
                        }
                        
                        Spacer()
                        
                        if case .success = setupState {
                            Label("Updated!", systemImage: "checkmark")
                                .foregroundColor(.green)
                        } else if case .failure(let msg) = setupState {
                            Label(msg, systemImage: "xmark")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Setup Flow
    
    var setupFlowView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Hero section
            VStack(spacing: 16) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Connect to Claude")
                    .font(.title2.bold())
                
                Text("Analyze your full year of messages with Claude's 200K context window")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            
            // Quick setup steps
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Setup")
                    .font(.headline)
                
                SetupStepRow(
                    number: 1,
                    title: "Open Anthropic Console",
                    subtitle: "Sign up or log in to get API access",
                    action: {
                        claudeManager.openAnthropicConsole()
                    },
                    actionLabel: "Open Console"
                )
                
                SetupStepRow(
                    number: 2,
                    title: "Create an API Key",
                    subtitle: "Go to Settings → API Keys → Create Key",
                    action: {
                        claudeManager.openAPIKeysPage()
                    },
                    actionLabel: "Go to API Keys"
                )
                
                SetupStepRow(
                    number: 3,
                    title: "Paste Your Key Below",
                    subtitle: "Your key is stored securely in Keychain",
                    action: nil,
                    actionLabel: nil
                )
            }
            
            // API Key input
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.subheadline.bold())
                
                HStack {
                    Group {
                        if showingKey {
                            TextField("sk-ant-api03-...", text: $apiKey)
                        } else {
                            SecureField("sk-ant-api03-...", text: $apiKey)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    
                    Button(action: { showingKey.toggle() }) {
                        Image(systemName: showingKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
                
                // Connect button
                HStack {
                    Button(action: connectWithKey) {
                        HStack {
                            if case .testing = setupState {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "link")
                            }
                            Text(setupState == .testing ? "Connecting..." : "Connect")
                        }
                        .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(apiKey.isEmpty || !apiKey.hasPrefix("sk-ant-") || setupState == .testing)
                    
                    if case .failure(let message) = setupState {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            
            // First $5 free note
            HStack {
                Image(systemName: "gift")
                    .foregroundColor(.green)
                Text("New accounts get $5 free API credits")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Model Selection
    
    var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Model Selection", systemImage: "cpu")
                .font(.headline)
            
            ForEach(ClaudeModel.allCases, id: \.self) { model in
                ModelOptionRow(
                    model: model,
                    isSelected: selectedModel == model,
                    onSelect: { selectedModel = model }
                )
            }
        }
    }
    
    // MARK: - OAuth Explanation
    
    var oauthExplanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { showOAuthExplanation.toggle() }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Why can't I use my Claude Pro/Max subscription?")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: showOAuthExplanation ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            if showOAuthExplanation {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Claude Pro/Max vs API Credits")
                        .font(.subheadline.bold())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("**Claude Pro/Max** ($20-100/mo): For claude.ai web/app, unlimited use within limits")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text("**API Credits** (pay-per-use): For developers building apps like this one")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text("Anthropic restricts OAuth to first-party apps. When third-party apps try OAuth, they get: *\"This credential is only authorized for use with Claude Code.\"*")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("The good news: API usage is very affordable (~$0.01-0.50 for a full iMessage analysis), and new accounts get $5 free!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
        }
    }
    
    // MARK: - Actions
    
    func connectWithKey() {
        setupState = .testing
        
        Task {
            let result = await claudeManager.setupWithKey(apiKey)
            switch result {
            case .success:
                setupState = .success
            case .failure(let message):
                setupState = .failure(message)
            }
        }
    }
    
    func updateKey() {
        setupState = .testing
        
        Task {
            let result = await claudeManager.setupWithKey(apiKey)
            switch result {
            case .success:
                setupState = .success
                // Reset after delay
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                setupState = .idle
            case .failure(let message):
                setupState = .failure(message)
            }
        }
    }
}

// MARK: - Supporting Views

struct SetupStepRow: View {
    let number: Int
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    let actionLabel: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.orange))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let action = action, let label = actionLabel {
                Button(label, action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}

struct ModelOptionRow: View {
    let model: ClaudeModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .orange : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Price indicator based on model tier
                Text(priceIndicator(for: model))
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.orange.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func priceIndicator(for model: ClaudeModel) -> String {
        switch model {
        case .haiku45:
            return "$"
        case .sonnet, .sonnet45:
            return "$$"
        case .opus45:
            return "$$$"
        }
    }
}

// MARK: - Claude Analysis Slide

struct ClaudeAnalysisSlide: View {
    let analytics: MessageAnalytics
    let messages: [Message]
    @StateObject private var claudeManager = ClaudeAPIManager()
    @State private var analysisResult: ClaudeAnalysisResult?
    @State private var streamingText = ""
    @State private var isAnalyzing = false
    @State private var error: String?
    @State private var showingSettings = false
    @State private var appear = false
    @State private var selectedModel: ClaudeModel = .opus45
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if !claudeManager.isConfigured {
                setupPromptView
            } else if isAnalyzing {
                analyzingView
            } else if let result = analysisResult {
                resultView(result)
            } else if let error = error {
                errorView(error)
            } else {
                readyToAnalyzeView
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingSettings) {
            ClaudeSettingsView(claudeManager: claudeManager)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
    
    // MARK: - View States
    
    var setupPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .scaleEffect(appear ? 1 : 0.5)
            
            Text("Claude AI Analysis")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Get the deepest insights with Claude's 200K context window")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                FeatureRow(icon: "brain.head.profile", text: "Analyze your full year of messages")
                FeatureRow(icon: "person.2", text: "Deep relationship insights")
                FeatureRow(icon: "text.quote", text: "Find patterns & themes")
                FeatureRow(icon: "sparkles", text: "Personalized narrative")
            }
            
            Button(action: { showingSettings = true }) {
                HStack {
                    Image(systemName: "key")
                    Text("Add Claude API Key")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(30)
        .offset(y: appear ? 0 : 30)
        .opacity(appear ? 1 : 0)
    }
    
    var readyToAnalyzeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Ready for Deep Analysis")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            // Cost estimate
            let estimate = ClaudeUsageEstimate.estimate(messageCount: messages.count, model: selectedModel)
            
            VStack(spacing: 8) {
                Text("\(messages.count) messages")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Estimated cost: \(estimate.formattedCost)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
            )
            
            // Model picker
            Picker("Model", selection: $selectedModel) {
                ForEach(ClaudeModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)
            
            HStack(spacing: 16) {
                Button(action: runAnalysis) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Analyze with Claude")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .offset(y: appear ? 0 : 30)
        .opacity(appear ? 1 : 0)
    }
    
    var analyzingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.orange)
            
            Text("Claude is analyzing your messages...")
                .font(.headline)
                .foregroundColor(.white)
            
            if !streamingText.isEmpty {
                ScrollView {
                    Text(streamingText)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .padding()
                }
                .frame(maxHeight: 300)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.05))
                )
                .padding(.horizontal, 30)
            }
        }
    }
    
    func resultView(_ result: ClaudeAnalysisResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    Text("Claude's Analysis")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(result.yearInEmojis)
                        .font(.title2)
                }
                
                // Opening Hook
                Text(result.narrative.openingHook)
                    .font(.title3)
                    .foregroundColor(.white)
                    .italic()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.3), .pink.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                // Key Moments
                if !result.narrative.keyMoments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Moments")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        ForEach(result.narrative.keyMoments, id: \.self) { moment in
                            HStack(alignment: .top, spacing: 8) {
                                Text("✦")
                                    .foregroundColor(.orange)
                                Text(moment)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
                
                // Relationship Highlights
                if !result.narrative.relationshipHighlights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Relationship Highlights")
                            .font(.headline)
                            .foregroundColor(.pink)
                        
                        Text(result.narrative.relationshipHighlights)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.05))
                    )
                }
                
                // Fun Facts
                if !result.funFacts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fun Facts")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        
                        ForEach(result.funFacts, id: \.self) { fact in
                            HStack(alignment: .top, spacing: 8) {
                                Text("🎯")
                                Text(fact)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
                
                // Personality
                if let personality = result.personalityInsights {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(personality.type)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text(personality.description)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(personality.style)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                
                // Closing
                Text(result.narrative.closingReflection)
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
            
            Text("Analysis Failed")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Try Again") {
                    error = nil
                    runAnalysis()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button("Settings") {
                    showingSettings = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    
    func runAnalysis() {
        isAnalyzing = true
        error = nil
        streamingText = ""
        
        Task {
            do {
                // Use streaming for real-time feedback
                let result = try await claudeManager.analyzeStreaming(
                    messages: messages,
                    analytics: analytics,
                    model: selectedModel
                ) { partial in
                    Task { @MainActor in
                        streamingText = partial
                    }
                }
                
                // Try to parse as structured result
                if let data = result.data(using: .utf8),
                   let parsed = try? JSONDecoder().decode(ClaudeAnalysisResult.self, from: data) {
                    await MainActor.run {
                        analysisResult = parsed
                        isAnalyzing = false
                    }
                } else {
                    // Use streaming text as narrative
                    await MainActor.run {
                        analysisResult = ClaudeAnalysisResult(
                            narrative: ClaudeNarrative(
                                openingHook: "",
                                keyMoments: [],
                                relationshipHighlights: "",
                                closingReflection: result
                            ),
                            topContactInsights: [],
                            themes: [],
                            emotionalTone: "",
                            funFacts: [],
                            personalityInsights: nil,
                            yearInEmojis: "💬"
                        )
                        isAnalyzing = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ClaudeAnalysisSlide(
            analytics: MessageAnalytics(messages: [], days: 30),
            messages: []
        )
    }
}
