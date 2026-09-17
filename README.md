# FLOWMIND

FLOWMIND is a privacy-first, local-first iPhone app for turning intentionally shared content into reusable Flows.

## Current foundation

- SwiftUI tab navigation for Home, Inbox, Flows, and Mind
- Four-page onboarding focused on explicit sharing and user control
- SwiftData models for inbox items, Flows, and Flow runs
- Empty-by-default local storage, with notes saved only from user-entered text
- Inbox item detail with extracted fields and suggested actions
- Visual Flow cards, a natural-language Flow builder backed by `MockFlowGenerationService`, and local Flow execution
- Transparent threshold-based pattern suggestions in Mind
- Privacy-focused Settings with local data deletion
- Unit tests for empty launches, persistence, user content preservation, capture, Flow creation, pattern detection, and mock Flow generation

## Structure

`App` owns app entry and root navigation. `Core` contains SwiftData records, domain values, the store, and service protocols. `Features` contains screen-level SwiftUI views. `Shared` contains semantic colors and reusable controls.

## Open and build

Open `FlowMind.xcodeproj` in Xcode 26.3 or newer. The deployment target is iOS 17. The shared `FlowMind` scheme includes the unit tests. Select an installed iPhone simulator and run Product > Test, or:

```sh
xcodebuild -project FlowMind.xcodeproj -scheme FlowMind -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Empty-state screenshots for Home (including history), Inbox, Flows, and Mind are attached to `testEmptyScreenRenderings` in the test results, in both appearances.

## Runtime data

Normal launch only loads existing SwiftData records. It never inserts sample Inbox items, Flows, history, or pattern suggestions, including after Delete All Data. Patterns depend on saved user content. Test fixtures use isolated in-memory or temporary stores; no preview fixtures are loaded by the app.

Older builds used `FlowMindStore.seedDemoData()` to insert five Inbox items, four Flows, and three runs. Those records had random IDs and no per-record demo marker; `hasSeededFlowMindDemoData` only indicates that seeding was attempted. Do not infer ownership from titles, categories, or `creationSource`, and do not reset an existing installation automatically.

For an older development installation, back up the store, inspect its insertion history against the old seeding code, and remove only the exact IDs proven to belong to the seed transaction. Preserve later user-created records, even when they were created from sample inputs. Where provenance is missing or ambiguous, retain the records until their owner explicitly approves deletion. The app deliberately performs no heuristic cleanup migration.

## Planned integrations

The next product phases can add a Share Extension with an App Group, App Intents and App Shortcuts, a server-backed `RemoteAIAnalysisService`, and richer Flow action executors. API keys must remain on a backend and never ship in the iOS target.

## Known limitations

The current app uses mock analysis and an on-demand mock Flow generator. These services do not populate the app at launch. The Share Extension, App Intents, real file/image importing, remote AI, calendar/reminder integrations, and cloud sync are architectural next steps rather than completed functionality.
