import SwiftUI

struct SettingsView: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Form {
            Section {
                Label("FLOWMIND only processes things you intentionally send to it.", systemImage: "hand.raised")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Privacy")
            }
            Section("Processing") {
                LabeledContent("AI Processing", value: "Mock mode")
                LabeledContent("Local Data", value: "On device")
            }
            Section {
                Button("Delete All Data", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            } footer: {
                Text("This removes local inbox items, Flows, and run history from this device.")
            }
            Section("About") {
                LabeledContent("Version", value: "V1 foundation")
                LabeledContent("Backend", value: "Not connected")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .confirmationDialog("Delete all local data?", isPresented: $showingDeleteConfirmation) {
            Button("Delete Everything", role: .destructive) {
                store.deleteAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
