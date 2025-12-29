import SwiftUI

// MARK: - OpenAI Settings View

struct OpenAISettingsView: View {
    @ObservedObject var openAIManager: OpenAIAPIManager
    @State private var apiKey = ""
    @State private var showingKey = false
    @State private var selectedModel: OpenAIModel = .gpt5
    @State private var setupState: SetupState = .idle
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
                    if openAIManager.isConfigured {
                        connectedView
                    } else {
                        setupFlowView
                    }
                    
                    Divider()
                    
                    // Model selection
                    modelSelectionSection
                    
                    Divider()
                    
                    // Cost info
                    costInfoSection
                }
                .padding(24)
            }
        }
        .frame(width: 520, height: 620)
        .onAppear {
            if let existingKey = openAIManager.getAPIKey() {
                apiKey = existingKey
            }
        }
    }
    
    // MARK: - Header
    
    var headerView: some View {
        HStack {
            HStack(spacing: 12) {
                // OpenAI logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Text("◯")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("OpenAI")
                        .font(.title2.bold())
                    Text(openAIManager.isConfigured ? "Connected" : "Not connected")
                        .font(.caption)
                        .foregroundColor(openAIManager.isConfigured ? .green : .secondary)
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
                    Text("Connected to OpenAI API")
                        .font(.headline)
                    
                    if let info = openAIManager.accountInfo {
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
                            openAIManager.deleteAPIKey()
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
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Connect to OpenAI")
                    .font(.title2.bold())
                
                Text("Use GPT-4o's 128K context window for deep message analysis")
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
                
                OpenAISetupStepRow(
                    number: 1,
                    title: "Open OpenAI Platform",
                    subtitle: "Sign up or log in to get API access",
                    action: {
                        openAIManager.openOpenAIPlatform()
                    },
                    actionLabel: "Open Platform"
                )
                
                OpenAISetupStepRow(
                    number: 2,
                    title: "Create an API Key",
                    subtitle: "Go to API Keys → Create new secret key",
                    action: {
                        openAIManager.openAPIKeysPage()
                    },
                    actionLabel: "Go to API Keys"
                )
                
                OpenAISetupStepRow(
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
                            TextField("sk-...", text: $apiKey)
                        } else {
                            SecureField("sk-...", text: $apiKey)
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
                    .tint(.green)
                    .disabled(apiKey.isEmpty || !apiKey.hasPrefix("sk-") || setupState == .testing)
                    
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
        }
    }
    
    // MARK: - Model Selection
    
    var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Model Selection", systemImage: "cpu")
                .font(.headline)
            
            ForEach(OpenAIModel.allCases, id: \.self) { model in
                OpenAIModelOptionRow(
                    model: model,
                    isSelected: selectedModel == model,
                    onSelect: { selectedModel = model }
                )
            }
        }
    }
    
    // MARK: - Cost Info
    
    var costInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Estimated Costs", systemImage: "dollarsign.circle")
                .font(.headline)
            
            VStack(spacing: 8) {
                OpenAICostRow(period: "7 days", messages: 500, model: selectedModel)
                OpenAICostRow(period: "30 days", messages: 2000, model: selectedModel)
                OpenAICostRow(period: "365 days", messages: 20000, model: selectedModel)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Text("GPT-4o Mini is extremely affordable. GPT-4o provides the best quality.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    func connectWithKey() {
        setupState = .testing
        
        Task {
            let result = await openAIManager.setupWithKey(apiKey)
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
            let result = await openAIManager.setupWithKey(apiKey)
            switch result {
            case .success:
                setupState = .success
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                setupState = .idle
            case .failure(let message):
                setupState = .failure(message)
            }
        }
    }
}

// MARK: - Supporting Views

struct OpenAISetupStepRow: View {
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
                .background(Circle().fill(Color.green))
            
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

struct OpenAIModelOptionRow: View {
    let model: OpenAIModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
                
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
                    .foregroundColor(.green)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func priceIndicator(for model: OpenAIModel) -> String {
        switch model {
        case .gpt5Nano:
            return "$"
        case .gpt5Mini, .gpt5, .gpt52, .gpt4o:
            return "$$"
        case .gpt52Pro:
            return "$$$"
        }
    }
}

struct OpenAICostRow: View {
    let period: String
    let messages: Int
    let model: OpenAIModel
    
    var estimate: OpenAIUsageEstimate {
        OpenAIUsageEstimate.estimate(messageCount: messages, model: model)
    }
    
    var body: some View {
        HStack {
            Text(period)
                .foregroundColor(.secondary)
            Text("~\(messages) msgs")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(estimate.formattedCost)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}

// MARK: - OpenAI Analysis Slide

struct OpenAIAnalysisSlide: View {
    let analytics: MessageAnalytics
    let messages: [Message]
    @StateObject private var openAIManager = OpenAIAPIManager()
    @State private var analysisResult: OpenAIAnalysisResult?
    @State private var streamingText = ""
    @State private var isAnalyzing = false
    @State private var error: String?
    @State private var showingSettings = false
    @State private var appear = false
    @State private var selectedModel: OpenAIModel = .gpt5
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            if !openAIManager.isConfigured {
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
            OpenAISettingsView(openAIManager: openAIManager)
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
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .scaleEffect(appear ? 1 : 0.5)
            
            Text("OpenAI Analysis")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Use GPT-4o's 128K context for deep insights")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                OpenAIFeatureRow(icon: "brain", text: "GPT-4o: Most capable model")
                OpenAIFeatureRow(icon: "doc.text", text: "128K context (~2,500 messages)")
                OpenAIFeatureRow(icon: "bolt", text: "GPT-4o Mini: Ultra affordable")
                OpenAIFeatureRow(icon: "lock.shield", text: "Your key stays on device")
            }
            
            Button(action: { showingSettings = true }) {
                HStack {
                    Image(systemName: "key")
                    Text("Add OpenAI API Key")
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)
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
                    LinearGradient(colors: [.green, .teal, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Ready for Analysis")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            // Cost estimate
            let estimate = OpenAIUsageEstimate.estimate(messageCount: messages.count, model: selectedModel)
            
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
                ForEach(OpenAIModel.allCases, id: \.self) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)
            
            HStack(spacing: 16) {
                Button(action: runAnalysis) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Analyze with GPT-4")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)
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
                .tint(.green)
            
            Text("GPT-4 is analyzing your messages...")
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
    
    func resultView(_ result: OpenAIAnalysisResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    Text("GPT-4 Analysis")
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
                                    colors: [.green.opacity(0.3), .teal.opacity(0.2)],
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
                            .foregroundColor(.green)
                        
                        ForEach(result.narrative.keyMoments, id: \.self) { moment in
                            HStack(alignment: .top, spacing: 8) {
                                Text("✦")
                                    .foregroundColor(.green)
                                Text(moment)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
                
                // Fun Facts
                if !result.funFacts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fun Facts")
                            .font(.headline)
                            .foregroundColor(.teal)
                        
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
                                    colors: [.green.opacity(0.3), .cyan.opacity(0.2)],
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
                .foregroundColor(.green)
            
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
                .tint(.green)
                
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
                let result = try await openAIManager.analyzeStreaming(
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
                   let parsed = try? JSONDecoder().decode(OpenAIAnalysisResult.self, from: data) {
                    await MainActor.run {
                        analysisResult = parsed
                        isAnalyzing = false
                    }
                } else {
                    await MainActor.run {
                        analysisResult = OpenAIAnalysisResult(
                            narrative: OpenAINarrative(
                                openingHook: "",
                                keyMoments: [],
                                relationshipHighlights: "",
                                closingReflection: result
                            ),
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

struct OpenAIFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
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
        OpenAIAnalysisSlide(
            analytics: MessageAnalytics(messages: [], days: 30),
            messages: []
        )
    }
}
