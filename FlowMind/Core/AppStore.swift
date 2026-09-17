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

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reload()
    }

    func reload() {
        do {
            inboxItems = try modelContext.fetch(FetchDescriptor<InboxItemRecord>()).map(\.domainValue).sorted { $0.createdAt > $1.createdAt }
            flows = try modelContext.fetch(FetchDescriptor<FlowRecord>()).map(\.domainValue).sorted { $0.name < $1.name }
            let flowNames = Dictionary(uniqueKeysWithValues: flows.map { ($0.id, $0.name) })
            activity = try modelContext.fetch(FetchDescriptor<FlowRunRecord>()).map { run in
                ActivityRecord(id: run.id, flowName: flowNames[run.flowID] ?? "FLOWMIND Flow", action: run.executedActions, timestamp: run.completedAt ?? run.startedAt, status: run.status.capitalized)
            }.sorted { $0.timestamp > $1.timestamp }
            refreshPatterns()
        } catch {
            errorMessage = "FLOWMIND could not load local data."
        }
    }

    @discardableResult
    func addTextItem(title: String, text: String) -> Bool {
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return false }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return addInboxItem(
            contentType: .text,
            title: trimmedTitle.isEmpty ? String(content.prefix(60)) : trimmedTitle,
            plainTextContent: content,
            category: .note,
            summary: content,
            source: "Manual entry"
        )
    }

    @discardableResult
    func addLinkItem(urlString: String, title: String) -> Bool {
        let trimmedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedURLString), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            errorMessage = "Enter a valid web link that starts with http:// or https://."
            return false
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return addInboxItem(
            contentType: .url,
            title: trimmedTitle.isEmpty ? (url.host ?? "Saved link") : trimmedTitle,
            sourceURL: url.absoluteString,
            category: .article,
            summary: "A link you added to your Smart Inbox.",
            source: "Link"
        )
    }

    @discardableResult
    func addAttachmentItem(data: Data, filename: String, contentType: InboxContentType) -> Bool {
        guard !data.isEmpty else {
            errorMessage = "FLOWMIND could not read that item."
            return false
        }
        let category: DetectedCategory = contentType == .pdf ? .document : .unknown
        let summary = contentType == .image ? "A photo you added to your Smart Inbox." : "A file you added to your Smart Inbox."
        return addInboxItem(
            contentType: contentType,
            title: filename,
            sourceFilename: filename,
            attachmentData: data,
            category: category,
            summary: summary,
            source: contentType.label
        )
    }

    @discardableResult
    func createFlow(from definition: FlowDefinition) -> FlowSummary? {
        let flow = FlowSummary(id: UUID(), name: definition.name, icon: "bolt.fill", trigger: definition.trigger, condition: definition.condition, actionSummary: definition.actions.joined(separator: " -> "), isEnabled: true, runCount: 0, successfulRunCount: 0, lastRunAt: nil, creationSource: "manual")
        modelContext.insert(FlowRecord(flow: flow))
        return persistAndReload() ? flow : nil
    }

    @discardableResult
    func createFlow(from item: InboxItem) -> FlowSummary? {
        let flow = FlowSummary(id: UUID(), name: item.detectedCategory == .receipt ? "Receipt Capture" : "\(item.detectedCategory.label) Capture", icon: "bolt.fill", trigger: "Something is shared", condition: "It is a \(item.detectedCategory.label.lowercased())", actionSummary: item.suggestedActions.prefix(2).joined(separator: " -> "), isEnabled: true, runCount: 0, successfulRunCount: 0, lastRunAt: nil, creationSource: "suggested")
        modelContext.insert(FlowRecord(flow: flow))
        return persistAndReload() ? flow : nil
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

    @discardableResult
    private func persistAndReload() -> Bool {
        do {
            try modelContext.save()
            reload()
            return true
        } catch {
            modelContext.rollback()
            errorMessage = "Your change could not be saved locally."
            return false
        }
    }

    private func refreshPatterns() {
        patternSuggestions = patternService.suggestions(from: activity, inbox: inboxItems)
    }

    @discardableResult
    private func addInboxItem(
        contentType: InboxContentType,
        title: String,
        sourceFilename: String? = nil,
        sourceURL: String? = nil,
        plainTextContent: String? = nil,
        attachmentData: Data? = nil,
        category: DetectedCategory,
        summary: String,
        source: String
    ) -> Bool {
        let now = Date()
        let item = InboxItem(
            id: UUID(),
            createdAt: now,
            updatedAt: now,
            contentType: contentType,
            title: title,
            sourceFilename: sourceFilename,
            sourceURL: sourceURL,
            plainTextContent: plainTextContent,
            attachmentData: attachmentData,
            processingStatus: .ready,
            detectedCategory: category,
            summary: summary,
            extractedFields: ["Source": source],
            suggestedActions: ["Generate summary", "Add tag", "Archive item"],
            isArchived: false
        )
        modelContext.insert(InboxItemRecord(item: item))
        return persistAndReload()
    }
}
