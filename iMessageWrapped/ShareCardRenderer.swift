import SwiftUI
import AppKit

// MARK: - Share Card Renderer

/// Renders share cards to images and handles sharing
@MainActor
class ShareCardRenderer: ObservableObject {
    static let shared = ShareCardRenderer()
    
    @Published var isRendering = false
    @Published var lastRenderedImage: NSImage?
    
    // MARK: - Render to Image
    
    /// Renders a share card view to an NSImage
    @MainActor
    func renderCardToImage<V: View>(_ view: V, size: CGSize = CGSize(width: 350, height: 500)) -> NSImage? {
        isRendering = true
        defer { isRendering = false }
        
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2.0  // Retina quality
        
        guard let cgImage = renderer.cgImage else { return nil }
        
        let image = NSImage(cgImage: cgImage, size: size)
        lastRenderedImage = image
        return image
    }
    
    /// Renders a specific card type
    func renderCard(type: ShareCardData.CardType, insights: WrappedInsights) -> NSImage? {
        let cardData = ShareCardData(
            type: type,
            userName: nil,
            timePeriod: "\(insights.timePeriodDays) days",
            stats: [:],
            accentColor: "#00FF88"
        )
        
        let cardView = ShareCardView(cardData: cardData, insights: insights)
        return renderCardToImage(cardView)
    }
    
    // MARK: - Share Sheet
    
    /// Shows the native macOS share sheet for an image
    func shareImage(_ image: NSImage, from view: NSView? = nil) {
        let sharingPicker = NSSharingServicePicker(items: [image])
        
        if let view = view ?? NSApp.keyWindow?.contentView {
            sharingPicker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        }
    }
    
    /// Renders and shares a card in one step
    func renderAndShare(type: ShareCardData.CardType, insights: WrappedInsights, from view: NSView? = nil) {
        guard let image = renderCard(type: type, insights: insights) else {
            print("Failed to render card")
            return
        }
        shareImage(image, from: view)
    }
    
    /// Shares directly to iMessage, bringing the app to foreground
    func shareToMessages(_ image: NSImage) {
        let service = NSSharingService(named: NSSharingService.Name.composeMessage)
        service?.perform(withItems: [image])
    }

    // MARK: - Save to File
    
    /// Saves an image to the Downloads folder
    func saveToDownloads(_ image: NSImage, filename: String = "iMessageWrapped") -> URL? {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let url = downloads.appendingPathComponent("\(filename)_\(timestamp).png")
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        do {
            try pngData.write(to: url)
            return url
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    // MARK: - Copy to Clipboard
    
    /// Copies an image to the system clipboard
    func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}

// MARK: - Share Button View

/// A reusable share button component
struct ShareButton: View {
    let cardType: ShareCardData.CardType
    let insights: WrappedInsights
    @StateObject private var renderer = ShareCardRenderer.shared
    @State private var showingOptions = false
    @State private var savedURL: URL?
    @State private var showingSavedAlert = false
    
    var body: some View {
        Menu {
            Button(action: shareToMessages) {
                Label("Share to iMessage", systemImage: "message.fill")
            }
            
            Button(action: shareToSocial) {
                Label("Share via...", systemImage: "square.and.arrow.up")
            }
            
            Button(action: copyToClipboard) {
                Label("Copy Image", systemImage: "doc.on.doc")
            }
            
            Button(action: saveToDownloads) {
                Label("Save to Downloads", systemImage: "arrow.down.circle")
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .alert("Saved!", isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) {}
            if let url = savedURL {
                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                }
            }
        } message: {
            Text("Your card has been saved to Downloads")
        }
    }
    
    private func shareToMessages() {
        if let image = renderer.renderCard(type: cardType, insights: insights) {
            renderer.shareToMessages(image)
        }
    }
    
    private func shareToSocial() {
        renderer.renderAndShare(type: cardType, insights: insights)
    }
    
    private func copyToClipboard() {
        if let image = renderer.renderCard(type: cardType, insights: insights) {
            renderer.copyToClipboard(image)
        }
    }
    
    private func saveToDownloads() {
        if let image = renderer.renderCard(type: cardType, insights: insights),
           let url = renderer.saveToDownloads(image, filename: "iMessageWrapped_\(cardType.rawValue)") {
            savedURL = url
            showingSavedAlert = true
        }
    }
}

// MARK: - Card Type Picker

struct CardTypePicker: View {
    @Binding var selectedType: ShareCardData.CardType
    
    private let types: [(ShareCardData.CardType, String, String)] = [
        (.summary, "Summary", "square.text.square"),
        (.personality, "Personality", "person.fill.questionmark"),
        (.topFriends, "Top Friends", "person.3.fill"),
        (.emoji, "Emoji", "face.smiling"),
        (.vibe, "Vibe", "heart.fill")
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(types, id: \.0.rawValue) { type, name, icon in
                Button(action: { selectedType = type }) {
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.title2)
                        Text(name)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedType == type ? .white : .white.opacity(0.5))
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedType == type ? Color.purple.opacity(0.5) : Color.white.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Share Sheet View

/// Full share experience with card preview and type selection
struct ShareSheetView: View {
    let insights: WrappedInsights
    @State private var selectedCardType: ShareCardData.CardType = .summary
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Share Your Wrapped")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            
            // Card type picker
            CardTypePicker(selectedType: $selectedCardType)
            
            // Preview
            Group {
                switch selectedCardType {
                case .summary:
                    SummaryCard(insights: insights)
                case .personality:
                    PersonalityCard(dna: insights.communicationDNA)
                case .topFriends:
                    TopFriendsCard(dynamics: Array(insights.relationshipDynamics.prefix(3)))
                case .emoji:
                    EmojiCard(emojiData: insights.emojiDeepDive)
                case .vibe:
                    VibeCard(insights: insights)
                }
            }
            .scaleEffect(0.85)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Share button
            ShareButton(cardType: selectedCardType, insights: insights)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
        )
        .frame(width: 450, height: 700)
    }
}

// MARK: - Preview

#Preview {
    let sampleInsights = WrappedInsights(
        generatedAt: Date(),
        timePeriodDays: 30,
        totalMessagesAnalyzed: 1500,
        communicationDNA: CommunicationDNA(
            averageMessageLength: 45,
            questionToStatementRatio: 0.3,
            emojiDensity: 3.5,
            avgResponseTimeMinutes: 15,
            punctuationStyle: .exclamationEnthusiast,
            expressiveness: 0.7,
            formality: 0.4,
            vocabularyComplexity: "Standard"
        ),
        relationshipDynamics: [],

        worldMap: WorldMapInsights(places: [], people: [], organizations: []),
        evolution: CommunicationEvolution(
            monthlyStats: [],
            wordCountTrend: .stable,
            emojiUsageTrend: .increasing,
            responseTimeTrend: .stable,
            newWordsAdopted: []
        ),
        connectionPatterns: ConnectionPatterns(
            ghostingEvents: [],
            reconnections: [],
            fadeOuts: [],
            longestStreak: nil,
            intenseConversations: []
        ),
        emojiDeepDive: EmojiDeepDive(
            topEmojis: [
                EmojiInsight(id: UUID(), emoji: "😂", count: 150, percentOfTotal: 25, mostUsedWith: "Best Friend", averageSentimentContext: 0.8)
            ],
            emojiCombos: [],
            emojiSentimentMap: [:],
            totalEmojiCount: 600,
            uniqueEmojiCount: 45,
            emojiPercentOfMessages: 35
        ),
        temporalFingerprint: TemporalFingerprint(
            hourlyDistribution: [:],
            weekdayDistribution: [:],
            inferredSleepStart: 23,
            inferredSleepEnd: 7,
            workHoursPercent: 0.4,
            weekendVsWeekdayRatio: 1.2,
            nightOwlScore: 0.6,
            earlyBirdScore: 0.2
        ),
        aiRevelations: []
    )
    
    ShareSheetView(insights: sampleInsights)
        .frame(width: 500, height: 750)
        .background(Color.black)
}
