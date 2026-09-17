import SwiftUI

struct FlowsView: View {
    @Environment(FlowMindStore.self) private var store
    @State private var showingBuilder = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if store.flows.isEmpty {
                    EmptyStateView(icon: "bolt", title: "No Flows yet.", detail: "Teach FLOWMIND something you do repeatedly.")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else {
                    ForEach(store.flows) { flow in
                        FlowCard(flow: flow)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.flowMindBackground)
        .navigationTitle("Flows")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingBuilder = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create a Flow")
            }
        }
        .sheet(isPresented: $showingBuilder) {
            FlowBuilderView()
        }
    }
}

struct FlowCard: View {
    @Environment(FlowMindStore.self) private var store
    let flow: FlowSummary
    @State private var showingRunSheet = false

    var body: some View {
        FlowMindCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: flow.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.flowMindAccent)
                        .frame(width: 42, height: 42)
                        .background(Color.flowMindAccent.opacity(0.11))
                        .clipShape(.rect(cornerRadius: 13))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(flow.name).font(.headline)
                        Text(flow.creationSource.capitalized + " Flow")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(title: flow.isEnabled ? "On" : "Off", color: flow.isEnabled ? .flowMindSuccess : .secondary)
                }
                FlowStepLine(label: "WHEN", value: flow.trigger, icon: "arrow.down")
                FlowStepLine(label: "IF", value: flow.condition, icon: "arrow.down")
                FlowStepLine(label: "DO", value: flow.actionSummary, icon: nil)
                HStack {
                    Text("\(flow.successfulRunCount)/\(flow.runCount) successful runs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showingRunSheet = true
                    } label: {
                        Label("Run", systemImage: "play.fill")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showingRunSheet) {
            RunFlowSheet(flow: flow)
        }
    }
}

struct FlowStepLine: View {
    let label: String
    let value: String
    let icon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(Color.flowMindAccent)
            HStack {
                Text(value).font(.subheadline.weight(.medium))
                Spacer()
            }
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
    }
}

struct RunFlowSheet: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let flow: FlowSummary
    @State private var selectedItemID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Input") {
                    Picker("Inbox item", selection: $selectedItemID) {
                        Text("Choose an item").tag(UUID?.none)
                        ForEach(store.inboxItems) { item in
                            Text(item.title).tag(UUID?.some(item.id))
                        }
                    }
                }
                Section {
                    Button {
                        guard let selectedItemID, let item = store.inboxItems.first(where: { $0.id == selectedItemID }) else { return }
                        store.run(flow: flow, with: item)
                        dismiss()
                    } label: {
                        Label("Run Flow", systemImage: "play.fill")
                    }
                    .disabled(selectedItemID == nil)
                }
            }
            .navigationTitle("Run \(flow.name)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
