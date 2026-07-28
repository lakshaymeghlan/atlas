import SwiftUI

/// The Welcome hero river: soft periwinkle silk-flow strands under a gentle
/// journey line with Find·Join·Belong ring nodes, and a little paper boat with
/// a foam wake drifting on the surface. Reduce Motion → still.
///
/// ponytail: the flowing "silk" is layered blurred sine ribbons — an evocative
/// approximation of a rendered flow illustration, not a pixel copy of one.
struct RiverBand: View {
    var tint: Color
    var isDark: Bool
    var nodeInset: CGFloat = 24

    private let bandHeight: CGFloat = 190
    private let nodeFractions: [CGFloat] = [1.0 / 6, 0.5, 5.0 / 6]
    private let lineY: CGFloat = 30
    private let lineAmp: CGFloat = 7

    // (midY fraction, amplitude, cycles, drift period, stroke width, opacity light, dark)
    private let ribbons: [(CGFloat, CGFloat, CGFloat, Double, CGFloat, CGFloat, CGFloat)] = [
        (0.46, 50, 0.6, 22, 48, 0.06, 0.09),
        (0.42, 42, 0.7, 26, 42, 0.07, 0.10),
        (0.52, 32, 0.9, 20, 36, 0.13, 0.16),
        (0.60, 26, 1.1, 27, 30, 0.13, 0.16),
        (0.66, 36, 0.8, 18, 36, 0.09, 0.12),
        (0.72, 22, 1.4, 30, 24, 0.07, 0.10),
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
        drawSilk(&ctx, size, t: t, animate: animate)
        drawJourneyLine(&ctx, size, t: t, animate: animate)
        drawBoat(&ctx, size, t: t, animate: animate)
    }

    // MARK: Silk flow

    private func drawSilk(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        let W = size.width, H = size.height
        func phase(_ period: Double, _ seed: Double) -> CGFloat {
            animate ? CGFloat(2 * .pi * (t.truncatingRemainder(dividingBy: period) / period)) : CGFloat(seed)
        }

        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 13))
            for (i, r) in ribbons.enumerated() {
                let pts = RiverShapes.points(width: W, midY: H * r.0, amplitude: r.1,
                                             wavelengths: r.2, phase: phase(r.3, Double(i) * 1.3))
                layer.stroke(RiverShapes.smoothPath(pts),
                             with: .color(tint.opacity(isDark ? r.6 : r.5)),
                             style: StrokeStyle(lineWidth: r.4, lineCap: .round))
            }
        }
        // Airy white highlights weaving through.
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 7))
            for (i, spec) in [(CGFloat(0.50), CGFloat(26), CGFloat(0.8), 21.0),
                              (0.58, 18, 1.2, 16.0)].enumerated() {
                let pts = RiverShapes.points(width: W, midY: H * spec.0, amplitude: spec.1,
                                             wavelengths: spec.2, phase: phase(spec.3, Double(i)))
                layer.stroke(RiverShapes.smoothPath(pts),
                             with: .color(.white.opacity(isDark ? 0.10 : 0.5)),
                             style: StrokeStyle(lineWidth: 6, lineCap: .round))
            }
        }
        // A couple of soft filaments for definition (gently blurred so they read
        // as flow, not stray threads).
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 1.5))
            for (i, spec) in [(CGFloat(0.52), CGFloat(24), CGFloat(0.8), 24.0),
                              (0.62, 30, 0.6, 19.0)].enumerated() {
                let pts = RiverShapes.points(width: W, midY: H * spec.0, amplitude: spec.1,
                                             wavelengths: spec.2, phase: phase(spec.3, Double(i) * 0.9))
                layer.stroke(RiverShapes.smoothPath(pts), with: .color(tint.opacity(0.18)),
                             style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
        }
    }

    // MARK: Journey line + nodes

    private func drawJourneyLine(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        let span = size.width - nodeInset * 2
        let drift: CGFloat = animate ? CGFloat(2 * .pi * (t.truncatingRemainder(dividingBy: 14) / 14)) : 0
        let pts = RiverShapes.points(width: span, midY: lineY, amplitude: lineAmp,
                                     wavelengths: 1.1, phase: drift)
            .map { CGPoint(x: $0.x + nodeInset, y: $0.y) }
        ctx.stroke(RiverShapes.smoothPath(pts), with: .color(tint.opacity(0.55)),
                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

        for frac in nodeFractions {
            let x = nodeInset + span * frac
            let y = RiverShapes.y(atX: span * frac, width: span, midY: lineY,
                                  amplitude: lineAmp, wavelengths: 1.1, phase: drift)
            let c = CGPoint(x: x, y: y)
            ctx.fill(disc(c, 6.5), with: .color(isDark ? Color(hex: "1A1915") : Color(hex: "FCFBF8")))
            ctx.stroke(disc(c, 6.5), with: .color(tint), lineWidth: 2)
        }
    }

    // MARK: Paper boat + wake

    private func drawBoat(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        let span = size.width - nodeInset * 2
        let baseX = nodeInset + span * 0.30
        let driftX = animate ? 16 * sin(2 * .pi * t / 13) : 0
        let x = baseX + CGFloat(driftX)
        let y = size.height * 0.56 + (animate ? 1.6 * sin(2 * .pi * t / 3.2) : 0)
        let s: CGFloat = 18

        // Foam wake trailing to the right.
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 2))
            var wake = Path()
            wake.move(to: CGPoint(x: x + s * 0.9, y: y + s * 0.5))
            wake.addQuadCurve(to: CGPoint(x: x + s * 4.5, y: y + s * 0.2),
                              control: CGPoint(x: x + s * 2.6, y: y + s * 0.9))
            layer.stroke(wake, with: .color(.white.opacity(isDark ? 0.25 : 0.7)), lineWidth: 2)
            // sparkle foam dots
            for (dx, dy, r) in [(1.7, 0.2, 1.3), (2.5, 0.55, 1.0), (3.3, 0.1, 1.2), (3.9, 0.5, 0.9)] {
                layer.fill(disc(CGPoint(x: x + s * CGFloat(dx), y: y + s * CGFloat(dy)), CGFloat(r)),
                           with: .color(.white.opacity(isDark ? 0.4 : 0.9)))
            }
        }

        ctx.drawLayer { layer in
            layer.translateBy(x: x, y: y)

            layer.drawLayer { sh in
                sh.addFilter(.blur(radius: 4))
                sh.fill(Path(ellipseIn: CGRect(x: -s * 1.1, y: s * 0.55, width: s * 2.2, height: s * 0.5)),
                        with: .color(Palette.ink.opacity(0.14)))
            }

            var hull = Path()
            hull.move(to: CGPoint(x: -1.15 * s, y: 0.14 * s))
            hull.addLine(to: CGPoint(x: 1.15 * s, y: 0.14 * s))
            hull.addLine(to: CGPoint(x: 0.72 * s, y: 0.7 * s))
            hull.addLine(to: CGPoint(x: -0.72 * s, y: 0.7 * s))
            hull.closeSubpath()

            var sail = Path()
            sail.move(to: CGPoint(x: 0, y: -0.98 * s))
            sail.addLine(to: CGPoint(x: -0.92 * s, y: 0.1 * s))
            sail.addLine(to: CGPoint(x: 0.92 * s, y: 0.1 * s))
            sail.closeSubpath()

            layer.fill(hull, with: .color(.white))
            layer.fill(sail, with: .color(.white))
            // Right halves slightly shaded for a folded-paper dimension.
            var sailShade = Path()
            sailShade.move(to: CGPoint(x: 0, y: -0.98 * s))
            sailShade.addLine(to: CGPoint(x: 0.92 * s, y: 0.1 * s))
            sailShade.addLine(to: CGPoint(x: 0, y: 0.1 * s))
            sailShade.closeSubpath()
            layer.fill(sailShade, with: .color(Palette.ink.opacity(0.06)))
            var hullShade = Path()
            hullShade.move(to: CGPoint(x: 0, y: 0.14 * s))
            hullShade.addLine(to: CGPoint(x: 1.15 * s, y: 0.14 * s))
            hullShade.addLine(to: CGPoint(x: 0.72 * s, y: 0.7 * s))
            hullShade.addLine(to: CGPoint(x: 0, y: 0.7 * s))
            hullShade.closeSubpath()
            layer.fill(hullShade, with: .color(Palette.ink.opacity(0.05)))

            layer.stroke(sail, with: .color(Palette.ink.opacity(0.1)), lineWidth: 0.75)
            layer.stroke(hull, with: .color(Palette.ink.opacity(0.1)), lineWidth: 0.75)
        }
    }

    private func disc(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
}

#Preview {
    VStack(spacing: 0) {
        RiverBand(tint: Color(hex: "7A8FFF"), isDark: false)
        RiverBand(tint: Color(hex: "7A8FFF"), isDark: true).background(Color(hex: "1A1915"))
    }
    .background(Color(hex: "FCFBF8"))
}
