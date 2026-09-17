import SwiftUI

struct MindView: View {
    @Environment(FlowMindStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mind")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Text("Transparent patterns from the work you choose to share.")
                        .foregroundStyle(.secondary)
                }
                SectionHeader("Suggestions")
                if store.patternSuggestions.isEmpty {
                    FlowMindCard {
                        EmptyStateView(icon: "lightbulb", title: "FLOWMIND is still learning.", detail: "Patterns will appear as you use the app.")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    }
                } else {
                    ForEach(store.patternSuggestions) { suggestion in
                        PatternCard(suggestion: suggestion)
                    }
                }
                SectionHeader("Learning status")
                FlowMindCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "eye")
                                .foregroundStyle(Color.flowMindAccent)
                            Text("Learning from explicit activity")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            StatusBadge(title: "Active", color: .flowMindSuccess)
                        }
                        Text("FLOWMIND uses a simple, visible heuristic in V1: repeated categories and action sequences become suggestions after three occurrences.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.flowMindBackground)
        .navigationTitle("Mind")
    }
}

struct PatternCard: View {
    let suggestion: PatternSuggestion

    var body: some View {
        FlowMindCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color.flowMindWarning)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("POSSIBLE AUTOMATION")
                            .font(.caption2.weight(.bold))
                            .tracking(1)
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
                Button("Create Flow", systemImage: "bolt.fill") { }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}
