import SwiftUI

struct InboxView: View {
    @Environment(FlowMindStore.self) private var store
    @State private var showingAddItem = false
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
                    EmptyStateView(icon: searchText.isEmpty ? "tray" : "magnifyingglass", title: searchText.isEmpty ? "Your Smart Inbox is empty." : "No matching items.", detail: searchText.isEmpty ? "Your saved notes will appear here." : "Try a different search.")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    if searchText.isEmpty {
                        Button("Create a note", systemImage: "square.and.pencil") {
                            showingAddItem = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .frame(maxWidth: .infinity)
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
    }
}

struct AddInboxItemSheet: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var text = ""
    @State private var showingSaveError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title (optional)", text: $title)
                }
                Section("Note") {
                    TextEditor(text: $text)
                        .frame(minHeight: 180)
                        .accessibilityLabel("Note content")
                }
            }
            .navigationTitle("New note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        if store.addTextItem(title: title, text: text) {
                            dismiss()
                        } else {
                            showingSaveError = true
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Note could not be saved", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(store.errorMessage ?? "Please try again.")
            }
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
