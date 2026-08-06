import SwiftUI

/// A GitHub-style contribution heatmap — 52 weeks × 7 days of little squares,
/// shaded by activity level, fit to the available width. Levels are generated
/// deterministically from a seed so the graph is stable across launches.
struct ContributionGraph: View {
    var seed: Int = 7
    private let weeks = 52
    private let days = 7

    // GitHub's green scale, with a warm empty cell so it sits on ivory.
    private let levelColors = [
        Color(hex: "EAE7E0"), Color(hex: "9BE9A8"),
        Color(hex: "40C463"), Color(hex: "30A14E"), Color(hex: "216E39"),
    ]

    var body: some View {
        Canvas { ctx, size in
            let gap: CGFloat = 2
            let sq = (size.width - gap * CGFloat(weeks - 1)) / CGFloat(weeks)
            let gridHeight = CGFloat(days) * sq + CGFloat(days - 1) * gap
            let yTop = max(0, (size.height - gridHeight) / 2)
            for w in 0..<weeks {
                for d in 0..<days {
                    let x = CGFloat(w) * (sq + gap)
                    let y = yTop + CGFloat(d) * (sq + gap)
                    let rect = CGRect(x: x, y: y, width: sq, height: sq)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: sq * 0.25),
                             with: .color(levelColors[level(w, d)]))
                }
            }
        }
        .frame(height: 78)
        .accessibilityHidden(true)
    }

    /// Deterministic 0…4 level, weighted toward the low end for realism.
    private func level(_ w: Int, _ d: Int) -> Int {
        let n = Double((w * days + d + seed) &* 2654435761 & 0xFFFFFF)
        let v = abs(sin(n)).truncatingRemainder(dividingBy: 1)
        switch v {
        case ..<0.52: return 0
        case ..<0.74: return 1
        case ..<0.88: return 2
        case ..<0.96: return 3
        default: return 4
        }
    }
}

#Preview {
    ContributionGraph()
        .padding()
        .background(Color.canopyPaper)
}
