import SwiftUI

enum AtlasButtonKind { case primary, secondary }

/// The two button shapes in Atlas. Primary is the only filled (blue) button in
/// the app; secondary is card-fill with a hairline border. Both share geometry:
/// full width, 56pt min height, 16pt radius.
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
        let label = configuration.label
            .foregroundStyle(kind == .primary ? Color.white : Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, Space.l)

        return glass(label, pressed: pressed)
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(pressed ? 0.985 : 1)
            .animation(.easeOut(duration: Motion.tap), value: pressed)
    }

    @ViewBuilder private func glass(_ label: some View, pressed: Bool) -> some View {
        switch kind {
        case .primary:
            label.tintedGlass(Radius.button, fill: pressed ? Palette.bluePressed : Palette.blue)
        case .secondary:
            label.glassSurface(Radius.button, tint: pressed ? Palette.chip.opacity(0.7) : .white.opacity(0.4))
        }
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
    .background(Palette.paper)
}
