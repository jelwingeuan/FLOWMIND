import SwiftUI

extension Color {
    static let flowMindAccent = Color(red: 0.36, green: 0.37, blue: 0.94)
    static let flowMindBackground = Color(uiColor: .systemGroupedBackground)
    static let flowMindSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let flowMindInk = Color(uiColor: .label)
    static let flowMindSuccess = Color(red: 0.18, green: 0.58, blue: 0.39)
    static let flowMindWarning = Color(red: 0.77, green: 0.48, blue: 0.14)
}

struct FlowMindCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(Color.flowMindSurface)
            .clipShape(.rect(cornerRadius: 20))
    }
}

struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(.secondary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.footnote.weight(.semibold))
            }
        }
    }
}

struct StatusBadge: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(color.opacity(0.11))
        .clipShape(Capsule())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
            .background(Color.flowMindAccent.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(.rect(cornerRadius: 15))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.flowMindAccent)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(Color.flowMindAccent.opacity(configuration.isPressed ? 0.16 : 0.09))
            .clipShape(.rect(cornerRadius: 14))
    }
}

extension Date {
    var flowMindRelative: String {
        RelativeDateTimeFormatter().localizedString(for: self, relativeTo: Date())
    }
}
