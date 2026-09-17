import XCTest
import SwiftData
import SwiftUI
@testable import FlowMind

final class FlowMindTests: XCTestCase {
    @MainActor
    private func makeContainer(url: URL? = nil) throws -> ModelContainer {
        let schema = Schema([InboxItemRecord.self, FlowRecord.self, FlowRunRecord.self])
        let configuration = url.map { ModelConfiguration(schema: schema, url: $0) }
            ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    func testFreshStoreAndRepeatedLaunchesStayEmpty() throws {
        let container = try makeContainer()
        for _ in 0..<3 {
            let store = FlowMindStore(modelContext: container.mainContext)
            XCTAssertTrue(store.inboxItems.isEmpty)
            XCTAssertTrue(store.flows.isEmpty)
            XCTAssertTrue(store.activity.isEmpty)
            XCTAssertTrue(store.patternSuggestions.isEmpty)
            XCTAssertNil(store.errorMessage)
        }
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<InboxItemRecord>()), 0)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<FlowRecord>()), 0)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<FlowRunRecord>()), 0)
    }

    @MainActor
    func testPersistedUserContentWithDemoNamesSurvivesRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        var savedID: UUID?
        do {
            let container = try makeContainer(url: url)
            let store = FlowMindStore(modelContext: container.mainContext)
            XCTAssertTrue(store.addTextItem(title: "Restaurant Receipt", text: "My own receipt notes"))
            savedID = store.inboxItems.first?.id
            XCTAssertTrue(store.createFlow(from: FlowDefinition(name: "Receipt Capture", trigger: "Something is shared", condition: "It is a receipt", actions: ["Save expense"])))
            store.run(flow: try XCTUnwrap(store.flows.first), with: try XCTUnwrap(store.inboxItems.first))
        }
        let reopenedContainer = try makeContainer(url: url)
        let reopened = FlowMindStore(modelContext: reopenedContainer.mainContext)
        XCTAssertEqual(reopened.inboxItems.count, 1)
        XCTAssertEqual(reopened.inboxItems.first?.id, savedID)
        XCTAssertEqual(reopened.inboxItems.first?.plainTextContent, "My own receipt notes")
        XCTAssertEqual(reopened.flows.count, 1)
        XCTAssertEqual(reopened.flows.first?.name, "Receipt Capture")
        XCTAssertEqual(reopened.flows.first?.runCount, 1)
        XCTAssertEqual(reopened.activity.count, 1)
    }

    @MainActor
    func testDeleteAllDataDoesNotReseedOnRelaunch() throws {
        let container = try makeContainer()
        let store = FlowMindStore(modelContext: container.mainContext)
        store.addTextItem(title: "My note", text: "A task to organize")
        store.createFlow(from: try XCTUnwrap(store.inboxItems.first))
        store.run(flow: try XCTUnwrap(store.flows.first), with: try XCTUnwrap(store.inboxItems.first))
        store.deleteAllData()
        let relaunched = FlowMindStore(modelContext: container.mainContext)
        XCTAssertTrue(relaunched.inboxItems.isEmpty)
        XCTAssertTrue(relaunched.flows.isEmpty)
        XCTAssertTrue(relaunched.activity.isEmpty)
        XCTAssertTrue(relaunched.patternSuggestions.isEmpty)
    }

    @MainActor
    func testCaptureSavesOnlyUserEnteredContent() throws {
        let container = try makeContainer()
        let store = FlowMindStore(modelContext: container.mainContext)
        XCTAssertFalse(store.addTextItem(title: "Title without content", text: " \n "))
        XCTAssertTrue(store.inboxItems.isEmpty)
        XCTAssertTrue(store.addTextItem(title: " ", text: "  Plan next week\n"))
        let note = try XCTUnwrap(store.inboxItems.first)
        XCTAssertEqual(note.title, "Plan next week")
        XCTAssertEqual(note.plainTextContent, "Plan next week")
        XCTAssertEqual(note.summary, "Plan next week")
        XCTAssertTrue(store.activity.isEmpty)
        XCTAssertTrue(store.patternSuggestions.isEmpty)
    }

    @MainActor
    func testFlowCreationWorksWithoutInboxOrFabricatedHistory() throws {
        let container = try makeContainer()
        let store = FlowMindStore(modelContext: container.mainContext)
        let definition = FlowDefinition(name: "My Flow", trigger: "A note is shared", condition: "It has a deadline", actions: ["Add reminder"])
        XCTAssertTrue(store.createFlow(from: definition))
        let flow = try XCTUnwrap(store.flows.first)
        XCTAssertEqual(flow.name, definition.name)
        XCTAssertEqual(flow.trigger, definition.trigger)
        XCTAssertEqual(flow.condition, definition.condition)
        XCTAssertEqual(flow.actionSummary, "Add reminder")
        XCTAssertEqual(flow.runCount, 0)
        XCTAssertEqual(flow.successfulRunCount, 0)
        XCTAssertNil(flow.lastRunAt)
        XCTAssertTrue(store.inboxItems.isEmpty)
        XCTAssertTrue(store.activity.isEmpty)
    }

    @MainActor
    func testEmptyScreenRenderings() async throws {
        let container = try makeContainer()
        let store = FlowMindStore(modelContext: container.mainContext)
        for style in [UIUserInterfaceStyle.light, .dark] {
            try await attachRendering(HomeView(), name: "Home", store: store, style: style, height: 1800)
            try await attachRendering(InboxView(), name: "Inbox", store: store, style: style)
            try await attachRendering(FlowsView(), name: "Flows", store: store, style: style)
            try await attachRendering(MindView(), name: "Mind", store: store, style: style)
        }
    }

    @MainActor
    private func attachRendering<Content: View>(_ content: Content, name: String, store: FlowMindStore, style: UIUserInterfaceStyle, height: CGFloat = 812) async throws {
        let controller = UIHostingController(rootView: NavigationStack { content.environment(store) }.tint(.flowMindAccent))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 375, height: height)
        window.overrideUserInterfaceStyle = style
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        controller.view.frame = window.bounds
        window.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(150))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "Empty-\(name)-\(style == .dark ? "dark" : "light")"
        attachment.lifetime = .keepAlways
        add(attachment)
        let pixels = try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
        XCTAssertGreaterThan(Set(pixels).count, 16, "The screen capture must contain rendered UI, not a blank frame.")
    }

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
