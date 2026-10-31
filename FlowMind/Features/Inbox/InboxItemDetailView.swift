import PDFKit
import QuickLook
import SwiftUI

struct InboxItemDetailView: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(UserEducationState.self) private var education
    @Environment(\.dismiss) private var dismiss
    let item: InboxItem
    @State private var firstCreatedFlow: FlowSummary?
    @State private var showingCreatedFlow = false
    @State private var showingArchiveError = false
    @State private var previewImage: UIImage?
    @State private var pdfDocument: PDFDocument?
    @State private var pdfThumbnail: UIImage?
    @State private var previewFailure: String?
    @State private var isLoadingPreview = false
    @State private var showingPDF = false
    @State private var requestedFilePreview: UUID?
    @State private var isPreparingFile = false
    @State private var temporaryPreview: TemporaryAttachmentPreview?
    @State private var quickLookURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                preview
                if education.shouldShowFirstItemGuidance && store.inboxItems.count == 1 {
                    FirstItemGuidanceCard {
                        education.dismissFirstItemGuidance()
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    HStack(spacing: 8) {
                        StatusBadge(title: item.detectedCategory.label, color: .flowMindAccent)
                        StatusBadge(title: item.processingStatus.rawValue.capitalized, color: .flowMindSuccess)
                    }
                }
                FlowMindCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.contentType == .text ? "Note" : "Summary").font(.headline)
                        Text(item.contentType == .text ? (item.plainTextContent ?? item.summary) : item.summary)
                            .foregroundStyle(.secondary)
                    }
                }
                if let originalURL {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(originalURL.absoluteString)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Link(destination: originalURL) {
                            Label("Open Original Link", systemImage: "arrow.up.right.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                if !item.extractedFields.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Key Information")
                        FlowMindCard {
                            VStack(spacing: 12) {
                                ForEach(item.extractedFields.sorted(by: { $0.key < $1.key }), id: \.key) { field in
                                    HStack {
                                        Text(field.key).foregroundStyle(.secondary)
                                        Spacer()
                                        Text(field.value).fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Suggested Actions")
                    ForEach(item.suggestedActions, id: \.self) { action in
                        Label(action, systemImage: "checkmark.circle")
                            .foregroundStyle(.primary)
                    }
                }
                Button {
                    let isFirstFlow = store.flows.isEmpty && !education.hasCreatedFirstFlow
                    guard let flow = store.createFlow(from: item) else { return }
                    if isFirstFlow {
                        education.markFirstFlowCreated()
                        firstCreatedFlow = flow
                    } else {
                        showingCreatedFlow = true
                    }
                } label: {
                    Label("Create Flow from these actions", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryGlassButtonStyle())
            }
            .padding(20)
        }
        .background(Color.flowMindBackground)
        .navigationTitle("Item detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if store.archive(item: item) {
                        dismiss()
                    } else {
                        showingArchiveError = true
                    }
                } label: {
                    Image(systemName: "archivebox")
                }
                .accessibilityLabel("Archive item")
            }
        }
        .alert("Flow created", isPresented: $showingCreatedFlow) {
            Button("Done", role: .cancel) { }
        } message: {
            Text("You can find it in the Flows tab and run it on a compatible item.")
        }
        .alert("Item could not be archived", isPresented: $showingArchiveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(store.errorMessage ?? "Please try again.")
        }
        .sheet(item: $firstCreatedFlow) { flow in
            FirstFlowSuccessSheet(flow: flow) { }
        }
        .sheet(isPresented: $showingPDF) {
            if let pdfDocument {
                NavigationStack {
                    PDFDocumentView(document: pdfDocument)
                        .navigationTitle(item.sourceFilename ?? "PDF")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showingPDF = false }
                            }
                        }
                }
            }
        }
        .task(id: item.id) { await loadPreview() }
        .task(id: requestedFilePreview) {
            guard requestedFilePreview != nil else { return }
            await prepareOtherFilePreview()
        }
        .quickLookPreview($quickLookURL)
        .onChange(of: quickLookURL) { oldURL, newURL in
            guard oldURL != nil, newURL == nil, let temporaryPreview else { return }
            self.temporaryPreview = nil
            Task.detached(priority: .utility) { try? temporaryPreview.remove() }
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let previewImage {
            attachmentImage(previewImage)
                .accessibilityLabel("Saved photo: \(item.title)")
        } else if let pdfThumbnail {
            VStack(spacing: 12) {
                attachmentImage(pdfThumbnail)
                    .accessibilityLabel("First page of \(item.title)")
                Button("Read PDF", systemImage: "doc.text.magnifyingglass") {
                    showingPDF = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.flowMindAccent.opacity(0.11))
                VStack(spacing: 12) {
                    if isLoadingPreview {
                        ProgressView("Loading original...")
                    } else {
                        Image(systemName: previewIcon)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(Color.flowMindAccent)
                            .accessibilityHidden(true)
                        Text(previewFailure ?? item.contentType.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        if pdfDocument != nil {
                            Button("Read PDF", systemImage: "doc.text.magnifyingglass") {
                                showingPDF = true
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        if item.contentType == .unknown {
                            Button {
                                requestedFilePreview = UUID()
                            } label: {
                                if isPreparingFile {
                                    ProgressView("Preparing file...")
                                } else {
                                    Label("Open File", systemImage: "doc.text.magnifyingglass")
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(isPreparingFile)
                        }
                        if previewFailure != nil && item.contentType != .unknown {
                            Button("Try Again") { Task { await loadPreview() } }
                                .buttonStyle(SecondaryTextButtonStyle())
                        }
                    }
                }
                .padding(44)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func attachmentImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: 360)
            .background(Color.flowMindSurface)
            .clipShape(.rect(cornerRadius: 8))
    }

    private var originalURL: URL? {
        guard item.contentType == .url,
              let sourceURL = item.sourceURL,
              let url = URL(string: sourceURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else { return nil }
        return url
    }

    @MainActor
    private func loadPreview() async {
        guard item.contentType == .image || item.contentType == .pdf else { return }
        previewImage = nil
        pdfDocument = nil
        pdfThumbnail = nil
        previewFailure = nil
        isLoadingPreview = true
        defer { isLoadingPreview = false }
        await Task.yield()
        guard !Task.isCancelled else { return }
        guard let data = store.attachmentData(for: item.id) else {
            previewFailure = store.errorMessage ?? "The original file could not be loaded."
            return
        }
        if item.contentType == .image {
            previewImage = UIImage(data: data)
            if previewImage == nil { previewFailure = "This photo could not be displayed." }
        } else {
            pdfDocument = PDFDocument(data: data)
            pdfThumbnail = pdfDocument?.page(at: 0)?.thumbnail(of: CGSize(width: 600, height: 800), for: .mediaBox)
            if pdfThumbnail == nil { previewFailure = pdfDocument == nil ? "This PDF could not be opened." : "Preview unavailable." }
        }
    }

    @MainActor
    private func prepareOtherFilePreview() async {
        guard !isPreparingFile else { return }
        isPreparingFile = true
        previewFailure = nil
        defer { isPreparingFile = false }
        guard let data = store.attachmentData(for: item.id) else {
            previewFailure = store.errorMessage ?? "The original file could not be loaded."
            return
        }
        let filename = item.sourceFilename ?? item.title
        do {
            let preview = try await Task.detached(priority: .userInitiated) {
                try TemporaryAttachmentPreview(data: data, filename: filename)
            }.value
            guard !Task.isCancelled else {
                try? preview.remove()
                return
            }
            temporaryPreview = preview
            quickLookURL = preview.url
        } catch {
            previewFailure = "This file could not be opened. Please try again."
        }
    }

    private var previewIcon: String {
        switch item.contentType {
        case .image: "photo"
        case .pdf: "doc.text"
        case .url: "link"
        case .text: "text.alignleft"
        case .unknown: "doc"
        }
    }
}

private struct PDFDocumentView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = document
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document !== document {
            view.document = document
        }
    }
}
