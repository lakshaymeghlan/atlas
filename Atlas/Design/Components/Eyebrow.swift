import SwiftUI

/// A meta label: uppercase SF Mono with wide tracking. Used for the top-left
/// wordmark, stage counters ("CAREER PATH · 1 OF 3") and card section headers.
struct Eyebrow: View {
    let text: String
    var color: Color = Palette.inkSecondary

    init(_ text: String, color: Color = Palette.inkSecondary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .atlasText(.meta)
            .foregroundStyle(color)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Space.m) {
        Eyebrow("ATLAS")
        Eyebrow("CAREER PATH · 1 OF 3")
        Eyebrow("READING YOUR CV", color: Palette.blue)
    }
    .padding(Space.screen)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Palette.paper)
}
