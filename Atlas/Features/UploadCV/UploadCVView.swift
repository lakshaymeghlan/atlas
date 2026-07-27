import SwiftUI

// Placeholder — real UI (drop zone, file importer, validation) in Step 7.
struct UploadCVView: View {
    var onContinue: (PickedCV) -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: Space.block) {
            Eyebrow("UPLOAD CV · 2 OF 3")
            Text("Upload CV (stub)").atlasText(.title)
            AtlasButton("Continue →") {
                onContinue(PickedCV(filename: "sample.pdf", byteSize: 1024, data: Data()))
            }
            AtlasButton("Back", kind: .secondary, action: onBack)
        }
        .padding(Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
    }
}
