import Foundation

// MARK: - Narrative Insights Model

/// LLM-generated narrative content from actual message analysis
struct NarrativeInsights: Codable, Identifiable {
    let id: UUID
    let generatedAt: Date
    let modelUsed: String
    let tokensUsed: Int
    let generationTimeSeconds: Double
    
    // Narrative content
    let yearInReview: String           // 2-3 paragraph story
    let topContactNarrative: String    // Personalized insight about #1 contact
    let communicationStyle: String     // Personality description
    let funFacts: [String]             // Quirky observations (3-5)
    let emotionalJourney: String       // How mood evolved over time
    
    init(
        id: UUID = UUID(),
        generatedAt: Date = Date(),
        modelUsed: String,
        tokensUsed: Int,
        generationTimeSeconds: Double,
        yearInReview: String,
        topContactNarrative: String,
        communicationStyle: String,
        funFacts: [String],
        emotionalJourney: String
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.modelUsed = modelUsed
        self.tokensUsed = tokensUsed
        self.generationTimeSeconds = generationTimeSeconds
        self.yearInReview = yearInReview
        self.topContactNarrative = topContactNarrative
        self.communicationStyle = communicationStyle
        self.funFacts = funFacts
        self.emotionalJourney = emotionalJourney
    }
}

// MARK: - System Requirements

struct SystemRequirementsResult {
    let isAppleSilicon: Bool
    let macOSVersion: String
    let isMinimumMacOS: Bool       // macOS 14.0+
    let totalRAMGB: Int
    let availableStorageGB: Int
    let chipName: String
    
    var canRunMLX: Bool {
        isAppleSilicon && isMinimumMacOS
    }
    
    var ramWarning: String? {
        if totalRAMGB < 8 {
            return "Your Mac has \(totalRAMGB)GB RAM. AI features require 8GB minimum."
        } else if totalRAMGB == 8 {
            return "With 8GB RAM, you may experience slower AI generation on large message databases."
        }
        return nil
    }
    
    var storageWarning: String? {
        if availableStorageGB < 3 {
            return "Need at least 3GB free storage to download the AI model."
        }
        return nil
    }
    
    var overallStatus: RequirementStatus {
        if !isAppleSilicon {
            return .unsupported("Intel Macs are not supported for on-device AI. You can still use the basic analysis features.")
        }
        if !isMinimumMacOS {
            return .unsupported("macOS 14 (Sonoma) or later is required for on-device AI.")
        }
        if availableStorageGB < 3 {
            return .warning("Low storage. Please free up space before downloading the AI model.")
        }
        if totalRAMGB < 8 {
            return .warning("Low RAM. AI features may not work reliably.")
        }
        return .ready
    }
    
    enum RequirementStatus {
        case ready
        case warning(String)
        case unsupported(String)
        
        var isReady: Bool {
            if case .ready = self { return true }
            return false
        }
        
        var message: String? {
            switch self {
            case .ready: return nil
            case .warning(let msg), .unsupported(let msg): return msg
            }
        }
    }
}

// MARK: - Model Download State

enum ModelDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case loading
    case ready
    case error(String)
    
    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
    
    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
    
    var isDownloadedOrReady: Bool {
        switch self {
        case .downloaded, .ready, .loading:
            return true
        default:
            return false
        }
    }
    
    var statusText: String {
        switch self {
        case .notDownloaded:
            return "AI model not downloaded"
        case .downloading(let progress):
            return "Downloading... \(Int(progress * 100))%"
        case .downloaded:
            return "Model downloaded, ready to load"
        case .loading:
            return "Loading AI model..."
        case .ready:
            return "AI ready"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

// MARK: - MLX Model Configuration

struct MLXModelConfig {
    let modelId: String
    let displayName: String
    let huggingFaceRepo: String
    let estimatedSizeGB: Double
    let contextLength: Int
    let quantization: String
    
    static let phi35Mini4Bit = MLXModelConfig(
        modelId: "phi-3.5-mini-4bit",
        displayName: "Phi 3.5 Mini (4-bit)",
        huggingFaceRepo: "mlx-community/Phi-3.5-mini-instruct-4bit",
        estimatedSizeGB: 2.0,
        contextLength: 128_000,
        quantization: "4-bit"
    )
    
    // Alternative smaller model for constrained devices
    static let qwen25_3B4Bit = MLXModelConfig(
        modelId: "qwen2.5-3b-4bit",
        displayName: "Qwen 2.5 3B (4-bit)",
        huggingFaceRepo: "mlx-community/Qwen2.5-3B-Instruct-4bit",
        estimatedSizeGB: 1.5,
        contextLength: 32_768,
        quantization: "4-bit"
    )
    
    static let defaultModel = phi35Mini4Bit
}
