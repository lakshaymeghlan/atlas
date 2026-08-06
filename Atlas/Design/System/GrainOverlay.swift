import SwiftUI
import UIKit

/// Paper grain. SwiftUI has no `feTurbulence`, so we render a small monochrome
/// noise tile *once*, cache it, and tile it across the screen at 3% under a
/// multiply blend. Without it this palette reads as an unfinished wireframe;
/// with it, it registers as paper. Deterministic seed → identical every launch.
enum Grain {
    static let tile: UIImage = makeTile(side: 128)

    private static func makeTile(side: Int) -> UIImage {
        var rng = SeededRNG(seed: 0x0E241B)      // canopy900, for luck
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { ctx in
            for y in 0..<side {
                for x in 0..<side {
                    // Sparse speckle: most pixels clear, a few faint grey specks.
                    let r = rng.next()
                    guard r & 0x7 == 0 else { continue }              // ~1 in 8 pixels
                    let grey = CGFloat(30 + Int(r % 60)) / 255        // dark-ish fleck
                    ctx.cgContext.setFillColor(UIColor(white: grey, alpha: 1).cgColor)
                    ctx.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
    }
}

/// A tiny deterministic PRNG (SplitMix64) — no `Date`/`arc4random`, so the tile
/// is byte-identical every run.
private struct SeededRNG {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private struct GrainOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(
            Image(uiImage: Grain.tile)
                .resizable(resizingMode: .tile)
                .opacity(0.03)
                .blendMode(.multiply)
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .accessibilityHidden(true)
        )
    }
}

extension View {
    /// Overlay the paper grain (3%, multiply). Put it on the page background.
    func canopyGrain() -> some View { modifier(GrainOverlay()) }
}
