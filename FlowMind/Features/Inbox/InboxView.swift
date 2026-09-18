import Foundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct InboxView: View {
    @Environment(FlowMindStore.self) private var store
    @State private var showingAddItem = false
    @State private var showingGettingStarted = false
    @State private var searchText = ""

    private var visibleItems: [InboxItem] {
        let active = store.inboxItems.filter { !$0.isArchived }
        guard !searchText.isEmpty else { return active }
        return active.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) || item.detectedCategory.label.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if visibleItems.isEmpty {
                    EmptyStateView(icon: searchText.isEmpty ? "tray" : "magnifyingglass", title: searchText.isEmpty ? "Your Smart Inbox is empty." : "No matching items.", detail: searchText.isEmpty ? "Add a photo, document, link, or text to get started." : "Try a different search.")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    if searchText.isEmpty {
                        Button("Add Something", systemImage: "plus") {
                            showingAddItem = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .frame(maxWidth: .infinity)
                        Button("Learn How to Share") {
                            showingGettingStarted = true
                        }
                        .buttonStyle(SecondaryTextButtonStyle())
                    }
                } else {
                    ForEach(visibleItems) { item in
                        NavigationLink {
                            InboxItemDetailView(item: item)
                        } label: {
                            FlowMindCard { InboxRow(item: item) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .safeAreaPadding(.bottom, 96)
        .background(Color.flowMindBackground)
        .navigationTitle("Inbox")
        .searchable(text: $searchText, prompt: "Search your inbox")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add inbox item")
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddInboxItemSheet()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingGettingStarted) {
            NavigationStack { GettingStartedView() }
        }
    }
}

struct AddInboxItemSheet: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(UserEducationState.self) private var education
    @Environment(\.dismiss) private var dismiss
    @State private var kind: AddItemKind = .text
    @State private var title = ""
    @State private var text = ""
    @State private var link = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isLoadingPhoto = false
    @State private var selectedFileData: Data?
    @State private var selectedFileName: String?
    @State private var isLoadingFile = false
    @State private var showingFileImporter = false
    @State private var showingSaveError = false
    @State private var showingFirstItemReady = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Add Something") {
                    Picker("Content type", selection: $kind) {
                        ForEach(AddItemKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                switch kind {
                case .photo:
                    Section("Photo") {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Choose photo", systemImage: "photo")
                        }
                        if isLoadingPhoto {
                            HStack {
                                ProgressView()
                                Text("Preparing photo...")
                            }
                        } else if photoData != nil {
                            Label("Photo selected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Color.flowMindSuccess)
                        }
                    }
                case .file:
                    Section("File") {
                        Button {
                            showingFileImporter = true
                        } label: {
                            Label(selectedFileName == nil ? "Choose file" : "Choose another file", systemImage: "doc")
                        }
                        if isLoadingFile {
                            HStack {
                                ProgressView()
                                Text("Preparing file...")
                            }
                        } else if let selectedFileName {
                            Label(selectedFileName, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Color.flowMindSuccess)
                                .lineLimit(1)
                        }
                    }
                case .link:
                    Section("Link") {
                        TextField("https://example.com", text: $link)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                        TextField("Title (optional)", text: $title)
                    }
                case .text:
                    Section("Title") {
                        TextField("Title (optional)", text: $title)
                    }
                    Section("Note") {
                        TextEditor(text: $text)
                            .frame(minHeight: 180)
                            .accessibilityLabel("Note content")
                    }
                }
            }
            .navigationTitle("Add Something")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        save()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.item]) { result in
                importFile(result)
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else {
                    photoData = nil
                    return
                }
                Task { await loadPhoto(item) }
            }
            .alert("Item could not be saved", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(store.errorMessage ?? "Please try again.")
            }
            .alert("Your first item is ready.", isPresented: $showingFirstItemReady) {
                Button("Review in Inbox") { dismiss() }
            } message: {
                Text("Open it from Smart Inbox to review what FLOWMIND found and choose what should happen next.")
            }
        }
    }

    private var isSaveDisabled: Bool {
        switch kind {
        case .photo: photoData == nil || isLoadingPhoto
        case .file: selectedFileData == nil || selectedFileName == nil || isLoadingFile
        case .link: link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .text: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func save() {
        let didSave: Bool
        switch kind {
        case .photo:
            didSave = store.addAttachmentItem(data: photoData ?? Data(), filename: "Selected photo", contentType: .image)
        case .file:
            let filename = selectedFileName ?? "Imported file"
            let contentType: InboxContentType = URL(fileURLWithPath: filename).pathExtension.lowercased() == "pdf" ? .pdf : .unknown
            didSave = store.addAttachmentItem(data: selectedFileData ?? Data(), filename: filename, contentType: contentType)
        case .link:
            didSave = store.addLinkItem(urlString: link, title: title)
        case .text:
            didSave = store.addTextItem(title: title, text: text)
        }
        guard didSave else {
            showingSaveError = true
            return
        }
        if store.inboxItems.count == 1 && !education.hasAddedFirstItem {
            education.markFirstItemAdded()
            showingFirstItemReady = true
        } else {
            dismiss()
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else {
            store.errorMessage = "FLOWMIND could not read that photo."
            showingSaveError = true
            return
        }
        photoData = data
    }

    private func importFile(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        selectedFileData = nil
        selectedFileName = nil
        let accessed = url.startAccessingSecurityScopedResource()
        isLoadingFile = true
        Task {
            let data = await Task.detached(priority: .userInitiated) {
                try? Data(contentsOf: url, options: [.mappedIfSafe])
            }.value
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
                isLoadingFile = false
            }
            guard !Task.isCancelled else { return }
            guard let data, !data.isEmpty else {
                store.errorMessage = "FLOWMIND could not read that file."
                showingSaveError = true
                return
            }
            selectedFileData = data
            selectedFileName = url.lastPathComponent
        }
    }
}

private enum AddItemKind: String, CaseIterable, Identifiable {
    case photo
    case file
    case link
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photo: "Photo"
        case .file: "File"
        case .link: "Link"
        case .text: "Text"
        }
    }

    var systemImage: String {
        switch self {
        case .photo: "photo"
        case .file: "doc"
        case .link: "link"
        case .text: "text.alignleft"
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(Color.flowMindAccent)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
