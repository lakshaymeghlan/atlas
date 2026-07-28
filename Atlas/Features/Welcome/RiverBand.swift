import SwiftUI

/// The Welcome hero river — restrained and crafted rather than busy. A soft
/// water body fades downward; a few crisp flowing currents drift across, each
/// fading to nothing at the screen edges; a gentle journey line carries the
/// Find·Join·Belong ring nodes; and a small paper boat rides the top current
/// with a thin wake. Reduce Motion → still.
struct RiverBand: View {
    var tint: Color
    var nodeInset: CGFloat = 24

    private let bandHeight: CGFloat = 176
    private let nodeFractions: [CGFloat] = [1.0 / 6, 0.5, 5.0 / 6]
    private let lineY: CGFloat = 28
    private let lineAmp: CGFloat = 7

    // (midY fraction, amplitude, cycles, drift period, width, opacity)
    private let currents: [(CGFloat, CGFloat, CGFloat, Double, CGFloat, Double)] = [
        (0.38, 10, 0.7, 24, 1.4, 0.42),
        (0.44, 20, 0.9, 19, 1.1, 0.34),
        (0.50, 14, 1.2, 27, 0.9, 0.28),
        (0.57, 26, 0.6, 22, 1.2, 0.24),
        (0.64, 18, 1.1, 25, 0.9, 0.20),
        (0.71, 22, 1.4, 31, 0.7, 0.16),
    ]

    var body: some View {
        Group {
            if Motion.reduceMotion {
                Canvas { ctx, size in draw(&ctx, size, t: 0, animate: false) }
            } else {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in draw(&ctx, size, t: t, animate: true) }
                }
            }
        }
        .frame(height: bandHeight)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        guard size.width > 1 else { return }
        drawWater(&ctx, size, t: t, animate: animate)
        drawCurrents(&ctx, size, t: t, animate: animate)
        drawJourneyLine(&ctx, size, t: t, animate: animate)
        drawBoat(&ctx, size, t: t, animate: animate)
    }

    private func phase(_ period: Double, _ seed: Double, _ t: Double, _ animate: Bool) -> CGFloat {
        animate ? CGFloat(2 * .pi * (t.truncatingRemainder(dividingBy: period) / period)) : CGFloat(seed)
    }

    /// Soft body of water — one smooth wave filled with a downward-fading tint.
    private func drawWater(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        let W = size.width, H = size.height
        let surface = H * 0.40
        let pts = RiverShapes.points(width: W, midY: surface, amplitude: 14,
                                     wavelengths: 0.8, phase: phase(30, 0, t, animate))
        ctx.fill(
            RiverShapes.fillPath(pts, size: size),
            with: .linearGradient(
                Gradient(colors: [tint.opacity(0.13), tint.opacity(0.02), .clear]),
                startPoint: CGPoint(x: W / 2, y: surface),
                endPoint: CGPoint(x: W / 2, y: H * 0.98)
            )
        )
    }

    /// Crisp flowing currents, each fading to clear at both edges.
    private func drawCurrents(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        let W = size.width, H = size.height
        // One very soft wide glow for depth.
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 14))
            let pts = RiverShapes.points(width: W, midY: H * 0.52, amplitude: 20,
                                         wavelengths: 0.7, phase: phase(26, 0, t, animate))
            layer.stroke(RiverShapes.smoothPath(pts), with: .color(tint.opacity(0.10)),
                         style: StrokeStyle(lineWidth: 26, lineCap: .round))
        }
        for (i, c) in currents.enumerated() {
            let y = H * c.0
            let pts = RiverShapes.points(width: W, midY: y, amplitude: c.1,
                                         wavelengths: c.2, phase: phase(c.3, Double(i) * 1.1, t, animate))
            ctx.stroke(
                RiverShapes.smoothPath(pts),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: tint.opacity(c.5), location: 0.16),
                        .init(color: tint.opacity(c.5), location: 0.84),
                        .init(color: .clear, location: 1),
                    ]),
                    startPoint: CGPoint(x: 0, y: y), endPoint: CGPoint(x: W, y: y)
                ),
                style: StrokeStyle(lineWidth: c.4, lineCap: .round)
            )
        }
    }

    private func drawJourneyLine(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        let span = size.width - nodeInset * 2
        let drift = phase(16, 0, t, animate)
        let pts = RiverShapes.points(width: span, midY: lineY, amplitude: lineAmp,
                                     wavelengths: 1.1, phase: drift)
            .map { CGPoint(x: $0.x + nodeInset, y: $0.y) }
        ctx.stroke(
            RiverShapes.smoothPath(pts),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: tint.opacity(0.0), location: 0),
                    .init(color: tint.opacity(0.5), location: 0.12),
                    .init(color: tint.opacity(0.5), location: 0.88),
                    .init(color: tint.opacity(0.0), location: 1),
                ]),
                startPoint: CGPoint(x: 0, y: lineY), endPoint: CGPoint(x: size.width, y: lineY)
            ),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
        )
        for frac in nodeFractions {
            let x = nodeInset + span * frac
            let y = RiverShapes.y(atX: span * frac, width: span, midY: lineY,
                                  amplitude: lineAmp, wavelengths: 1.1, phase: drift)
            let c = CGPoint(x: x, y: y)
            ctx.fill(disc(c, 6.5), with: .color(Color(hex: "FCFBF8")))
            ctx.stroke(disc(c, 6.5), with: .color(tint), lineWidth: 2)
        }
    }

    private func drawBoat(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        let span = size.width - nodeInset * 2
        let x = nodeInset + span * 0.30 + (animate ? 14 * sin(2 * .pi * t / 14) : 0)
        let y = size.height * 0.46 + (animate ? 1.4 * sin(2 * .pi * t / 3.2) : 0)
        let s: CGFloat = 16

        // Thin wake trailing right + a couple of sparkles.
        ctx.drawLayer { layer in
            var wake = Path()
            wake.move(to: CGPoint(x: x + s * 0.9, y: y + s * 0.42))
            wake.addQuadCurve(to: CGPoint(x: x + s * 4.2, y: y + s * 0.16),
                              control: CGPoint(x: x + s * 2.5, y: y + s * 0.7))
            layer.stroke(wake, with: .linearGradient(
                Gradient(colors: [tint.opacity(0.5), .clear]),
                startPoint: CGPoint(x: x + s, y: y), endPoint: CGPoint(x: x + s * 4.4, y: y)),
                style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            for (dx, dy, r) in [(2.4, 0.15, 1.1), (3.2, 0.4, 0.9), (3.9, 0.1, 0.8)] {
                layer.fill(disc(CGPoint(x: x + s * CGFloat(dx), y: y + s * CGFloat(dy)), CGFloat(r)),
                           with: .color(tint.opacity(0.55)))
            }
        }

        ctx.drawLayer { layer in
            layer.translateBy(x: x, y: y)
            layer.drawLayer { sh in
                sh.addFilter(.blur(radius: 3.5))
                sh.fill(Path(ellipseIn: CGRect(x: -s * 1.0, y: s * 0.5, width: s * 2.0, height: s * 0.42)),
                        with: .color(Palette.ink.opacity(0.12)))
            }
            // Hull: pointed top corners with a rounded bottom — reads as a
            // little paper boat, not a trapezoid.
            var hull = Path()
            hull.move(to: CGPoint(x: -1.15 * s, y: 0.16 * s))
            hull.addLine(to: CGPoint(x: 1.15 * s, y: 0.16 * s))
            hull.addQuadCurve(to: CGPoint(x: -1.15 * s, y: 0.16 * s),
                              control: CGPoint(x: 0, y: 1.0 * s))
            hull.closeSubpath()
            // Sail: a folded triangular peak.
            var sail = Path()
            sail.move(to: CGPoint(x: 0, y: -1.0 * s))
            sail.addLine(to: CGPoint(x: -0.86 * s, y: 0.12 * s))
            sail.addLine(to: CGPoint(x: 0.86 * s, y: 0.12 * s))
            sail.closeSubpath()
            layer.fill(hull, with: .color(.white))
            layer.fill(sail, with: .color(.white))
            // Subtle fold shading on the right halves for a paper dimension.
            var sailFold = Path()
            sailFold.move(to: CGPoint(x: 0, y: -1.0 * s))
            sailFold.addLine(to: CGPoint(x: 0.86 * s, y: 0.12 * s))
            sailFold.addLine(to: CGPoint(x: 0, y: 0.12 * s))
            sailFold.closeSubpath()
            layer.fill(sailFold, with: .color(Palette.ink.opacity(0.06)))
            // Centre fold line on the sail.
            var crease = Path()
            crease.move(to: CGPoint(x: 0, y: -0.95 * s))
            crease.addLine(to: CGPoint(x: 0, y: 0.12 * s))
            layer.stroke(crease, with: .color(Palette.ink.opacity(0.12)), lineWidth: 0.75)
            layer.stroke(sail, with: .color(Palette.ink.opacity(0.1)), lineWidth: 0.75)
            layer.stroke(hull, with: .color(Palette.ink.opacity(0.1)), lineWidth: 0.75)
        }
    }

    private func disc(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
}

#Preview {
    RiverBand(tint: Color(hex: "7A8FFF"))
        .background(Color(hex: "FCFBF8"))
}
