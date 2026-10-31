import SwiftUI

struct FlowsView: View {
    @Environment(FlowMindStore.self) private var store
    @State private var showingBuilder = false
    @State private var showingHelp = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if store.flows.isEmpty {
                    EmptyStateView(icon: "bolt", title: "No Flows yet.", detail: "Flows are reusable actions you teach FLOWMIND.")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 88)
                        .padding(.bottom, 24)
                    Button {
                        showingBuilder = true
                    } label: {
                        Label("Create Your First Flow", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    Button("Learn About Flows") {
                        showingHelp = true
                    }
                    .buttonStyle(SecondaryTextButtonStyle())
                } else {
                    ForEach(store.flows) { flow in
                        FlowCard(flow: flow)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.flowMindPrimaryBackground)
        .navigationTitle("Flows")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingHelp = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Learn about Flows")
            }
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
        .sheet(isPresented: $showingHelp) {
            NavigationStack { GettingStartedView() }
        }
    }
}

struct FlowCard: View {
    @Environment(FlowMindStore.self) private var store
    let flow: FlowSummary
    @State private var showingRunSheet = false
    @State private var showingUpdateError = false

    private var isEnabled: Bool {
        store.flows.first(where: { $0.id == flow.id })?.isEnabled ?? flow.isEnabled
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { isEnabled },
            set: { enabled in
                if !store.setFlowEnabled(flow: flow, isEnabled: enabled) {
                    showingUpdateError = true
                }
            }
        )
    }

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
                    Toggle(isEnabled ? "On" : "Off", isOn: enabledBinding)
                        .toggleStyle(.switch)
                        .font(.caption.weight(.semibold))
                        .fixedSize()
                        .accessibilityLabel("\(flow.name) enabled")
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
                    .disabled(!isEnabled)
                }
            }
        }
        .sheet(isPresented: $showingRunSheet) {
            RunFlowSheet(flow: flow)
        }
        .alert("Flow could not be updated", isPresented: $showingUpdateError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(store.errorMessage ?? "Please try again.")
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
    @State private var showingRunError = false

    private var isEnabled: Bool {
        store.flows.first(where: { $0.id == flow.id })?.isEnabled == true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Input") {
                    if store.inboxItems.isEmpty {
                        EmptyStateView(icon: "tray", title: "Your Smart Inbox is empty.", detail: "A saved item is needed for this Flow.")
                            .padding(.vertical, 16)
                    } else {
                        Picker("Inbox item", selection: $selectedItemID) {
                            Text("Choose an item").tag(UUID?.none)
                            ForEach(store.inboxItems) { item in
                                Text(item.title).tag(UUID?.some(item.id))
                            }
                        }
                    }
                }
                Section {
                    Button {
                        guard let selectedItemID, let item = store.inboxItems.first(where: { $0.id == selectedItemID }) else { return }
                        if store.run(flow: flow, with: item) {
                            dismiss()
                        } else {
                            showingRunError = true
                        }
                    } label: {
                        Label("Run Flow", systemImage: "play.fill")
                    }
                    .disabled(selectedItemID == nil || !isEnabled)
                }
            }
            .navigationTitle("Run \(flow.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Flow could not be run", isPresented: $showingRunError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(store.errorMessage ?? "Please try again.")
            }
        }
    }
}
