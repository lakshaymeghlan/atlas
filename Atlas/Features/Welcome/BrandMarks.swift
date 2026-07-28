import SwiftUI

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

    var body: some View {
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

    /// Approximate GitHub octocat silhouette, filled, normalised to `size`.
    private static func octocat(in size: CGSize) -> Path {
        let s = min(size.width, size.height)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        var path = Path()
        // Head
        path.addEllipse(in: CGRect(x: 0.10 * s, y: 0.22 * s, width: 0.80 * s, height: 0.60 * s))
        // Ears
        path.move(to: p(0.26, 0.30)); path.addLine(to: p(0.24, 0.06)); path.addLine(to: p(0.46, 0.24)); path.closeSubpath()
        path.move(to: p(0.74, 0.30)); path.addLine(to: p(0.76, 0.06)); path.addLine(to: p(0.54, 0.24)); path.closeSubpath()
        // Body
        path.addEllipse(in: CGRect(x: 0.20 * s, y: 0.56 * s, width: 0.60 * s, height: 0.40 * s))
        // Little arm curl (lower left)
        path.addEllipse(in: CGRect(x: 0.10 * s, y: 0.68 * s, width: 0.16 * s, height: 0.16 * s))
        return path
    }
}

#Preview {
    HStack(spacing: 24) {
        BrandMarkView(mark: .linkedIn)
        BrandMarkView(mark: .github)
    }
    .padding()
    .background(Color(hex: "FCFBF8"))
}
