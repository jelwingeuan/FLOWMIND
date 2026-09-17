import Foundation

protocol PatternDetectionService {
    var threshold: Int { get }
    func suggestions(from activity: [ActivityRecord], inbox: [InboxItem]) -> [PatternSuggestion]
}

struct SimplePatternDetectionService: PatternDetectionService {
    let threshold: Int

    func suggestions(from activity: [ActivityRecord], inbox: [InboxItem]) -> [PatternSuggestion] {
        let receiptCount = inbox.filter { $0.detectedCategory == .receipt }.count
        guard receiptCount >= threshold else { return [] }

        return [PatternSuggestion(
            id: UUID(uuidString: "D8B7E33B-C3C0-4BFA-9A65-2A9C20C5AE01")!,
            title: "Receipt handling is becoming a pattern",
            detail: "You processed \(receiptCount) similar receipt images. FLOWMIND can make the repeated steps reusable.",
            actions: ["Extract merchant, date, and total", "Categorize as Food", "Save expense"],
            category: .receipt
        )]
    }
}

protocol FlowGenerationService {
    func generate(from prompt: String) async throws -> FlowDefinition
}

struct FlowDefinition: Codable, Hashable {
    let name: String
    let trigger: String
    let condition: String
    let actions: [String]
}

struct MockFlowGenerationService: FlowGenerationService {
    func generate(from prompt: String) async throws -> FlowDefinition {
        let lowercased = prompt.lowercased()
        if lowercased.contains("receipt") {
            return FlowDefinition(name: "Receipt Capture", trigger: "Something is shared", condition: "It is a receipt", actions: ["Extract merchant, date, and total", "Categorize as Food", "Save expense"])
        }
        if lowercased.contains("assignment") || lowercased.contains("deadline") {
            return FlowDefinition(name: "Assignment Capture", trigger: "A PDF is shared", condition: "It is an assignment", actions: ["Generate summary", "Add deadline", "Save document"])
        }
        return FlowDefinition(name: "New FLOWMIND Flow", trigger: "Something is shared", condition: "The item matches your instruction", actions: ["Generate summary", "Add tag"])
    }
}

protocol AIAnalysisService {
    func analyze(item: InboxItem) async throws -> ItemAnalysis
}

struct ItemAnalysis: Codable, Hashable {
    let category: DetectedCategory
    let summary: String
    let confidence: Double
    let extractedFields: [String: String]
    let tags: [String]
    let suggestedActions: [String]
}

struct MockAIAnalysisService: AIAnalysisService {
    func analyze(item: InboxItem) async throws -> ItemAnalysis {
        ItemAnalysis(category: item.detectedCategory, summary: item.summary, confidence: 0.92, extractedFields: item.extractedFields, tags: [item.detectedCategory.label], suggestedActions: item.suggestedActions)
    }
}
