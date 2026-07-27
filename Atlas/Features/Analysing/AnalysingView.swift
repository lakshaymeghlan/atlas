import SwiftUI

// Placeholder — real river + parser wiring in Step 9.
struct AnalysingView: View {
    let cv: PickedCV
    var onFinished: () -> Void
    var onRetry: () -> Void
    var onManualEntry: () -> Void

    var body: some View {
        VStack(spacing: Space.block) {
            Text("Analysing (stub)").atlasText(.title)
            AtlasButton("Finish →", action: onFinished)
            AtlasButton("Try another file", kind: .secondary, action: onRetry)
            AtlasButton("Enter manually", kind: .secondary, action: onManualEntry)
        }
        .padding(Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
    }
}
