import SwiftUI

extension Color {
    static let flowMindAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.43, green: 0.78, blue: 0.81, alpha: 1)
            : UIColor(red: 0.08, green: 0.34, blue: 0.39, alpha: 1)
    })
    static let flowMindAccentFill = Color(red: 0.08, green: 0.34, blue: 0.39)
    static let flowMindAccentSoft = Color(red: 0.80, green: 0.91, blue: 0.89)
    static let flowMindHighlight = Color(red: 0.93, green: 0.51, blue: 0.20)
    static let flowMindPrimaryBackground = Color(uiColor: .systemBackground)
    static let flowMindBackground = Color(uiColor: .systemGroupedBackground)
    static let flowMindCardBackground = Color(uiColor: .secondarySystemBackground)
    static let flowMindSurface = flowMindCardBackground
    static let flowMindPrimaryText = Color(uiColor: .label)
    static let flowMindSecondaryText = Color(uiColor: .secondaryLabel)
    static let flowMindTertiaryText = Color(uiColor: .tertiaryLabel)
    static let flowMindInk = flowMindPrimaryText
    static let flowMindCardBorder = Color(uiColor: .separator).opacity(0.45)
    static let flowMindAccentForeground = Color.white
    static let flowMindSuccess = Color(uiColor: .systemGreen)
    static let flowMindWarning = Color(uiColor: .systemOrange)
    static let flowMindError = Color(uiColor: .systemRed)
}

struct FlowMindCard<Content: View>: View {
    let content: Content
    private let padding: CGFloat
    private let fill: Color
    private let border: Color
    private let hasBorder: Bool

    init(
        padding: CGFloat = 18,
        fill: Color = .flowMindSurface,
        border: Color = .flowMindCardBorder,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.fill = fill
        self.border = border
        self.hasBorder = border != .clear
    }

    var body: some View {
        content
            .padding(padding)
            .background(fill)
            .clipShape(.rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(border, lineWidth: hasBorder ? 1 : 0)
            }
    }
}

struct FlowMindGlassCard<Content: View>: View {
    let content: Content
    private let padding: CGFloat
    private let tint: Color?
    private let cornerRadius: CGFloat
    private let fallbackFill: Color
    private let fallbackBorder: Color

    init(
        padding: CGFloat = 18,
        tint: Color? = nil,
        cornerRadius: CGFloat = 18,
        fallbackFill: Color = .flowMindSurface,
        fallbackBorder: Color = .flowMindCardBorder,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.fallbackFill = fallbackFill
        self.fallbackBorder = fallbackBorder
    }

    var body: some View {
        content
            .padding(padding)
            .flowMindGlassSurface(
                tint: tint,
                cornerRadius: cornerRadius,
                fallbackFill: fallbackFill,
                fallbackBorder: fallbackBorder
            )
    }
}

extension View {
    @ViewBuilder
    func flowMindGlassSurface(
        tint: Color? = nil,
        interactive: Bool = false,
        cornerRadius: CGFloat = 18,
        fallbackFill: Color = .flowMindSurface,
        fallbackBorder: Color = .flowMindCardBorder
    ) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                if interactive {
                    self.glassEffect(.regular.tint(tint).interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
                } else {
                    self.glassEffect(.regular.tint(tint), in: RoundedRectangle(cornerRadius: cornerRadius))
                }
            } else if interactive {
                self.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
            }
        } else {
            self
                .background(fallbackFill)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(fallbackBorder, lineWidth: 1)
                }
        }
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
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.flowMindAccent)
            }
        }
    }
}

struct StatusBadge: View {
    let title: String
    let color: Color
    let systemImage: String?

    init(title: String, color: Color, systemImage: String? = nil) {
        self.title = title
        self.color = color
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
            } else {
                Circle().fill(color).frame(width: 7, height: 7)
            }
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
            .foregroundStyle(Color.flowMindAccentForeground)
            .frame(minHeight: 52)
            .padding(.horizontal, 18)
            .background(Color.flowMindAccentFill.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(.rect(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.flowMindAccent)
            .frame(minHeight: 48)
            .padding(.horizontal, 16)
            .flowMindGlassSurface(
                tint: Color.flowMindAccent,
                interactive: true,
                cornerRadius: 15,
                fallbackFill: Color.flowMindAccent.opacity(configuration.isPressed ? 0.16 : 0.09),
                fallbackBorder: .clear
            )
    }
}

struct PrimaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.flowMindAccent)
            .frame(minHeight: 52)
            .padding(.horizontal, 18)
            .flowMindGlassSurface(
                tint: Color.flowMindAccent,
                interactive: true,
                cornerRadius: 16,
                fallbackFill: Color.flowMindAccentFill.opacity(configuration.isPressed ? 0.78 : 1),
                fallbackBorder: .clear
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct LightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.flowMindAccentFill)
            .frame(minHeight: 46)
            .padding(.horizontal, 15)
            .flowMindGlassSurface(
                tint: Color.white.opacity(0.65),
                interactive: true,
                cornerRadius: 14,
                fallbackFill: Color.flowMindAccentForeground.opacity(configuration.isPressed ? 0.78 : 1),
                fallbackBorder: .clear
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct FlowMindStat: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12))
                .clipShape(.rect(cornerRadius: 9))
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct FlowMindIconTile: View {
    let systemImage: String
    let tint: Color
    let size: CGFloat

    init(systemImage: String, tint: Color = .flowMindAccent, size: CGFloat = 44) {
        self.systemImage = systemImage
        self.tint = tint
        self.size = size
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.12))
            .clipShape(.rect(cornerRadius: size * 0.28))
    }
}

extension Date {
    @MainActor
    var flowMindRelative: String {
        FlowMindFormatters.relativeDate.localizedString(for: self, relativeTo: Date())
    }
}

@MainActor
private enum FlowMindFormatters {
    static let relativeDate = RelativeDateTimeFormatter()
}
