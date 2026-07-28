import SwiftUI

/// The tone-on-tone white "river" flowing down the right of the Welcome screen,
/// with a paper boat riding its bend. A soft-shadowed white ribbon on the warm
/// off-white background.
///
/// ponytail: an approximation of a rendered 3D flow illustration — a stroked
/// S-spine filled white, with a clipped inner crease shadow + edge highlight for
/// depth. Drop a real PNG in here for a pixel copy.
struct WhiteRibbon: View {
    var background: Color

    // Spine control points as (xFrac, yFrac) of the canvas.
    private let spine: [(CGFloat, CGFloat)] = [
        (0.96, -0.12), (0.74, 0.22), (0.82, 0.48), (1.07, 0.74), (0.93, 1.14),
    ]
    private let boatAt: (CGFloat, CGFloat) = (0.78, 0.43)

    var body: some View {
        Canvas { ctx, size in draw(&ctx, size) }
            .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize) {
        let W = size.width, H = size.height
        guard W > 1 else { return }
        let pts = spine.map { CGPoint(x: $0.0 * W, y: $0.1 * H) }
        let path = RiverShapes.smoothPath(pts)
        let ribbonW = W * 0.36
        let area = path.strokedPath(StrokeStyle(lineWidth: ribbonW, lineCap: .round))

        // Ambient drop shadow.
        ctx.drawLayer { l in
            l.addFilter(.blur(radius: 28))
            l.translateBy(x: 14, y: 18)
            l.fill(area, with: .color(.black.opacity(0.08)))
        }
        // White ribbon body.
        ctx.fill(area, with: .color(.white))

        // Inner crease shadow + right-edge highlight, clipped to the ribbon.
        var inner = ctx
        inner.clip(to: area)
        let leftPts = pts.map { CGPoint(x: $0.x - ribbonW * 0.24, y: $0.y) }
        inner.drawLayer { l in
            l.addFilter(.blur(radius: 22))
            l.stroke(RiverShapes.smoothPath(leftPts), with: .color(.black.opacity(0.06)),
                     style: StrokeStyle(lineWidth: ribbonW * 0.55, lineCap: .round))
        }
        let rightPts = pts.map { CGPoint(x: $0.x + ribbonW * 0.30, y: $0.y) }
        inner.drawLayer { l in
            l.addFilter(.blur(radius: 12))
            l.stroke(RiverShapes.smoothPath(rightPts), with: .color(.white),
                     style: StrokeStyle(lineWidth: ribbonW * 0.34, lineCap: .round))
        }

        drawPaperBoat(&ctx, at: CGPoint(x: boatAt.0 * W, y: boatAt.1 * H), scale: 24, tilt: 0.42)
    }

    /// White origami paper boat with folded-paper shading and a soft shadow.
    private func drawPaperBoat(_ ctx: inout GraphicsContext, at p: CGPoint, scale s: CGFloat, tilt: CGFloat) {
        ctx.drawLayer { layer in
            layer.translateBy(x: p.x, y: p.y)
            layer.rotate(by: .radians(Double(tilt)))

            layer.drawLayer { sh in
                sh.addFilter(.blur(radius: 6))
                sh.fill(Path(ellipseIn: CGRect(x: -s * 1.15, y: s * 0.5, width: s * 2.3, height: s * 0.6)),
                        with: .color(.black.opacity(0.12)))
            }

            var hull = Path()
            hull.move(to: CGPoint(x: -1.15 * s, y: 0.14 * s))
            hull.addLine(to: CGPoint(x: 1.15 * s, y: 0.14 * s))
            hull.addLine(to: CGPoint(x: 0.7 * s, y: 0.7 * s))
            hull.addLine(to: CGPoint(x: -0.7 * s, y: 0.7 * s))
            hull.closeSubpath()

            var sail = Path()
            sail.move(to: CGPoint(x: 0, y: -1.0 * s))
            sail.addLine(to: CGPoint(x: -0.95 * s, y: 0.1 * s))
            sail.addLine(to: CGPoint(x: 0.95 * s, y: 0.1 * s))
            sail.closeSubpath()

            layer.fill(hull, with: .color(.white))
            layer.fill(sail, with: .color(.white))
            // Right halves shaded for folded-paper dimension.
            var sailShade = Path()
            sailShade.move(to: CGPoint(x: 0, y: -1.0 * s))
            sailShade.addLine(to: CGPoint(x: 0.95 * s, y: 0.1 * s))
            sailShade.addLine(to: CGPoint(x: 0, y: 0.1 * s))
            sailShade.closeSubpath()
            layer.fill(sailShade, with: .color(.black.opacity(0.07)))
            var hullShade = Path()
            hullShade.move(to: CGPoint(x: 0, y: 0.14 * s))
            hullShade.addLine(to: CGPoint(x: 1.15 * s, y: 0.14 * s))
            hullShade.addLine(to: CGPoint(x: 0.7 * s, y: 0.7 * s))
            hullShade.addLine(to: CGPoint(x: 0, y: 0.7 * s))
            hullShade.closeSubpath()
            layer.fill(hullShade, with: .color(.black.opacity(0.06)))

            layer.stroke(sail, with: .color(.black.opacity(0.08)), lineWidth: 0.75)
            layer.stroke(hull, with: .color(.black.opacity(0.08)), lineWidth: 0.75)
        }
    }
}

#Preview {
    WhiteRibbon(background: Color(hex: "F3F2EF"))
        .background(Color(hex: "F3F2EF"))
        .ignoresSafeArea()
}
