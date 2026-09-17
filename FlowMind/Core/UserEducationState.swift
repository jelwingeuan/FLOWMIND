import Foundation
import Observation

@MainActor
@Observable
final class UserEducationState {
    private enum Key {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasAddedFirstItem = "hasAddedFirstItem"
        static let hasDismissedFirstItemGuidance = "hasDismissedFirstItemGuidance"
        static let hasCreatedFirstFlow = "hasCreatedFirstFlow"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var hasCompletedOnboarding: Bool { didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) } }
    var hasAddedFirstItem: Bool { didSet { defaults.set(hasAddedFirstItem, forKey: Key.hasAddedFirstItem) } }
    var hasDismissedFirstItemGuidance: Bool { didSet { defaults.set(hasDismissedFirstItemGuidance, forKey: Key.hasDismissedFirstItemGuidance) } }
    var hasCreatedFirstFlow: Bool { didSet { defaults.set(hasCreatedFirstFlow, forKey: Key.hasCreatedFirstFlow) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
        hasAddedFirstItem = defaults.bool(forKey: Key.hasAddedFirstItem)
        hasDismissedFirstItemGuidance = defaults.bool(forKey: Key.hasDismissedFirstItemGuidance)
        hasCreatedFirstFlow = defaults.bool(forKey: Key.hasCreatedFirstFlow)
    }

    var shouldShowFirstItemGuidance: Bool {
        hasAddedFirstItem && !hasDismissedFirstItemGuidance && !hasCreatedFirstFlow
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func replayOnboarding() {
        hasCompletedOnboarding = false
    }

    func markFirstItemAdded() {
        hasAddedFirstItem = true
    }

    func dismissFirstItemGuidance() {
        hasDismissedFirstItemGuidance = true
    }

    func markFirstFlowCreated() {
        hasCreatedFirstFlow = true
        hasDismissedFirstItemGuidance = true
    }
}
