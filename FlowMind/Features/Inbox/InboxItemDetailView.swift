import SwiftUI

struct InboxItemDetailView: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(UserEducationState.self) private var education
    let item: InboxItem
    @State private var firstCreatedFlow: FlowSummary?
    @State private var showingCreatedFlow = false

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
                        Text("Summary").font(.headline)
                        Text(item.summary).foregroundStyle(.secondary)
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
                    store.archive(item: item)
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
        .sheet(item: $firstCreatedFlow) { flow in
            FirstFlowSuccessSheet(flow: flow) { }
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.flowMindAccent.opacity(0.11))
            VStack(spacing: 12) {
                Image(systemName: previewIcon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Color.flowMindAccent)
                    .accessibilityHidden(true)
                Text(item.contentType.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(44)
        }
        .frame(maxWidth: .infinity)
    }

    private var previewIcon: String {
        switch item.contentType {
        case .image: "photo"
        case .pdf: "doc.text"
        case .url: "link"
        case .text: "text.alignleft"
        case .unknown: "tray"
        }
    }
}
