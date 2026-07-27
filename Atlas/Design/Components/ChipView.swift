import SwiftUI

/// A skill/language chip. Unselected is `chip` fill / ink; selected (and the
/// "+N more" overflow chip) is `blueTint` fill / blue.
struct ChipView: View {
    let text: String
    var selected: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(selected ? Palette.blue : Palette.ink)
            .padding(.horizontal, Space.m)
            .padding(.vertical, Space.s)
            .background(selected ? Palette.blueTint : Palette.chip)
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
    .background(Palette.paper)
}
