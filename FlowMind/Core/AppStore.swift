import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class FlowMindStore {
    var inboxItems: [InboxItem] = []
    var flows: [FlowSummary] = []
    var activity: [ActivityRecord] = []
    var patternSuggestions: [PatternSuggestion] = []
    var errorMessage: String?

    @ObservationIgnored private let modelContext: ModelContext
    private let patternService: any PatternDetectionService = SimplePatternDetectionService(threshold: 3)
    private let demoSeedKey = "hasSeededFlowMindDemoData"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reload()
        if inboxItems.isEmpty && flows.isEmpty && !UserDefaults.standard.bool(forKey: demoSeedKey) {
            seedDemoData()
        }
        refreshPatterns()
    }

    func reload() {
        do {
            inboxItems = try modelContext.fetch(FetchDescriptor<InboxItemRecord>()).map(\.domainValue).sorted { $0.createdAt > $1.createdAt }
            flows = try modelContext.fetch(FetchDescriptor<FlowRecord>()).map(\.domainValue).sorted { $0.name < $1.name }
            let flowNames = Dictionary(uniqueKeysWithValues: flows.map { ($0.id, $0.name) })
            activity = try modelContext.fetch(FetchDescriptor<FlowRunRecord>()).map { run in
                ActivityRecord(id: run.id, flowName: flowNames[run.flowID] ?? "FLOWMIND Flow", action: run.executedActions, timestamp: run.completedAt ?? run.startedAt, status: run.status.capitalized)
            }.sorted { $0.timestamp > $1.timestamp }
        } catch {
            errorMessage = "FLOWMIND could not load local data."
        }
    }

    func addTextItem() {
        let item = InboxItem(id: UUID(), createdAt: Date(), updatedAt: Date(), contentType: .text, title: "Quick note", sourceFilename: nil, sourceURL: nil, plainTextContent: "A note captured directly in FLOWMIND.", processingStatus: .ready, detectedCategory: .note, summary: "A quick note ready to organize or turn into a Flow.", extractedFields: ["Source": "Manual entry"], suggestedActions: ["Generate summary", "Add tag", "Archive item"], isArchived: false)
        modelContext.insert(InboxItemRecord(item: item))
        persistAndReload()
    }

    func createFlow(from item: InboxItem) {
        let flow = FlowSummary(id: UUID(), name: item.detectedCategory == .receipt ? "Receipt Capture" : "\(item.detectedCategory.label) Capture", icon: "bolt.fill", trigger: "Something is shared", condition: "It is a \(item.detectedCategory.label.lowercased())", actionSummary: item.suggestedActions.prefix(2).joined(separator: " -> "), isEnabled: true, runCount: 0, successfulRunCount: 0, lastRunAt: nil, creationSource: "suggested")
        modelContext.insert(FlowRecord(flow: flow))
        persistAndReload()
    }

    func run(flow: FlowSummary, with item: InboxItem) {
        let flowID = flow.id
        let descriptor = FetchDescriptor<FlowRecord>(predicate: #Predicate { $0.id == flowID })
        guard let record = try? modelContext.fetch(descriptor).first else { return }
        record.runCount += 1
        record.successfulRunCount += 1
        record.lastRunAt = Date()
        record.updatedAt = Date()
        modelContext.insert(FlowRunRecord(flowID: flow.id, inputItemID: item.id, actions: item.suggestedActions))
        persistAndReload()
    }

    func archive(item: InboxItem) {
        let itemID = item.id
        let descriptor = FetchDescriptor<InboxItemRecord>(predicate: #Predicate { $0.id == itemID })
        guard let record = try? modelContext.fetch(descriptor).first else { return }
        record.isArchived = true
        record.updatedAt = Date()
        persistAndReload()
    }

    func deleteAllData() {
        do {
            for record in try modelContext.fetch(FetchDescriptor<InboxItemRecord>()) {
                modelContext.delete(record)
            }
            for record in try modelContext.fetch(FetchDescriptor<FlowRecord>()) {
                modelContext.delete(record)
            }
            for record in try modelContext.fetch(FetchDescriptor<FlowRunRecord>()) {
                modelContext.delete(record)
            }
            try modelContext.save()
            inboxItems = []
            flows = []
            activity = []
            patternSuggestions = []
        } catch {
            errorMessage = "Local data could not be deleted."
        }
    }

    private func persistAndReload() {
        do {
            try modelContext.save()
            reload()
            refreshPatterns()
        } catch {
            errorMessage = "Your change could not be saved locally."
        }
    }

    private func refreshPatterns() {
        patternSuggestions = patternService.suggestions(from: activity, inbox: inboxItems)
    }

    private func seedDemoData() {
        let now = Date()
        let demoItems = [
            InboxItem(id: UUID(), createdAt: now.addingTimeInterval(-86400), updatedAt: now.addingTimeInterval(-86400), contentType: .pdf, title: "Assignment2.pdf", sourceFilename: "Assignment2.pdf", sourceURL: nil, plainTextContent: nil, processingStatus: .ready, detectedCategory: .assignment, summary: "Group assignment brief for LDCW6113 with a 23 October deadline.", extractedFields: ["Module": "LDCW6113", "Type": "Group Assignment", "Weight": "30%", "Deadline": "23 October", "Team Size": "6"], suggestedActions: ["Create project", "Add deadline", "Create reminder", "Save document"], isArchived: false),
            InboxItem(id: UUID(), createdAt: now.addingTimeInterval(-7200), updatedAt: now.addingTimeInterval(-7200), contentType: .image, title: "Restaurant Receipt", sourceFilename: "receipt-august.png", sourceURL: nil, plainTextContent: nil, processingStatus: .ready, detectedCategory: .receipt, summary: "Receipt image with merchant, date, and total ready to extract.", extractedFields: ["Merchant": "Northstar Kitchen", "Date": "14 August", "Total": "$42.80"], suggestedActions: ["Extract total", "Categorize as Food", "Save expense"], isArchived: false),
            InboxItem(id: UUID(), createdAt: now.addingTimeInterval(-172800), updatedAt: now.addingTimeInterval(-172800), contentType: .url, title: "Design Reference", sourceFilename: nil, sourceURL: "https://example.com/reference", plainTextContent: nil, processingStatus: .ready, detectedCategory: .visualReference, summary: "A visual reference saved for a future interface direction.", extractedFields: ["Collection": "Inspiration"], suggestedActions: ["Add tag", "Save to category"], isArchived: false),
            InboxItem(id: UUID(), createdAt: now.addingTimeInterval(-259200), updatedAt: now.addingTimeInterval(-259200), contentType: .image, title: "AirPods Product Screenshot", sourceFilename: "airpods.png", sourceURL: nil, plainTextContent: nil, processingStatus: .ready, detectedCategory: .product, summary: "Product screenshot saved for a purchase comparison.", extractedFields: ["Category": "Audio", "Source": "Screenshot"], suggestedActions: ["Add tag", "Generate summary"], isArchived: false),
            InboxItem(id: UUID(), createdAt: now.addingTimeInterval(-345600), updatedAt: now.addingTimeInterval(-345600), contentType: .url, title: "Article Link", sourceFilename: nil, sourceURL: "https://example.com/article", plainTextContent: nil, processingStatus: .ready, detectedCategory: .article, summary: "A saved article ready for a short summary.", extractedFields: ["Reading list": "Later"], suggestedActions: ["Generate summary", "Save to category"], isArchived: false)
        ]

        demoItems.forEach { modelContext.insert(InboxItemRecord(item: $0)) }
        let demoFlows = [
            FlowSummary(id: UUID(), name: "University Assignment", icon: "book", trigger: "A PDF is shared", condition: "It is an assignment", actionSummary: "Summarize -> Add deadline", isEnabled: true, runCount: 6, successfulRunCount: 6, lastRunAt: now.addingTimeInterval(-86400), creationSource: "manual"),
            FlowSummary(id: UUID(), name: "Receipt Capture", icon: "receipt", trigger: "An image is shared", condition: "It is a receipt", actionSummary: "Extract total -> Save expense", isEnabled: true, runCount: 23, successfulRunCount: 22, lastRunAt: now.addingTimeInterval(-120), creationSource: "suggested"),
            FlowSummary(id: UUID(), name: "Inspiration Saver", icon: "photo", trigger: "A URL is shared", condition: "It is a visual reference", actionSummary: "Add tag -> Save reference", isEnabled: true, runCount: 31, successfulRunCount: 31, lastRunAt: now.addingTimeInterval(-3600), creationSource: "manual"),
            FlowSummary(id: UUID(), name: "Purchase Compare", icon: "tag", trigger: "Text is shared", condition: "It is a product", actionSummary: "Generate summary -> Add tag", isEnabled: false, runCount: 3, successfulRunCount: 3, lastRunAt: now.addingTimeInterval(-172800), creationSource: "manual")
        ]
        demoFlows.forEach { modelContext.insert(FlowRecord(flow: $0)) }
        demoFlows.prefix(3).forEach { flow in
            guard let item = demoItems.first else { return }
            modelContext.insert(FlowRunRecord(flowID: flow.id, inputItemID: item.id, actions: [flow.actionSummary]))
        }
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: demoSeedKey)
        reload()
    }
}
