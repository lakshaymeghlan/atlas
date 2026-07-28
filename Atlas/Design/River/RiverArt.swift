import SwiftUI

/// Boat drawing for the onboarding progress river (`Current`). The boat is the
/// raft — it rides the current to each checkpoint. (S01 draws its own paper
/// boat in `WhiteRibbon`.)
enum RiverArt {
    /// Draw a little sailboat centred on `point` (its deck sits on the waterline,
    /// the hull dips below). Unit geometry scaled by `scale`; `tilt` rotates it
    /// to follow the wave slope.
    static func drawBoat(
        in ctx: inout GraphicsContext,
        at point: CGPoint,
        scale: CGFloat,
        tilt: CGFloat = 0,
        hull: Color = Palette.ink,
        sail: Color = Palette.blue
    ) {
        ctx.drawLayer { layer in
            layer.translateBy(x: point.x, y: point.y)
            layer.rotate(by: .radians(Double(tilt)))

            // Mast
            var mast = Path()
            mast.move(to: CGPoint(x: 0, y: 0))
            mast.addLine(to: CGPoint(x: 0, y: -1.75 * scale))
            layer.stroke(mast, with: .color(hull), lineWidth: max(1, 0.16 * scale))

            // Sail — a triangle billowing to the right
            var sailPath = Path()
            sailPath.move(to: CGPoint(x: 0.14 * scale, y: -1.65 * scale))
            sailPath.addLine(to: CGPoint(x: 0.14 * scale, y: -0.2 * scale))
            sailPath.addQuadCurve(to: CGPoint(x: 1.05 * scale, y: -0.35 * scale),
                                  control: CGPoint(x: 0.78 * scale, y: -1.15 * scale))
            sailPath.closeSubpath()
            layer.fill(sailPath, with: .color(sail))

            // Hull — a shallow lens sitting in the water
            var hullPath = Path()
            hullPath.move(to: CGPoint(x: -1.05 * scale, y: -0.05 * scale))
            hullPath.addLine(to: CGPoint(x: 1.05 * scale, y: -0.05 * scale))
            hullPath.addQuadCurve(to: CGPoint(x: -1.05 * scale, y: -0.05 * scale),
                                  control: CGPoint(x: 0, y: 1.25 * scale))
            layer.fill(hullPath, with: .color(hull))
        }
    }

    /// Slope-following tilt (radians) for a boat at `x` on the wave, damped so it
    /// leans gently rather than pitching.
    static func tilt(atX x: CGFloat, width: CGFloat, amplitude: CGFloat, wavelengths: CGFloat, phase: CGFloat) -> CGFloat {
        let y1 = RiverShapes.y(atX: x - 2, width: width, midY: 0, amplitude: amplitude, wavelengths: wavelengths, phase: phase)
        let y2 = RiverShapes.y(atX: x + 2, width: width, midY: 0, amplitude: amplitude, wavelengths: wavelengths, phase: phase)
        return atan2(y2 - y1, 4) * 0.6
    }
}
