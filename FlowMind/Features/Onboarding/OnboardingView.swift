import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: OnboardingStep = .welcome
    @State private var showingGettingStarted = false
    @State private var completed = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("FLOWMIND")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.flowMindAccent)
                Spacer()
                if step != .ready {
                    Button("Skip") {
                        complete()
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            TabView(selection: $step) {
                ForEach(OnboardingStep.allCases) { step in
                    OnboardingPageView(step: step, reduceMotion: reduceMotion)
                        .tag(step)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityValue("Step \(step.rawValue + 1) of \(OnboardingStep.allCases.count)")

            OnboardingProgressIndicator(step: step)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            VStack(spacing: 10) {
                Button {
                    advance()
                } label: {
                    Label(step.primaryActionTitle, systemImage: step == .ready ? "arrow.right" : "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryGlassButtonStyle())

                if step == .ready {
                    Button("How it works") {
                        showingGettingStarted = true
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.flowMindBackground.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: completed)
        .sheet(isPresented: $showingGettingStarted) {
            NavigationStack { GettingStartedView() }
        }
    }

    private func advance() {
        guard step != .ready else {
            complete()
            return
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            step = OnboardingStep(rawValue: step.rawValue + 1) ?? .ready
        }
    }

    private func complete() {
        completed = true
        onFinish()
    }
}

private enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case capture
    case teach
    case flows
    case learning
    case privacy
    case ready

    var id: Int { rawValue }

    var primaryActionTitle: String {
        switch self {
        case .welcome: "Get Started"
        case .ready: "Open FLOWMIND"
        default: "Continue"
        }
    }
}

private struct OnboardingPageView: View {
    let step: OnboardingStep
    let reduceMotion: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 42)
                visual
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let supportingText {
                    Text(supportingText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                Spacer(minLength: 28)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, minHeight: 500)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var visual: some View {
        switch step {
        case .welcome:
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 82, weight: .medium))
                .foregroundStyle(Color.flowMindAccent)
                .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                .accessibilityHidden(true)
        case .capture:
            ContentTypeGrid()
        case .teach:
            LearningSequence(steps: ["Something arrives", "FLOWMIND understands it", "You choose actions", "Save as a Flow"])
        case .flows:
            FlowExampleDiagram()
        case .learning:
            LearningSequence(steps: ["Repeated action", "Pattern detected", "Suggested Flow", "You decide"])
        case .privacy:
            PrivacyPromise()
        case .ready:
            Image(systemName: "arrow.forward.circle.fill")
                .font(.system(size: 82, weight: .medium))
                .foregroundStyle(Color.flowMindAccent)
                .accessibilityHidden(true)
        }
    }

    private var title: String {
        switch step {
        case .welcome: "Your iPhone learns the work you repeat."
        case .capture: "Start with anything."
        case .teach: "Teach it once."
        case .flows: "Turn routines into Flows."
        case .learning: "It gets smarter with use."
        case .privacy: "You stay in control."
        case .ready: "Ready to build your first Flow?"
        }
    }

    private var detail: String {
        switch step {
        case .welcome: "Turn everyday actions into simple, reusable Flows."
        case .capture: "Share a photo, document, link, or text with FLOWMIND."
        case .teach: "Choose what you usually do with something, and FLOWMIND can turn those steps into a reusable Flow."
        case .flows: "Flows help you repeat useful actions without starting from scratch every time."
        case .learning: "As you use FLOWMIND, it can notice repeated actions and suggest new Flows."
        case .privacy: "FLOWMIND only works with content you choose to send to it. It does not monitor your other apps."
        case .ready: "Start by adding something to your Smart Inbox."
        }
    }

    private var supportingText: String? {
        switch step {
        case .capture: "FLOWMIND understands what you send and helps you decide what should happen next."
        case .learning: "Nothing is automated without your approval."
        case .privacy: "Suggested Flows require approval, and you can delete your local data from Settings."
        default: nil
        }
    }
}

private struct ContentTypeGrid: View {
    private let types = [("photo", "Image"), ("doc", "Document"), ("link", "Link"), ("text.alignleft", "Text")]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(types, id: \.1) { type in
                VStack(spacing: 8) {
                    Image(systemName: type.0)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.flowMindAccent)
                    Text(type.1)
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, minHeight: 92)
                .flowMindGlassSurface(cornerRadius: 14)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You can add images, documents, links, and text")
    }
}

private struct LearningSequence: View {
    let steps: [String]

    var body: some View {
        VStack(spacing: 7) {
            ForEach(steps, id: \.self) { step in
                Text(step)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .flowMindGlassSurface(cornerRadius: 12)
                if step != steps.last {
                    Image(systemName: "arrow.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.flowMindAccent)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FlowExampleDiagram: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowStepLine(label: "WHEN", value: "Something is shared", icon: "arrow.down")
            FlowStepLine(label: "IF", value: "It matches your rule", icon: "arrow.down")
            FlowStepLine(label: "DO", value: "Perform your actions", icon: nil)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .flowMindGlassSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Flow example: When something is shared, if it matches your rule, perform your actions")
    }
}

private struct PrivacyPromise: View {
    private let messages = [("hand.raised", "You choose what to send"), ("lock", "Your local data stays on this device"), ("checkmark.shield", "You approve every Flow")]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(messages, id: \.1) { message in
                Label(message.1, systemImage: message.0)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.flowMindPrimaryText)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .flowMindGlassSurface(cornerRadius: 16)
    }
}

private struct OnboardingProgressIndicator: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: 7) {
            ForEach(OnboardingStep.allCases) { item in
                Capsule()
                    .fill(item == step ? Color.flowMindAccent : Color.flowMindTertiaryText.opacity(0.35))
                    .frame(width: item == step ? 24 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.2), value: step)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Step \(step.rawValue + 1) of \(OnboardingStep.allCases.count)")
    }
}
