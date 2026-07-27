import SwiftUI

/// 20pt monochrome provider marks for the sign-in buttons. Neither provider
/// gets a coloured button — the mark is ink on the card fill.
///
/// ponytail: monogram stand-ins, not the licensed brand glyphs. Drop real
/// LinkedIn/GitHub SVG assets in before public release.
struct ProviderMark: View {
    enum Provider { case linkedIn, github }
    let provider: Provider

    init(_ provider: Provider) { self.provider = provider }

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Palette.ink)
            .frame(width: 20, height: 20)
            .overlay(glyph)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var glyph: some View {
        switch provider {
        case .linkedIn:
            Text("in")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white)
        case .github:
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    HStack(spacing: Space.m) {
        ProviderMark(.linkedIn)
        ProviderMark(.github)
    }
    .padding()
    .background(Palette.paper)
}
