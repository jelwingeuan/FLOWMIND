import SwiftUI

struct GettingStartedView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Text("FLOWMIND is a personal workspace for turning the actions you repeat into reusable Flows.")
                    .foregroundStyle(.secondary)
            }
            Section("Getting Started") {
                GuideDisclosure(title: "What is the Smart Inbox?", detail: "The Smart Inbox holds the photos, files, links, and notes you intentionally add to FLOWMIND.")
                GuideDisclosure(title: "What is a Flow?", detail: "A Flow is a reusable set of actions you define for compatible items.")
                GuideDisclosure(title: "What is Mind?", detail: "Mind looks for repeated categories and action sequences, then offers suggestions for you to review.")
                GuideDisclosure(title: "How do I share something?", detail: "Use Add Something to choose a photo, file, link, or text. Nothing is added until you confirm it.")
                GuideDisclosure(title: "How does FLOWMIND learn?", detail: "It uses activity you create in FLOWMIND. Suggestions remain optional and require your approval.")
                GuideDisclosure(title: "How does privacy work?", detail: "FLOWMIND only works with content you choose to add. Current V1 data stays on this device and can be deleted from Settings.")
            }
        }
        .navigationTitle("Getting Started")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

struct FirstItemGuidanceCard: View {
    let onDismiss: () -> Void

    var body: some View {
        FlowMindGlassCard(tint: Color.flowMindAccent, fallbackBorder: Color.flowMindAccent.opacity(0.35)) {
            VStack(alignment: .leading, spacing: 14) {
                Label("YOUR FIRST ITEM IS READY", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(Color.flowMindAccent)
                FirstUseStep(number: 1, title: "Review", detail: "Check what FLOWMIND found.")
                FirstUseStep(number: 2, title: "Choose actions", detail: "Decide what should happen next.")
                FirstUseStep(number: 3, title: "Save as a Flow", detail: "Reuse those steps whenever you need them.")
                Button("Hide tips") {
                    onDismiss()
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct FirstFlowSuccessSheet: View {
    let flow: FlowSummary
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingRunner = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54, weight: .medium))
                .foregroundStyle(Color.flowMindSuccess)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("Your first Flow is ready.")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text("FLOWMIND can now reuse these steps when you need them.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            Button("Run Flow", systemImage: "play.fill") {
                showingRunner = true
            }
            .buttonStyle(PrimaryGlassButtonStyle())
            Button("Done") {
                onDone()
                dismiss()
            }
            .font(.body.weight(.semibold))
        }
        .padding(28)
        .presentationDetents([.medium])
        .sheet(isPresented: $showingRunner) {
            RunFlowSheet(flow: flow)
        }
        .onAppear { appeared = true }
        .sensoryFeedback(.success, trigger: appeared)
    }
}

private struct GuideDisclosure: View {
    let title: String
    let detail: String

    var body: some View {
        DisclosureGroup(title) {
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
        }
    }
}

private struct FirstUseStep: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.flowMindAccentForeground)
                .frame(width: 22, height: 22)
                .background(Color.flowMindAccent)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
