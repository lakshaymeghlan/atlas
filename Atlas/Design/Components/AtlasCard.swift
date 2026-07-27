import SwiftUI

/// White card: 20pt radius, 1px border, the one approved shadow. Everything on
/// the confirm and career screens sits in one of these.
struct AtlasCard<Content: View>: View {
    var padding: CGFloat = Space.screen
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassSurface(Radius.card, tint: .white.opacity(0.55))
    }
}

#Preview {
    VStack(spacing: Space.l) {
        AtlasCard {
            VStack(alignment: .leading, spacing: Space.s) {
                Eyebrow("EDUCATION")
                Text("A card").atlasText(.title)
                Text("With some body copy inside it.").atlasText(.body)
                    .foregroundStyle(Palette.inkSecondary)
            }
        }
    }
    .padding(Space.screen)
    .frame(maxHeight: .infinity)
    .background(Palette.paper)
}
