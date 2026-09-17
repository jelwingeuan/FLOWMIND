import XCTest
@testable import FlowMind

final class FlowMindTests: XCTestCase {
    func testPatternSuggestionRequiresThreshold() {
        let service = SimplePatternDetectionService(threshold: 3)
        let inbox = (0..<2).map { index in
            InboxItem(id: UUID(), createdAt: Date(), updatedAt: Date(), contentType: .image, title: "Receipt \(index)", sourceFilename: nil, sourceURL: nil, plainTextContent: nil, processingStatus: .ready, detectedCategory: .receipt, summary: "Receipt", extractedFields: [:], suggestedActions: ["Extract total"], isArchived: false)
        }
        XCTAssertTrue(service.suggestions(from: [], inbox: inbox).isEmpty)
    }

    func testReceiptPatternSuggestionAppearsAtThreshold() {
        let service = SimplePatternDetectionService(threshold: 3)
        let inbox = (0..<3).map { index in
            InboxItem(id: UUID(), createdAt: Date(), updatedAt: Date(), contentType: .image, title: "Receipt \(index)", sourceFilename: nil, sourceURL: nil, plainTextContent: nil, processingStatus: .ready, detectedCategory: .receipt, summary: "Receipt", extractedFields: [:], suggestedActions: ["Extract total"], isArchived: false)
        }
        XCTAssertEqual(service.suggestions(from: [], inbox: inbox).count, 1)
    }

    func testMockFlowGenerationRecognizesReceipts() async throws {
        let definition = try await MockFlowGenerationService().generate(from: "Whenever I share a restaurant receipt, extract the total")
        XCTAssertEqual(definition.name, "Receipt Capture")
        XCTAssertTrue(definition.actions.contains("Save expense"))
    }
}
