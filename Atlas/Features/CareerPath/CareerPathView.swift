import SwiftUI

// Placeholder — real UI in Step 7.
struct CareerPathView: View {
    var onChooseSeeking: () -> Void

    var body: some View {
        VStack(spacing: Space.block) {
            Eyebrow("CAREER PATH · 1 OF 3")
            Text("Career path (stub)").atlasText(.title)
            AtlasButton("Find my next role →", action: onChooseSeeking)
        }
        .padding(Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
    }
}
