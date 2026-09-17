import SwiftUI

enum AppTab: Hashable {
    case home
    case inbox
    case flows
    case mind
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct RootView: View {
    @AppStorage("appAppearance") private var appAppearanceRawValue = AppAppearance.system.rawValue
    @State private var education = UserEducationState()
    @State private var selectedTab: AppTab = .home

    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .system
    }

    var body: some View {
        Group {
            if education.hasCompletedOnboarding {
                MainTabView(selection: $selectedTab)
            } else {
                OnboardingView {
                    education.completeOnboarding()
                }
            }
        }
        .environment(education)
        .tint(.flowMindAccent)
        .preferredColorScheme(appAppearance.colorScheme)
    }
}

struct MainTabView: View {
    @Binding private var selection: AppTab

    init(selection: Binding<AppTab>) {
        _selection = selection
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)

            NavigationStack { InboxView() }
                .tabItem { Label("Inbox", systemImage: "tray") }
                .tag(AppTab.inbox)

            NavigationStack { FlowsView() }
                .tabItem { Label("Flows", systemImage: "bolt") }
                .tag(AppTab.flows)

            NavigationStack { MindView() }
                .tabItem { Label("Mind", systemImage: "lightbulb") }
                .tag(AppTab.mind)
        }
    }
}
