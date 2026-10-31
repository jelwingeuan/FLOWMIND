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
    private var hasStartedLoading = false

    init(modelContext: ModelContext, loadImmediately: Bool = true) {
        self.modelContext = modelContext
        if loadImmediately {
            reload()
        }
    }

    func loadIfNeeded() {
        guard !hasStartedLoading else { return }
        reload()
    }

    func reload() {
        hasStartedLoading = true
        do {
            let inboxDescriptor = FetchDescriptor<InboxItemRecord>(
                predicate: #Predicate { !$0.isArchived },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            inboxItems = try modelContext.fetch(inboxDescriptor).map(\.listValue)

            let flowDescriptor = FetchDescriptor<FlowRecord>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            flows = try modelContext.fetch(flowDescriptor).map(\.domainValue)

            let flowNames = Dictionary(uniqueKeysWithValues: flows.map { ($0.id, $0.name) })
            var activityDescriptor = FetchDescriptor<FlowRunRecord>(
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            activityDescriptor.fetchLimit = 50
            activity = try modelContext.fetch(activityDescriptor).map { run in
                ActivityRecord(id: run.id, flowName: flowNames[run.flowID] ?? "FLOWMIND Flow", action: run.executedActions, timestamp: run.completedAt ?? run.startedAt, status: run.status.capitalized)
            }
            refreshPatterns()
        } catch {
            hasStartedLoading = false
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
    func createFlow(from definition: FlowDefinition, source: String = "manual") -> FlowSummary? {
        let flow = FlowSummary(id: UUID(), name: definition.name, icon: "bolt.fill", trigger: definition.trigger, condition: definition.condition, actionSummary: definition.actions.joined(separator: " -> "), isEnabled: true, runCount: 0, successfulRunCount: 0, lastRunAt: nil, creationSource: source)
        modelContext.insert(FlowRecord(flow: flow))
        guard persist() else { return nil }
        flows.append(flow)
        flows.sort { $0.name < $1.name }
        refreshPatterns()
        return flow
    }

    @discardableResult
    func createFlow(from item: InboxItem) -> FlowSummary? {
        createFlow(from: item.suggestedFlowDefinition, source: "suggested")
    }

    func setFlowEnabled(flow: FlowSummary, isEnabled: Bool) -> Bool {
        let flowID = flow.id
        let descriptor = FetchDescriptor<FlowRecord>(predicate: #Predicate { $0.id == flowID })
        guard let record = try? modelContext.fetch(descriptor).first else {
            errorMessage = "FLOWMIND could not access this Flow."
            return false
        }
        guard record.isEnabled != isEnabled else { return true }
        record.isEnabled = isEnabled
        record.updatedAt = Date()
        guard persist() else { return false }
        if let index = flows.firstIndex(where: { $0.id == flowID }) {
            flows[index] = record.domainValue
        }
        return true
    }

    func run(flow: FlowSummary, with item: InboxItem) -> Bool {
        let flowID = flow.id
        let descriptor = FetchDescriptor<FlowRecord>(predicate: #Predicate { $0.id == flowID })
        guard let record = try? modelContext.fetch(descriptor).first else {
            errorMessage = "FLOWMIND could not access this Flow."
            return false
        }
        guard record.isEnabled else {
            errorMessage = "Turn on this Flow before running it."
            return false
        }
        record.runCount += 1
        record.successfulRunCount += 1
        let completedAt = Date()
        record.lastRunAt = completedAt
        record.updatedAt = Date()
        let runRecord = FlowRunRecord(flowID: flow.id, inputItemID: item.id, actions: [record.actionSummary])
        modelContext.insert(runRecord)
        guard persist() else { return false }

        if let index = flows.firstIndex(where: { $0.id == flow.id }) {
            flows[index] = record.domainValue
        }
        activity.insert(
            ActivityRecord(id: runRecord.id, flowName: record.name, action: runRecord.executedActions, timestamp: completedAt, status: runRecord.status.capitalized),
            at: 0
        )
        if activity.count > 50 {
            activity.removeLast(activity.count - 50)
        }
        return true
    }

    func archive(item: InboxItem) -> Bool {
        let itemID = item.id
        let descriptor = FetchDescriptor<InboxItemRecord>(predicate: #Predicate { $0.id == itemID })
        guard let record = try? modelContext.fetch(descriptor).first else {
            errorMessage = "FLOWMIND could not access this item."
            return false
        }
        record.isArchived = true
        record.updatedAt = Date()
        guard persist() else { return false }
        inboxItems.removeAll { $0.id == item.id }
        refreshPatterns()
        return true
    }

    func attachmentData(for itemID: UUID) -> Data? {
        let descriptor = FetchDescriptor<InboxItemRecord>(predicate: #Predicate { $0.id == itemID })
        do {
            guard let data = try modelContext.fetch(descriptor).first?.attachmentData else {
                errorMessage = "The original file is no longer available."
                return nil
            }
            return data
        } catch {
            errorMessage = "FLOWMIND could not load this file."
            return nil
        }
    }

    func deleteAllData() -> Bool {
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
            return true
        } catch {
            modelContext.rollback()
            errorMessage = "Local data could not be deleted."
            return false
        }
    }

    @discardableResult
    private func persist() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            errorMessage = "Your change could not be saved locally."
            return false
        }
    }

    private func refreshPatterns() {
        patternSuggestions = patternService.suggestions(from: activity, inbox: inboxItems)
            .filter { suggestion in
                !flows.contains { $0.name == suggestion.flowDefinition.name }
            }
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
        guard persist() else { return false }
        inboxItems.insert(item, at: 0)
        refreshPatterns()
        return true
    }
}

struct TemporaryAttachmentPreview: Sendable {
    let url: URL
    private let directory: URL

    init(data: Data, filename: String) throws {
        let name = URL(fileURLWithPath: filename).lastPathComponent
        let safeName = name.isEmpty || name == "." || name == ".." ? "Attachment" : name
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowMindPreview-\(UUID().uuidString)", isDirectory: true)
        let url = directory.appendingPathComponent(safeName)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
            try data.write(to: url, options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
        self.url = url
        self.directory = directory
    }

    func remove() throws {
        try FileManager.default.removeItem(at: directory)
    }
}
