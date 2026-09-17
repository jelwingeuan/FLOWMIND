import SwiftUI

struct HomeView: View {
    @Environment(FlowMindStore.self) private var store
    @State private var showingSettings = false
    @State private var showingCapture = false
    @State private var showingInbox = false
    @State private var showingFlows = false
    @State private var showingGettingStarted = false

    private var activeInboxCount: Int {
        store.inboxItems.filter { !$0.isArchived }.count
    }

    private var activeFlowCount: Int {
        store.flows.filter(\.isEnabled).count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header
                focusCard
                quickStats
                inboxPreview
                flowsPreview
                activityPreview
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
        }
        .scrollIndicators(.hidden)
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
        .sheet(isPresented: $showingCapture) {
            AddInboxItemSheet()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingInbox) {
            NavigationStack { InboxView() }
        }
        .sheet(isPresented: $showingFlows) {
            NavigationStack { FlowsView() }
        }
        .sheet(isPresented: $showingGettingStarted) {
            NavigationStack { GettingStartedView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Text("FLOWMIND")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.flowMindAccent)
                StatusBadge(title: "On device", color: Color.flowMindSuccess, systemImage: "lock.fill")
            }
            Text(greeting)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Text(activeInboxCount == 0 ? "Start with FLOWMIND." : "A clear view of the work you want to keep moving.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var focusCard: some View {
        FlowMindCard(padding: 20, fill: Color.flowMindAccentFill) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label("YOUR CONTROL CENTER", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(Color.flowMindAccentForeground.opacity(0.78))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.flowMindAccentForeground.opacity(0.72))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(activeInboxCount == 0 ? "Start with FLOWMIND." : "Capture the next thing.")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.flowMindAccentForeground)
                    Text(activeInboxCount == 0 ? "Send something to your Smart Inbox and decide what should happen to it." : "Keep useful context close, then turn repeated work into a Flow when you are ready.")
                        .font(.subheadline)
                        .foregroundStyle(Color.flowMindAccentForeground.opacity(0.78))
                }
                HStack(spacing: 14) {
                    Button {
                        showingCapture = true
                    } label: {
                        Label(activeInboxCount == 0 ? "Add Something" : "Quick capture", systemImage: "plus")
                    }
                    .buttonStyle(LightButtonStyle())
                    if activeInboxCount == 0 {
                        Button("How FLOWMIND works") {
                            showingGettingStarted = true
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.flowMindAccentForeground.opacity(0.82))
                    } else {
                        Text("\(activeInboxCount) items ready")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.flowMindAccentForeground.opacity(0.76))
                    }
                }
            }
        }
    }

    private var quickStats: some View {
        HStack(spacing: 0) {
            FlowMindStat(value: "\(activeInboxCount)", label: "Ready to review", systemImage: "tray.full", tint: Color.flowMindAccent)
            Divider().frame(height: 76)
            FlowMindStat(value: "\(activeFlowCount)", label: "Active Flows", systemImage: "bolt.fill", tint: Color.flowMindHighlight)
            Divider().frame(height: 76)
            FlowMindStat(value: "\(store.activity.count)", label: "Runs logged", systemImage: "checkmark.seal", tint: Color.flowMindSuccess)
        }
        .padding(.vertical, 2)
    }

    private var inboxPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Smart Inbox", actionTitle: "See all") {
                showingInbox = true
            }
            FlowMindCard(padding: 16) {
                VStack(spacing: 0) {
                    if activeInboxCount == 0 {
                        EmptyStateView(icon: "tray", title: "Your Smart Inbox is empty.", detail: "Add a photo, document, link, or text to get started.")
                            .padding(.vertical, 16)
                    }
                    ForEach(Array(store.inboxItems.filter { !$0.isArchived }.prefix(3).enumerated()), id: \.element.id) { index, item in
                        if index > 0 { Divider().padding(.vertical, 12) }
                        NavigationLink {
                            InboxItemDetailView(item: item)
                        } label: {
                            InboxRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var flowsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Your Flows", actionTitle: "View flows") {
                showingFlows = true
            }
            FlowMindCard(padding: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    if store.flows.isEmpty {
                        EmptyStateView(icon: "bolt", title: "No Flows yet.", detail: "Create your first Flow from something you do repeatedly.")
                            .padding(.vertical, 16)
                    }
                    ForEach(Array(store.flows.prefix(3).enumerated()), id: \.element.id) { index, flow in
                        if index > 0 { Divider().padding(.vertical, 12) }
                        FlowSummaryRow(flow: flow)
                    }
                }
            }
        }
    }

    private var activityPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Recent Activity")
            FlowMindCard(padding: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    if store.activity.isEmpty {
                        EmptyStateView(icon: "clock", title: "No activity yet.", detail: "Your Flow runs will appear here.")
                            .padding(.vertical, 16)
                    }
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
        HStack(spacing: 12) {
            FlowMindIconTile(systemImage: icon, size: 42)
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
            Spacer(minLength: 8)
            Text(item.createdAt.flowMindRelative)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 42)
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
            FlowMindIconTile(systemImage: flow.icon, tint: Color.flowMindHighlight, size: 38)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(flow.name).font(.subheadline.weight(.semibold))
                Text("\(flow.runCount) runs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 38)
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
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            Text(status)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.flowMindSuccess)
        }
    }
}
