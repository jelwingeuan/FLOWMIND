# FLOWMIND

FLOWMIND is a privacy-first, local-first iPhone app for turning intentionally shared content into reusable Flows.

## Current foundation

- SwiftUI tab navigation for Home, Inbox, Flows, and Mind
- Four-page onboarding focused on explicit sharing and user control
- SwiftData models for inbox items, Flows, and Flow runs
- Development seed data provided by `FlowMindStore`, not embedded in views
- Inbox item detail with extracted fields and suggested actions
- Visual Flow cards, a natural-language Flow builder backed by `MockFlowGenerationService`, and local Flow execution
- Transparent threshold-based pattern suggestions in Mind
- Privacy-focused Settings with local data deletion
- Unit tests for pattern detection and mock Flow generation

## Structure

`App` owns app entry and root navigation. `Core` contains SwiftData records, domain values, the store, and service protocols. `Features` contains screen-level SwiftUI views. `Shared` contains semantic colors and reusable controls.

## Open and build

Open `FlowMind.xcodeproj` in Xcode 26.3 or newer. The deployment target is iOS 17. The current environment has Xcode command-line tools selected but no full Xcode app or simulator runtime available, so compilation must be completed in a full Xcode installation.

## Planned integrations

The next product phases can add a Share Extension with an App Group, App Intents and App Shortcuts, a server-backed `RemoteAIAnalysisService`, and richer Flow action executors. API keys must remain on a backend and never ship in the iOS target.

## Known limitations

The current app uses mock analysis and local demo data. The Share Extension, App Intents, real file/image importing, remote AI, calendar/reminder integrations, and cloud sync are architectural next steps rather than completed functionality.
