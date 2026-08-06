import SwiftUI
import UIKit

/// Provider brand marks for the sign-in buttons.
///
/// ponytail: LinkedIn is drawn accurately; GitHub is a hand-approximated octocat
/// silhouette (no Apple-provided glyph exists). Drop real brand SVG/PDF assets in
/// here for a pixel-exact logo — this is the one file to change.
enum BrandMark {
    case linkedIn, github
}

struct BrandMarkView: View {
    let mark: BrandMark
    var size: CGFloat = 26
    /// Fill for the monochrome (GitHub) mark — ink so it flips on dark.
    var monoColor: Color = .black

    /// Asset name checked first — drop a real logo image set here for a
    /// pixel-exact mark; otherwise the drawn fallback is used.
    private var assetName: String { mark == .linkedIn ? "logo-linkedin" : "logo-github" }

    var body: some View {
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            drawn
        }
    }

    @ViewBuilder private var drawn: some View {
        switch mark {
        case .linkedIn:
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(Color(hex: "0A66C2"))
                .frame(width: size, height: size)
                .overlay(
                    Text("in")
                        .font(.system(size: size * 0.58, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(y: size * 0.02)
                )
        case .github:
            Canvas { ctx, s in
                ctx.fill(Self.octocat(in: s), with: .color(monoColor))
            }
            .frame(width: size, height: size)
        }
    }

    /// Clean GitHub octocat silhouette (approximate): a rounded head/body with
    /// two ears. Filled, normalised to `size`.
    private static func octocat(in size: CGSize) -> Path {
        let s = min(size.width, size.height)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        var path = Path()
        // Head + body as one soft rounded silhouette.
        path.addRoundedRect(in: CGRect(x: 0.13 * s, y: 0.24 * s, width: 0.74 * s, height: 0.66 * s),
                            cornerSize: CGSize(width: 0.32 * s, height: 0.30 * s))
        // Ears, rooted cleanly on the head.
        path.move(to: p(0.30, 0.30)); path.addLine(to: p(0.28, 0.07)); path.addLine(to: p(0.48, 0.26)); path.closeSubpath()
        path.move(to: p(0.70, 0.30)); path.addLine(to: p(0.72, 0.07)); path.addLine(to: p(0.52, 0.26)); path.closeSubpath()
        return path
    }
}

#Preview {
    HStack(spacing: 24) {
        BrandMarkView(mark: .linkedIn)
        BrandMarkView(mark: .github)
    }
    .padding()
    .background(Color.canopyPaper)
}
