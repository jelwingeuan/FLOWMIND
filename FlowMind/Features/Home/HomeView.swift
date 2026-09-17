import SwiftUI

struct HomeView: View {
    @Environment(FlowMindStore.self) private var store
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                inboxPreview
                flowsPreview
                activityPreview
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
        }
        .background(Color.flowMindBackground)
        .navigationTitle("FLOWMIND")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                .accessibilityLabel("Open settings")
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Text("Your work, understood at a glance.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var inboxPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Smart Inbox", actionTitle: "See all") { }
            ForEach(store.inboxItems.prefix(3)) { item in
                NavigationLink {
                    InboxItemDetailView(item: item)
                } label: {
                    InboxRow(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var flowsPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Your Flows", actionTitle: "View flows") { }
            FlowMindCard {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(store.flows.prefix(3)) { flow in
                        FlowSummaryRow(flow: flow)
                    }
                }
            }
        }
    }

    private var activityPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Recent Activity")
            FlowMindCard {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(store.activity.prefix(3)) { record in
                        ActivityRow(flowName: record.flowName, action: record.action, timestamp: record.timestamp, status: record.status)
                    }
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        return switch hour {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }
}

struct InboxRow: View {
    let item: InboxItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.flowMindAccent)
                .frame(width: 42, height: 42)
                .background(Color.flowMindAccent.opacity(0.11))
                .clipShape(.rect(cornerRadius: 13))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(item.detectedCategory.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.createdAt.flowMindRelative)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch item.contentType {
        case .image: "photo"
        case .pdf: "doc.text"
        case .url: "link"
        case .text: "text.alignleft"
        case .unknown: "tray"
        }
    }
}

struct FlowSummaryRow: View {
    let flow: FlowSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: flow.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.flowMindAccent)
                .frame(width: 34, height: 34)
                .background(Color.flowMindAccent.opacity(0.1))
                .clipShape(.rect(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(flow.name).font(.subheadline.weight(.semibold))
                Text("\(flow.runCount) runs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
    }
}

struct ActivityRow: View {
    let flowName: String
    let action: String
    let timestamp: Date
    let status: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.flowMindSuccess)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(flowName).font(.subheadline.weight(.semibold))
                Text("\(action) • \(timestamp.flowMindRelative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(status)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.flowMindSuccess)
        }
    }
}
