import SwiftUI

// Placeholder — full stub content in Step 11.
struct HomeView: View {
    var onSignOut: () -> Void

    var body: some View {
        VStack(spacing: Space.block) {
            Eyebrow("ATLAS")
            Text("Home (stub)").atlasText(.title)
            AtlasButton("Sign out", kind: .secondary, action: onSignOut)
        }
        .padding(Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
    }
}
