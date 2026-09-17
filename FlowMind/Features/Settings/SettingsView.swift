import SwiftUI

struct SettingsView: View {
    @Environment(FlowMindStore.self) private var store
    @Environment(UserEducationState.self) private var education
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appAppearance") private var appAppearanceRawValue = AppAppearance.system.rawValue
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Form {
            Section {
                Label("FLOWMIND only processes things you intentionally send to it.", systemImage: "hand.raised")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Privacy")
            }
            Section("Appearance") {
                Picker("Appearance", selection: $appAppearanceRawValue) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Label(appearance.displayName, systemImage: appearance.systemImage)
                            .tag(appearance.rawValue)
                    }
                }
                .pickerStyle(.navigationLink)
            }
            Section("Processing") {
                LabeledContent("AI Processing", value: "Mock mode")
                LabeledContent("Local Data", value: "On device")
            }
            Section("Help & About") {
                NavigationLink("Getting Started") {
                    GettingStartedView()
                }
                Button("Replay Onboarding", systemImage: "arrow.counterclockwise") {
                    education.replayOnboarding()
                    dismiss()
                }
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
