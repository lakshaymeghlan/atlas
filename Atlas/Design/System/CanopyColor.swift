import SwiftUI

/// The one and only place a Canopy colour is referenced. Values are defined once
/// as asset-catalog colour sets under `Assets.xcassets/Canopy/`; this extension
/// is the single Swift surface for them. Views use `Color.canopy800`, never a
/// literal, never `Color("…")` inline.
///
/// Palette thesis — cool paper, canopy greens, and `sun` as light through
/// leaves. `sun` is scarce by rule: an active/complete node, a progress fill, a
/// match-strength indicator, or the light shaft. Never a button, link, or fill.
extension Color {
    // Paper — page, wells, hairlines
    static let canopyPaper = Color("canopyPaper")
    static let canopyPaperDeep = Color("canopyPaperDeep")
    static let canopyPaperLine = Color("canopyPaperLine")

    // Canopy — mist through to deep shade
    static let canopyMist = Color("canopyMist")
    static let canopy200 = Color("canopy200")
    static let canopy400 = Color("canopy400")
    static let canopy600 = Color("canopy600")
    static let canopy800 = Color("canopy800")
    static let canopy900 = Color("canopy900")

    // Sun — light, not brand. Use sparingly (see thesis).
    static let sunWash = Color("sunWash")
    static let sun = Color("sun")
    static let sunDeep = Color("sunDeep")
}
