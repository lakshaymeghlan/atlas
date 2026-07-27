import SwiftUI

// Placeholder — real section cards + edit sheets in Step 10.
struct ConfirmProfileView: View {
    var onDone: () -> Void

    @Environment(ProfileStore.self) private var store

    var body: some View {
        VStack(spacing: Space.block) {
            Eyebrow("CONFIRM PROFILE · 3 OF 3")
            Text("Confirm profile (stub)").atlasText(.title)
            Text("\(store.profile.experiences.count) roles, \(store.profile.skills.count) skills")
                .atlasText(.body)
            AtlasButton("Looks good", action: onDone)
        }
        .padding(Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
    }
}
