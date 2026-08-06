import SwiftUI

enum AtlasButtonKind { case primary, secondary }

/// The two button shapes in Atlas. Primary is a solid ink fill; secondary is
/// white with a hairline border (the same family as the sign-in buttons). Both
/// share geometry: full width, 56pt min height, 16pt radius.
struct AtlasButton<Leading: View>: View {
    let title: String
    var kind: AtlasButtonKind = .primary
    var isEnabled: Bool = true
    @ViewBuilder var leading: Leading
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                leading
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .buttonStyle(AtlasButtonStyle(kind: kind, isEnabled: isEnabled))
        .disabled(!isEnabled)
    }
}

// Convenience for the common no-icon case.
extension AtlasButton where Leading == EmptyView {
    init(_ title: String, kind: AtlasButtonKind = .primary, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.init(title: title, kind: kind, isEnabled: isEnabled, leading: { EmptyView() }, action: action)
    }
}

private struct AtlasButtonStyle: ButtonStyle {
    let kind: AtlasButtonKind
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
        return configuration.label
            .foregroundStyle(labelColor)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, Space.l)
            .background(shape.fill(fill(pressed: pressed)))
            .overlay(kind == .secondary ? shape.strokeBorder(Color.canopyPaperLine, lineWidth: 1) : nil)
            .clipShape(shape)
            .shadow(color: shadowColor, radius: pressed ? 5 : 13, x: 0, y: pressed ? 2 : 6)
            .scaleEffect(pressed ? 0.985 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: pressed)
    }

    // Primary = solid canopy shade; secondary = paper with a hairline.
    private var labelColor: Color {
        guard isEnabled else { return Color.canopy400 }
        return kind == .primary ? .canopyPaper : Color.canopy900
    }

    private func fill(pressed: Bool) -> Color {
        switch kind {
        case .primary:
            if !isEnabled { return Color.canopyPaperLine }
            return pressed ? Color.canopy900 : Color.canopy800
        case .secondary:
            return pressed ? Color.canopyMist : .canopyPaper
        }
    }

    private var shadowColor: Color {
        guard isEnabled else { return .clear }
        return kind == .primary ? Color.canopy900.opacity(0.18) : .canopy900.opacity(0.05)
    }
}

#Preview {
    VStack(spacing: Space.m) {
        AtlasButton("Looks good") {}
        AtlasButton("Continue →", isEnabled: false) {}
        AtlasButton(title: "Continue with GitHub", kind: .secondary,
                    leading: { ProviderMark(.github) }) {}
        AtlasButton(title: "Continue with LinkedIn", kind: .secondary,
                    leading: { ProviderMark(.linkedIn) }) {}
    }
    .padding(Space.screen)
    .frame(maxHeight: .infinity)
    .background(Color.canopyPaper)
}
