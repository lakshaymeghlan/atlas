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
        configuration.label
            .foregroundStyle(kind == .primary ? Color.white : Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, Space.l)
            .background(background(pressed: pressed))
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
                    .stroke(Palette.border, lineWidth: kind == .secondary ? 1 : 0)
            )
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: Motion.tap), value: pressed)
    }

    private func background(pressed: Bool) -> Color {
        switch kind {
        case .primary:   return pressed ? Palette.bluePressed : Palette.blue
        case .secondary: return pressed ? Palette.chip : Palette.card
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
