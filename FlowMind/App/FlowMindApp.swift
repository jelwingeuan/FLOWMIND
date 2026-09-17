import SwiftData
import SwiftUI

@main
struct FlowMindApp: App {
    private let modelContainer: ModelContainer
    @State private var store: FlowMindStore

    init() {
        do {
            modelContainer = try ModelContainer(
                for: InboxItemRecord.self,
                FlowRecord.self,
                FlowRunRecord.self
            )
        } catch {
            fatalError("FLOWMIND could not create its local data store: \(error)")
        }

        _store = State(initialValue: FlowMindStore(modelContext: modelContainer.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .modelContainer(modelContainer)
        }
    }
}
