import SwiftUI

struct MindView: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(UserEducationState.self) private var education
    @State private var showingHelp = false
    @State private var selectedSuggestion: PatternSuggestion?
    @State private var showingSaveError = false
    @State private var showingCreated = false
    @State private var didCreateFlow = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Patterns from the work you choose to share.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Suggestions")
                    if store.patternSuggestions.isEmpty {
                        VStack(spacing: 16) {
                            EmptyStateView(icon: "lightbulb", title: "FLOWMIND is still learning.", detail: "As you repeat actions, possible automations will appear here.")
                                .frame(maxWidth: .infinity)
                                .padding(.top, 28)
                            Button("How Mind Works") {
                                showingHelp = true
                            }
                            .buttonStyle(SecondaryTextButtonStyle())
                        }
                    } else {
                        ForEach(store.patternSuggestions) { suggestion in
                            PatternCard(suggestion: suggestion) {
                                selectedSuggestion = suggestion
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Learning status")
                    FlowMindCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "eye")
                                    .foregroundStyle(Color.flowMindAccent)
                                Text("Learning from your Inbox")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                StatusBadge(title: store.inboxItems.isEmpty ? "Waiting" : "Active", color: store.inboxItems.isEmpty ? .secondary : .flowMindSuccess)
                            }
                            Text("Suggestions appear after you add three similar items. You review each Flow before it is saved.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.flowMindPrimaryBackground)
        .navigationTitle("Mind")
        .sheet(isPresented: $showingHelp) {
            NavigationStack { GettingStartedView() }
        }
        .sheet(item: $selectedSuggestion, onDismiss: {
            if didCreateFlow {
                showingCreated = true
                didCreateFlow = false
            }
        }) { suggestion in
            NavigationStack {
                ScrollView {
                    GeneratedFlowPreview(definition: suggestion.flowDefinition) {
                        let isFirstFlow = store.flows.isEmpty && !education.hasCreatedFirstFlow
                        if store.createFlow(from: suggestion.flowDefinition, source: "suggested") != nil {
                            if isFirstFlow { education.markFirstFlowCreated() }
                            didCreateFlow = true
                            selectedSuggestion = nil
                        } else {
                            showingSaveError = true
                        }
                    }
                    .padding(20)
                }
                .navigationTitle("Review suggestion")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { selectedSuggestion = nil }
                    }
                }
                .alert("Flow could not be saved", isPresented: $showingSaveError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(store.errorMessage ?? "Please try again.")
                }
            }
        }
        .alert("Flow created", isPresented: $showingCreated) {
            Button("Done", role: .cancel) { }
        } message: {
            Text("Find your new Flow in the Flows tab.")
        }
    }
}

struct PatternCard: View {
    let suggestion: PatternSuggestion
    let onReview: () -> Void

    var body: some View {
        FlowMindGlassCard(tint: Color.flowMindAccent) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color.flowMindWarning)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("POSSIBLE AUTOMATION")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.flowMindWarning)
                        Text(suggestion.title).font(.headline)
                    }
                }
                Text(suggestion.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(suggestion.actions, id: \.self) { action in
                        Label(action, systemImage: "checkmark")
                            .font(.subheadline)
                    }
                }
                Button("Review Flow", systemImage: "arrow.right", action: onReview)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.flowMindAccent)
                    .frame(minHeight: 44)
            }
        }
    }
}
