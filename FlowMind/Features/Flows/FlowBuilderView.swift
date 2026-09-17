import SwiftUI

struct FlowBuilderView: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(UserEducationState.self) private var education
    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var definition: FlowDefinition?
    @State private var isGenerating = false
    @State private var showingSaveError = false
    @State private var firstCreatedFlow: FlowSummary?

    private let generationService = MockFlowGenerationService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What should happen?")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                        Text("Describe a repeated task in your own words. FLOWMIND will turn it into a reviewable Flow.")
                            .foregroundStyle(.secondary)
                    }
                    TextField("Whenever I share a restaurant receipt...", text: $prompt, axis: .vertical)
                        .lineLimit(4...8)
                        .padding(14)
                        .background(Color.flowMindSurface)
                        .clipShape(.rect(cornerRadius: 15))
                        .onSubmit { generate() }
                    Button {
                        generate()
                    } label: {
                        Label(isGenerating ? "Thinking..." : "Suggest a Flow", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
                    if let definition {
                        GeneratedFlowPreview(definition: definition) {
                            let isFirstFlow = store.flows.isEmpty && !education.hasCreatedFirstFlow
                            if let flow = store.createFlow(from: definition) {
                                if isFirstFlow {
                                    education.markFirstFlowCreated()
                                    firstCreatedFlow = flow
                                } else {
                                    dismiss()
                                }
                            } else {
                                showingSaveError = true
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.flowMindBackground)
            .navigationTitle("New Flow")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Flow could not be saved", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(store.errorMessage ?? "Please try again.")
            }
            .sheet(item: $firstCreatedFlow) { flow in
                FirstFlowSuccessSheet(flow: flow) {
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func generate() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isGenerating = true
        Task { @MainActor in
            let result = try? await generationService.generate(from: prompt)
            definition = result
            isGenerating = false
        }
    }
}

struct GeneratedFlowPreview: View {
    let definition: FlowDefinition
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(definition.name).font(.headline)
                Spacer()
                StatusBadge(title: "Review", color: .flowMindWarning)
            }
            FlowStepLine(label: "WHEN", value: definition.trigger, icon: "arrow.down")
            FlowStepLine(label: "IF", value: definition.condition, icon: "arrow.down")
            VStack(alignment: .leading, spacing: 10) {
                Text("DO").font(.caption2.weight(.bold)).tracking(1).foregroundStyle(Color.flowMindAccent)
                ForEach(definition.actions, id: \.self) { action in
                    Label(action, systemImage: "checkmark.circle")
                        .font(.subheadline)
                }
            }
            Button {
                onCreate()
            } label: {
                Label("Create this Flow", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(18)
        .background(Color.flowMindSurface)
        .clipShape(.rect(cornerRadius: 20))
    }
}
