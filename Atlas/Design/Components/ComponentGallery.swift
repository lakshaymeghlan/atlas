import SwiftUI

/// Dev-only gallery of the design components on paper. Not part of the app
/// flow — open it via the Xcode preview canvas.
struct ComponentGallery: View {
    @State private var selectedChip = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.block) {
                Eyebrow("ATLAS")

                Text("Component\ngallery")
                    .atlasText(.displayLarge)
                    .fixedSize(horizontal: false, vertical: true)

                section("Type") {
                    Text("Display 34").atlasText(.display)
                    Text("Title 20").atlasText(.title)
                    Text("Body 15 — the quick brown fox jumps.").atlasText(.body)
                        .foregroundStyle(Color.canopy600)
                    Eyebrow("META · SF MONO")
                }

                section("Chips") {
                    HStack {
                        ChipView(text: "Swift")
                        ChipView(text: "Product design")
                        ChipView(text: "+4 more", selected: true)
                    }
                }

                section("Cards") {
                    AtlasCard {
                        VStack(alignment: .leading, spacing: Space.s) {
                            Eyebrow("EXPERIENCE")
                            Text("Senior Engineer").atlasText(.bodyStrong)
                            Text("Acme · 2021 — Present").atlasText(.caption)
                                .foregroundStyle(Color.canopy400)
                        }
                    }
                }

                section("Buttons") {
                    AtlasButton("Looks good") {}
                    AtlasButton("Continue →", isEnabled: false) {}
                    AtlasButton(title: "Continue with GitHub", kind: .secondary,
                                leading: { ProviderMark(.github) }) {}
                    AtlasButton(title: "Continue with LinkedIn", kind: .secondary,
                                leading: { ProviderMark(.linkedIn) }) {}
                }
            }
            .padding(Space.screen)
        }
        .background(Color.canopyPaper)
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            Eyebrow(title, color: Color.canopy400)
            content()
        }
    }
}

#Preview {
    ComponentGallery()
}
