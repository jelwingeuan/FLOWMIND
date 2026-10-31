import SwiftUI

struct HomeView: View {
    @Environment(FlowMindStore.self) private var store
    @Binding private var selection: AppTab
    @State private var showingSettings = false
    @State private var showingCapture = false
    @State private var showingGettingStarted = false

    init(selection: Binding<AppTab> = .constant(.home)) {
        _selection = selection
    }

    private var activeInboxCount: Int {
        store.inboxItems.filter { !$0.isArchived }.count
    }

    private var activeFlowCount: Int {
        store.flows.filter(\.isEnabled).count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                header
                capturePanel
                quickStats
                inboxPreview
                flowsPreview
                activityPreview
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color.flowMindPrimaryBackground)
        .navigationTitle("FLOWMIND")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
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
        .sheet(isPresented: $showingGettingStarted) {
            NavigationStack { GettingStartedView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(greeting)
                .font(.system(.largeTitle, design: .default).weight(.bold))
            Text(activeInboxCount == 0 && store.flows.isEmpty
                 ? "Make the work you repeat easier."
                 : "Your work, in motion.")
                .font(.body)
                .foregroundStyle(.secondary)
            Label("Private on this iPhone", systemImage: "lock.shield")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.flowMindAccent)
                .padding(.top, 2)
        }
    }

    private var capturePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.flowMindAccent)
                    .accessibilityHidden(true)
                Spacer()
                Text("CAPTURE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            Text(activeInboxCount == 0 ? "Start with something." : "Capture the next thing.")
                .font(.system(.title2, design: .default).weight(.semibold))
            Text("Add a note, link, photo, or document. Keep it in your Inbox until you're ready to act.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showingCapture = true
            } label: {
                Label("Add to Smart Inbox", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("How FLOWMIND works", systemImage: "arrow.up.right") {
                showingGettingStarted = true
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.flowMindAccent)
        }
        .padding(20)
        .background(Color.flowMindSurface)
        .clipShape(.rect(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).stroke(Color.flowMindCardBorder, lineWidth: 1) }
    }

    private var quickStats: some View {
        HStack(alignment: .top, spacing: 12) {
            FlowMindStat(value: "\(activeInboxCount)", label: "In Inbox", tint: .flowMindAccent)
            Divider().frame(height: 64)
            FlowMindStat(value: "\(activeFlowCount)", label: "Active Flows", tint: .flowMindHighlight)
            Divider().frame(height: 64)
            FlowMindStat(value: "\(store.activity.count)", label: "Runs logged", tint: .flowMindSuccess)
        }
        .padding(.vertical, 4)
    }

    private var inboxPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Smart Inbox", actionTitle: "Open Inbox") {
                selection = .inbox
            }
            VStack(spacing: 0) {
                if activeInboxCount == 0 {
                    HomeEmptyRow(icon: "tray", title: "Your Smart Inbox is empty.", detail: "Things you add will be ready to review here.")
                }
                ForEach(Array(store.inboxItems.filter { !$0.isArchived }.prefix(3).enumerated()), id: \.element.id) { index, item in
                    if index > 0 { Divider() }
                    NavigationLink {
                        InboxItemDetailView(item: item)
                    } label: {
                        InboxRow(item: item)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var flowsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Flows", actionTitle: "Open Flows") {
                selection = .flows
            }
            VStack(alignment: .leading, spacing: 0) {
                if store.flows.isEmpty {
                    HomeEmptyRow(icon: "bolt", title: "No Flows yet.", detail: "Create one when a task starts to repeat.")
                }
                ForEach(Array(store.flows.prefix(3).enumerated()), id: \.element.id) { index, flow in
                    if index > 0 { Divider() }
                    FlowSummaryRow(flow: flow)
                        .padding(.vertical, 10)
                }
            }
        }
    }

    private var activityPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Recent Activity")
            VStack(alignment: .leading, spacing: 0) {
                if store.activity.isEmpty {
                    HomeEmptyRow(icon: "clock.arrow.circlepath", title: "No activity yet.", detail: "Flow runs will appear here.")
                }
                ForEach(Array(store.activity.prefix(3).enumerated()), id: \.element.id) { index, record in
                    if index > 0 { Divider() }
                    ActivityRow(flowName: record.flowName, action: record.action, timestamp: record.timestamp, status: record.status)
                        .padding(.vertical, 10)
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

private struct HomeEmptyRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            FlowMindIconTile(systemImage: icon, size: 42)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
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
