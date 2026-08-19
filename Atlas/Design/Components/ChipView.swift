import SwiftUI

/// A skill/language chip on a mist fill. `selected` (and the "+N more" overflow
/// chip) reads in canopy rather than ink.
struct ChipView: View {
    let text: String
    var selected: Bool = false
    /// Low-confidence chips get a leading 6pt blue dot (no percentage shown).
    var lowConfidence: Bool = false

    var body: some View {
        HStack(spacing: Space.xs) {
            if lowConfidence {
                Circle().fill(Color.canopy600).frame(width: 6, height: 6)
            }
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(selected ? Color.canopy600 : Color.canopy900)
        }
        .padding(.horizontal, Space.m)
        .padding(.vertical, Space.s)
        .background(Color.canopyMist)
        .clipShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
    }
}

#Preview {
    HStack {
        ChipView(text: "Swift")
        ChipView(text: "SwiftUI")
        ChipView(text: "+4 more", selected: true)
    }
    .padding(Space.screen)
    .frame(maxWidth: .infinity)
    .background(Color.canopyPaper)
}
