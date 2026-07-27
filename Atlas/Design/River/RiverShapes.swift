import SwiftUI

/// Sine-wave path building, shared by `Current` (stroked) and `RiverCanvas`
/// (filled). Paths are built with quad curves through sampled points, not a
/// hundred line segments.
enum RiverShapes {
    /// Sample a sine across [0, width]. `wavelengths` is full cycles across the
    /// width; `phase` shifts it horizontally.
    static func points(
        width: CGFloat,
        midY: CGFloat,
        amplitude: CGFloat,
        wavelengths: CGFloat,
        phase: CGFloat,
        step: CGFloat = 10
    ) -> [CGPoint] {
        guard width > 0 else { return [] }
        let k = 2 * .pi * wavelengths / width
        var pts: [CGPoint] = []
        var x: CGFloat = 0
        while x < width {
            pts.append(CGPoint(x: x, y: midY + amplitude * sin(k * x + phase)))
            x += step
        }
        pts.append(CGPoint(x: width, y: midY + amplitude * sin(k * width + phase)))
        return pts
    }

    /// Smooth open path through points using the midpoint quad-curve technique.
    static func smoothPath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first)
        guard pts.count >= 3 else {
            for p in pts.dropFirst() { path.addLine(to: p) }
            return path
        }
        for i in 1..<(pts.count - 1) {
            let mid = CGPoint(x: (pts[i].x + pts[i + 1].x) / 2,
                              y: (pts[i].y + pts[i + 1].y) / 2)
            path.addQuadCurve(to: mid, control: pts[i])
        }
        path.addLine(to: pts[pts.count - 1])
        return path
    }

    /// Closed fill path: the wave, then down and around the bottom of `size`.
    static func fillPath(_ pts: [CGPoint], size: CGSize) -> Path {
        var path = smoothPath(pts)
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }

    /// The sine value at a single x — used to sit nodes exactly on the curve.
    static func y(atX x: CGFloat, width: CGFloat, midY: CGFloat, amplitude: CGFloat, wavelengths: CGFloat, phase: CGFloat) -> CGFloat {
        guard width > 0 else { return midY }
        let k = 2 * .pi * wavelengths / width
        return midY + amplitude * sin(k * x + phase)
    }
}
