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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appAppearance") private var appAppearanceRawValue = AppAppearance.system.rawValue
    @State private var selectedTab: AppTab = .home

    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .system
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(selection: $selectedTab)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
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

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages = [
        OnboardingPage(icon: "sparkles", title: "Your iPhone learns the work you repeat.", detail: "FLOWMIND turns the things you intentionally share into simple, reusable Flows."),
        OnboardingPage(icon: "square.and.arrow.down", title: "Share anything.", detail: "Screenshots, documents, links, and text all land in one calm Smart Inbox."),
        OnboardingPage(icon: "wand.and.stars", title: "Teach it once.", detail: "Choose the actions that matter and FLOWMIND remembers the pattern you approved."),
        OnboardingPage(icon: "checkmark.circle", title: "You stay in control.", detail: "FLOWMIND only processes what you send to it. Nothing runs without your approval.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("FLOWMIND")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .tracking(1.2)
                Spacer()
                Text("\(page + 1) / \(pages.count)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 28) {
                        Spacer()
                        Image(systemName: page.icon)
                            .font(.system(size: 62, weight: .medium))
                            .foregroundStyle(Color.flowMindAccent)
                            .accessibilityHidden(true)
                        VStack(spacing: 14) {
                            Text(page.title)
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .multilineTextAlignment(.center)
                            Text(page.detail)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(pages) { pageItem in
                    let index = pages.firstIndex(where: { $0.id == pageItem.id }) ?? 0
                    Capsule()
                        .fill(index == page ? Color.flowMindAccent : Color.secondary.opacity(0.22))
                        .frame(width: index == page ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: page)
                }
            }
            .accessibilityHidden(true)

            Button {
                if page == pages.count - 1 {
                    onFinish()
                } else {
                    withAnimation { page += 1 }
                }
            } label: {
                Label(page == pages.count - 1 ? "Get Started" : "Continue", systemImage: page == pages.count - 1 ? "arrow.right" : "chevron.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(24)
        }
        .background(Color.flowMindBackground.ignoresSafeArea())
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}
