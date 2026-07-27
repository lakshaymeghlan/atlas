import SwiftUI

/// Bare 20pt monochrome provider marks for the sign-in buttons — ink, no
/// container. Neither provider gets a coloured box.
///
/// ponytail: monogram stand-ins, not the licensed brand glyphs. Drop real
/// LinkedIn/GitHub SVG assets in before public release.
struct ProviderMark: View {
    enum Provider { case linkedIn, github }
    let provider: Provider

    init(_ provider: Provider) { self.provider = provider }

    var body: some View {
        glyph
            .foregroundStyle(Palette.ink)
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var glyph: some View {
        switch provider {
        case .linkedIn:
            Text("in").font(.system(size: 17, weight: .heavy))
        case .github:
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

#Preview {
    HStack(spacing: Space.l) {
        ProviderMark(.linkedIn)
        ProviderMark(.github)
    }
    .padding()
    .background(Palette.paper)
}
