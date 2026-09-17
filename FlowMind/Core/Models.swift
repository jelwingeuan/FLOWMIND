import Foundation
import SwiftData

enum InboxContentType: String, CaseIterable, Codable {
    case image
    case pdf
    case url
    case text
    case unknown

    var label: String {
        switch self {
        case .image: "Image"
        case .pdf: "PDF"
        case .url: "URL"
        case .text: "Text"
        case .unknown: "Item"
        }
    }
}

enum ProcessingStatus: String, CaseIterable, Codable {
    case waiting
    case processing
    case ready
    case failed
}

enum DetectedCategory: String, CaseIterable, Codable {
    case assignment
    case receipt
    case visualReference
    case product
    case document
    case article
    case note
    case unknown

    var label: String {
        switch self {
        case .assignment: "University Assignment"
        case .receipt: "Receipt"
        case .visualReference: "Visual Reference"
        case .product: "Product"
        case .document: "Document"
        case .article: "Article"
        case .note: "Note"
        case .unknown: "Uncategorized"
        }
    }
}

struct InboxItem: Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let contentType: InboxContentType
    let title: String
    let sourceFilename: String?
    let sourceURL: String?
    let plainTextContent: String?
    let attachmentData: Data?
    let processingStatus: ProcessingStatus
    let detectedCategory: DetectedCategory
    let summary: String
    let extractedFields: [String: String]
    let suggestedActions: [String]
    let isArchived: Bool

    init(
        id: UUID,
        createdAt: Date,
        updatedAt: Date,
        contentType: InboxContentType,
        title: String,
        sourceFilename: String?,
        sourceURL: String?,
        plainTextContent: String?,
        attachmentData: Data? = nil,
        processingStatus: ProcessingStatus,
        detectedCategory: DetectedCategory,
        summary: String,
        extractedFields: [String: String],
        suggestedActions: [String],
        isArchived: Bool
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.contentType = contentType
        self.title = title
        self.sourceFilename = sourceFilename
        self.sourceURL = sourceURL
        self.plainTextContent = plainTextContent
        self.attachmentData = attachmentData
        self.processingStatus = processingStatus
        self.detectedCategory = detectedCategory
        self.summary = summary
        self.extractedFields = extractedFields
        self.suggestedActions = suggestedActions
        self.isArchived = isArchived
    }
}

struct FlowSummary: Identifiable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let trigger: String
    let condition: String
    let actionSummary: String
    let isEnabled: Bool
    let runCount: Int
    let successfulRunCount: Int
    let lastRunAt: Date?
    let creationSource: String
}

struct ActivityRecord: Identifiable, Hashable {
    let id: UUID
    let flowName: String
    let action: String
    let timestamp: Date
    let status: String
}

struct PatternSuggestion: Identifiable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let actions: [String]
    let category: DetectedCategory
}

@Model
final class InboxItemRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var contentTypeRaw: String
    var title: String
    var sourceFilename: String?
    var sourceURL: String?
    var plainTextContent: String?
    @Attribute(.externalStorage) var attachmentData: Data?
    var processingStatusRaw: String
    var detectedCategoryRaw: String
    var summary: String
    var extractedFieldsJSON: String
    var suggestedActionsJSON: String
    var isArchived: Bool

    init(item: InboxItem) {
        id = item.id
        createdAt = item.createdAt
        updatedAt = item.updatedAt
        contentTypeRaw = item.contentType.rawValue
        title = item.title
        sourceFilename = item.sourceFilename
        sourceURL = item.sourceURL
        plainTextContent = item.plainTextContent
        attachmentData = item.attachmentData
        processingStatusRaw = item.processingStatus.rawValue
        detectedCategoryRaw = item.detectedCategory.rawValue
        summary = item.summary
        extractedFieldsJSON = Self.encode(item.extractedFields)
        suggestedActionsJSON = Self.encode(item.suggestedActions)
        isArchived = item.isArchived
    }

    var domainValue: InboxItem {
        InboxItem(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            contentType: InboxContentType(rawValue: contentTypeRaw) ?? .unknown,
            title: title,
            sourceFilename: sourceFilename,
            sourceURL: sourceURL,
            plainTextContent: plainTextContent,
            attachmentData: attachmentData,
            processingStatus: ProcessingStatus(rawValue: processingStatusRaw) ?? .ready,
            detectedCategory: DetectedCategory(rawValue: detectedCategoryRaw) ?? .unknown,
            summary: summary,
            extractedFields: Self.decode(extractedFieldsJSON, as: [String: String].self) ?? [:],
            suggestedActions: Self.decode(suggestedActionsJSON, as: [String].self) ?? [],
            isArchived: isArchived
        )
    }

    private static func encode<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    private static func decode<T: Decodable>(_ value: String, as type: T.Type) -> T? {
        try? JSONDecoder().decode(type, from: Data(value.utf8))
    }
}

@Model
final class FlowRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var createdAt: Date
    var updatedAt: Date
    var isEnabled: Bool
    var trigger: String
    var condition: String
    var actionSummary: String
    var runCount: Int
    var successfulRunCount: Int
    var lastRunAt: Date?
    var creationSource: String

    init(flow: FlowSummary) {
        id = flow.id
        name = flow.name
        icon = flow.icon
        createdAt = Date()
        updatedAt = Date()
        isEnabled = flow.isEnabled
        trigger = flow.trigger
        condition = flow.condition
        actionSummary = flow.actionSummary
        runCount = flow.runCount
        successfulRunCount = flow.successfulRunCount
        lastRunAt = flow.lastRunAt
        creationSource = flow.creationSource
    }

    var domainValue: FlowSummary {
        FlowSummary(id: id, name: name, icon: icon, trigger: trigger, condition: condition, actionSummary: actionSummary, isEnabled: isEnabled, runCount: runCount, successfulRunCount: successfulRunCount, lastRunAt: lastRunAt, creationSource: creationSource)
    }
}

@Model
final class FlowRunRecord {
    @Attribute(.unique) var id: UUID
    var flowID: UUID
    var startedAt: Date
    var completedAt: Date?
    var status: String
    var inputItemID: UUID
    var executedActions: String
    var errorMessage: String?

    init(flowID: UUID, inputItemID: UUID, actions: [String]) {
        id = UUID()
        self.flowID = flowID
        startedAt = Date()
        completedAt = Date()
        status = "completed"
        self.inputItemID = inputItemID
        executedActions = actions.joined(separator: ", ")
        errorMessage = nil
    }
}
