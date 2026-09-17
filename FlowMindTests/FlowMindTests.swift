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
            XCTAssertNotNil(store.createFlow(from: FlowDefinition(name: "Receipt Capture", trigger: "Something is shared", condition: "It is a receipt", actions: ["Save expense"])))
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
    func testLinkAndFileCapturePersistOnlyAfterExplicitSave() throws {
        let container = try makeContainer()
        let store = FlowMindStore(modelContext: container.mainContext)
        XCTAssertTrue(store.addLinkItem(urlString: "https://example.com/read", title: "Reading"))
        XCTAssertTrue(store.addAttachmentItem(data: Data([0x01, 0x02]), filename: "notes.pdf", contentType: .pdf))

        XCTAssertEqual(store.inboxItems.count, 2)
        let link = try XCTUnwrap(store.inboxItems.first(where: { $0.contentType == .url }))
        let file = try XCTUnwrap(store.inboxItems.first(where: { $0.contentType == .pdf }))
        XCTAssertEqual(link.sourceURL, "https://example.com/read")
        XCTAssertNil(link.attachmentData)
        XCTAssertEqual(file.sourceFilename, "notes.pdf")
        XCTAssertEqual(file.attachmentData, Data([0x01, 0x02]))
    }

    @MainActor
    func testOnboardingReplayPreservesEducationProgress() {
        let suiteName = "FlowMindTests.Education.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let education = UserEducationState(defaults: defaults)
        XCTAssertFalse(education.hasCompletedOnboarding)
        education.markFirstItemAdded()
        education.markFirstFlowCreated()
        education.completeOnboarding()

        let reloaded = UserEducationState(defaults: defaults)
        XCTAssertTrue(reloaded.hasCompletedOnboarding)
        XCTAssertTrue(reloaded.hasAddedFirstItem)
        XCTAssertTrue(reloaded.hasCreatedFirstFlow)
        reloaded.replayOnboarding()
        XCTAssertFalse(reloaded.hasCompletedOnboarding)
        XCTAssertTrue(reloaded.hasAddedFirstItem)
        XCTAssertTrue(reloaded.hasCreatedFirstFlow)
    }

    @MainActor
    func testFlowCreationWorksWithoutInboxOrFabricatedHistory() throws {
        let container = try makeContainer()
        let store = FlowMindStore(modelContext: container.mainContext)
        let definition = FlowDefinition(name: "My Flow", trigger: "A note is shared", condition: "It has a deadline", actions: ["Add reminder"])
        let createdFlow = try XCTUnwrap(store.createFlow(from: definition))
        let flow = try XCTUnwrap(store.flows.first)
        XCTAssertEqual(createdFlow.id, flow.id)
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
        let education = UserEducationState(defaults: UserDefaults(suiteName: "FlowMindTests.Render.\(UUID().uuidString)")!)
        for style in [UIUserInterfaceStyle.light, .dark] {
            try await attachRendering(HomeView(), name: "Home", store: store, education: education, style: style, height: 1800)
            try await attachRendering(InboxView(), name: "Inbox", store: store, education: education, style: style)
            try await attachRendering(FlowsView(), name: "Flows", store: store, education: education, style: style)
            try await attachRendering(MindView(), name: "Mind", store: store, education: education, style: style)
            try await attachRendering(OnboardingView(onFinish: {}), name: "Onboarding", store: store, education: education, style: style)
        }
    }

    @MainActor
    private func attachRendering<Content: View>(_ content: Content, name: String, store: FlowMindStore, education: UserEducationState, style: UIUserInterfaceStyle, height: CGFloat = 812) async throws {
        let controller = UIHostingController(rootView: NavigationStack { content }
            .environment(store)
            .environment(education)
            .tint(.flowMindAccent))
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
