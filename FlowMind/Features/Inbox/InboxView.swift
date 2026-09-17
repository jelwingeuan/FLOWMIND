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
                    EmptyStateView(icon: "tray", title: "Your Smart Inbox is empty.", detail: "Share a screenshot, document, link, or note to FLOWMIND.")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
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
                .presentationDetents([.medium])
        }
    }
}

struct AddInboxItemSheet: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Capture something you want FLOWMIND to remember.")
                    .font(.title3.weight(.semibold))
                Button {
                    store.addTextItem()
                    dismiss()
                } label: {
                    Label("Create a quick note", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                Text("Share Extension, Photos, Files, URLs, and App Intents will connect to this same inbox as the V1 integrations land.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(24)
            .navigationTitle("New item")
            .navigationBarTitleDisplayMode(.inline)
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
    }
}
