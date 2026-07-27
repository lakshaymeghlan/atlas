import SwiftUI

/// A calm, ~90pt band of flowing water for the Welcome screen — layered soft
/// waves that drift continuously, with a tiny white paper boat floating slowly
/// across. Edges fade to nothing so it reads as a river passing through, not a
/// boxed graphic. Reduce Motion → still water, boat at rest.
struct RiverBand: View {
    var tint: Color
    var isDark: Bool

    private let bandHeight: CGFloat = 90
    private let surfaceFraction: CGFloat = 0.26
    private let boatLoop: Double = 20

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
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.10),
                    .init(color: .black, location: 0.90),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .accessibilityHidden(true)
    }

    // (amplitude, cycles across width, seconds/drift, y-offset from surface, opacity)
    private var layers: [(CGFloat, CGFloat, Double, CGFloat, CGFloat)] {
        [
            (7, 1.0, 26, 0, isDark ? 0.24 : 0.17),
            (5, 1.5, 18, 6, isDark ? 0.17 : 0.11),
            (4, 2.2, 34, 12, isDark ? 0.11 : 0.07),
        ]
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        guard size.width > 1 else { return }
        let surface = size.height * surfaceFraction

        for (amp, cyc, period, off, op) in layers {
            let phase = animate ? 2 * .pi * (t.truncatingRemainder(dividingBy: period) / period) : 0
            let pts = RiverShapes.points(width: size.width, midY: surface + off,
                                         amplitude: amp, wavelengths: cyc, phase: phase)
            ctx.fill(RiverShapes.fillPath(pts, size: size), with: .color(tint.opacity(op)))
        }

        // A faint specular line along the top surface.
        let phase0 = animate ? 2 * .pi * (t.truncatingRemainder(dividingBy: 26) / 26) : 0
        let surfacePts = RiverShapes.points(width: size.width, midY: surface, amplitude: 7,
                                            wavelengths: 1.0, phase: phase0)
        ctx.stroke(RiverShapes.smoothPath(surfacePts),
                   with: .color(.white.opacity(isDark ? 0.16 : 0.45)), lineWidth: 1)

        // Paper boat drifting slowly across, bobbing on the surface.
        let travel = animate ? t.truncatingRemainder(dividingBy: boatLoop) / boatLoop : 0.32
        let margin: CGFloat = 46
        let boatX = -margin + CGFloat(travel) * (size.width + margin * 2)
        let boatY = RiverShapes.y(atX: boatX, width: size.width, midY: surface, amplitude: 7,
                                  wavelengths: 1.0, phase: phase0)
        let bob = animate ? 1.6 * sin(2 * .pi * t / 3.0) : 0
        let tilt = RiverArt.tilt(atX: boatX, width: size.width, amplitude: 7, wavelengths: 1.0, phase: phase0)
        drawPaperBoat(&ctx, at: CGPoint(x: boatX, y: boatY - 5 + CGFloat(bob)), scale: 11, tilt: tilt)
    }

    /// A little origami paper boat — trapezoid hull + triangular sail with a
    /// centre fold — white, with a soft shadow on the water.
    private func drawPaperBoat(_ ctx: inout GraphicsContext, at p: CGPoint, scale s: CGFloat, tilt: CGFloat) {
        ctx.drawLayer { layer in
            layer.translateBy(x: p.x, y: p.y)
            layer.rotate(by: .radians(Double(tilt)))

            layer.drawLayer { shadow in
                shadow.addFilter(.blur(radius: 4))
                shadow.fill(Path(ellipseIn: CGRect(x: -s * 1.1, y: s * 0.62, width: s * 2.2, height: s * 0.5)),
                            with: .color(Palette.ink.opacity(0.12)))
            }

            var hull = Path()
            hull.move(to: CGPoint(x: -1.15 * s, y: 0.16 * s))
            hull.addLine(to: CGPoint(x: 1.15 * s, y: 0.16 * s))
            hull.addLine(to: CGPoint(x: 0.72 * s, y: 0.74 * s))
            hull.addLine(to: CGPoint(x: -0.72 * s, y: 0.74 * s))
            hull.closeSubpath()

            var sail = Path()
            sail.move(to: CGPoint(x: 0, y: -0.98 * s))
            sail.addLine(to: CGPoint(x: -0.92 * s, y: 0.12 * s))
            sail.addLine(to: CGPoint(x: 0.92 * s, y: 0.12 * s))
            sail.closeSubpath()

            layer.fill(hull, with: .color(.white))
            layer.fill(sail, with: .color(.white))

            var fold = Path()
            fold.move(to: CGPoint(x: 0, y: -0.92 * s))
            fold.addLine(to: CGPoint(x: 0, y: 0.12 * s))
            layer.stroke(fold, with: .color(Palette.ink.opacity(0.12)), lineWidth: 0.75)
            layer.stroke(sail, with: .color(Palette.ink.opacity(0.09)), lineWidth: 0.75)
            layer.stroke(hull, with: .color(Palette.ink.opacity(0.09)), lineWidth: 0.75)
        }
    }
}

#Preview {
    VStack {
        RiverBand(tint: Color(hex: "7A8FFF"), isDark: false)
        RiverBand(tint: Color(hex: "7A8FFF"), isDark: true).background(Color(hex: "1A1915"))
    }
    .background(Color(hex: "FCFBF8"))
}
