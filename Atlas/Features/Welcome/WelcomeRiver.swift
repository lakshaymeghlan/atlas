import SwiftUI

/// S01 hero. A full-bleed band of water previewing the whole Atlas journey —
/// FIND · JOIN · BELONG — with a boat waiting at the start. Nothing is complete
/// and nothing is in progress; it's a promise. One slow light travels the river
/// and rests, so it reads as a journey without claiming the user is on one.
struct WelcomeRiver: View {
    /// When set, renders a single frozen frame at this time (for previews).
    var frozenTime: Double? = nil
    /// Preview-only: force the Reduce Motion path (the env key can't be set).
    var forceReduceMotion = false

    private let config = RiverConfig()
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cache = SampleCache()

    private var reduceMotionActive: Bool { reduceMotion || forceReduceMotion }

    private var height: CGFloat {
        typeSize.isAccessibilitySize ? config.accessibilityHeight : config.height
    }

    var body: some View {
        ZStack {
            if let frozenTime {
                Canvas { ctx, size in draw(&ctx, size, time: frozenTime, animate: true) }
                    .accessibilityHidden(true)
            } else if reduceMotionActive {
                Canvas { ctx, size in draw(&ctx, size, time: 0, animate: false) }
                    .accessibilityHidden(true)
            } else {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { ctx, size in draw(&ctx, size, time: t, animate: true) }
                }
                .accessibilityHidden(true)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Atlas guides you through three stages: find, join, belong.")
    }

    // MARK: Draw

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, time: Double, animate: Bool) {
        guard size.width > 1 else { return }
        let W = size.width, H = size.height
        cache.refresh(config: config, width: W, height: H)
        let path = cache.path

        drawReflection(&ctx, path: path, size: size)
        drawGlow(&ctx, path: path)
        drawBed(&ctx, path: path)

        // Travel light + resulting node pulses.
        var lightCenter: CGFloat = 2 // off-river by default (no pulse under Reduce Motion)
        if animate {
            let (from, to, center) = travelWindow(time)
            lightCenter = center
            let a = max(0, min(1, from)), b = max(0, min(1, to))
            if b > a {
                let seg = path.trimmedPath(from: a, to: b)
                ctx.drawLayer { layer in
                    layer.addFilter(.blur(radius: 5))
                    layer.stroke(seg, with: .color(Palette.blue.opacity(0.25)),
                                 style: StrokeStyle(lineWidth: 8, lineCap: .round))
                }
                ctx.stroke(seg, with: .color(Palette.blue),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }

        drawNodesAndLabels(&ctx, size: size, lightCenter: lightCenter)
        drawBoat(&ctx, time: time, animate: animate)
    }

    // MARK: Layers

    private func drawReflection(_ ctx: inout GraphicsContext, path: Path, size: CGSize) {
        let baseline = path.boundingRect.maxY
        let mirror = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 2 * baseline + 10)
        let reflection = path.applying(mirror)
        ctx.stroke(
            reflection,
            with: .linearGradient(
                Gradient(colors: [Palette.blue.opacity(0.07), .clear]),
                startPoint: CGPoint(x: size.width / 2, y: baseline),
                endPoint: CGPoint(x: size.width / 2, y: baseline + 44)
            ),
            lineWidth: 2
        )
    }

    private func drawGlow(_ ctx: inout GraphicsContext, path: Path) {
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 8))
            layer.stroke(path, with: .color(Palette.blue.opacity(0.09)), lineWidth: 12)
        }
    }

    private func drawBed(_ ctx: inout GraphicsContext, path: Path) {
        ctx.stroke(path, with: .color(Palette.blue.opacity(0.22)),
                   style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    private func drawNodesAndLabels(_ ctx: inout GraphicsContext, size: CGSize, lightCenter: CGFloat) {
        for (i, node) in cache.nodes.enumerated() {
            // Pulse as the light passes: a soft bump on distance in path space.
            let d = abs(lightCenter - config.nodeTs[i])
            let pulse = d < 0.08 ? exp(-pow(d / 0.035, 2)) : 0
            let radius = 4 + 0.5 * pulse
            let opacity = 0.35 + 0.65 * pulse

            ctx.fill(disc(node, radius), with: .color(Palette.paper))
            ctx.stroke(disc(node, radius), with: .color(Palette.blue.opacity(opacity)), lineWidth: 1.5)

            // Label — one style, alternating sides, clamped off the edges.
            var text = ctx.resolve(Text(config.labels[i])
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1.8))
            text.shading = .color(Palette.inkTertiary)
            let measured = text.measure(in: CGSize(width: 200, height: 40))
            let half = measured.width / 2
            let x = min(max(node.x, 12 + half), size.width - 12 - half)
            let below = config.labelBelow[i]
            ctx.draw(text, at: CGPoint(x: x, y: below ? node.y + 22 : node.y - 20),
                     anchor: below ? .top : .bottom)
        }
    }

    private func drawBoat(_ ctx: inout GraphicsContext, time: Double, animate: Bool) {
        let bobY = animate ? 1.5 * sin(2 * .pi * time / 3.4) : 0
        let bobAngle = animate ? (2 * .pi / 180) * sin(2 * .pi * time / 4.1) : 0
        let point = CGPoint(x: cache.boat.x, y: cache.boat.y + CGFloat(bobY))

        ctx.drawLayer { layer in
            layer.translateBy(x: point.x, y: point.y)
            layer.rotate(by: .radians(Double(cache.boatTangent) + bobAngle))

            // Wake — two short arcs trailing the stern, stretching at the top of the bob.
            let stretch = CGFloat(1 + max(0, -bobY) * 0.12)
            for (offset, span) in [(-6.0, 5.0), (-11.0, 6.5)] {
                var wake = Path()
                let ox = CGFloat(offset) * stretch, s = CGFloat(span)
                wake.move(to: CGPoint(x: ox - s / 2, y: 2))
                wake.addQuadCurve(to: CGPoint(x: ox + s / 2, y: 2), control: CGPoint(x: ox, y: 4.5))
                layer.stroke(wake, with: .color(Palette.blue.opacity(0.18)), lineWidth: 1)
            }

            // Hull — flat top, curved bottom.
            var hull = Path()
            hull.move(to: CGPoint(x: -11, y: 0))
            hull.addLine(to: CGPoint(x: 11, y: 0))
            hull.addQuadCurve(to: CGPoint(x: -11, y: 0), control: CGPoint(x: 0, y: 14))
            layer.fill(hull, with: .color(Palette.ink))

            // Mast
            var mast = Path()
            mast.move(to: CGPoint(x: 0, y: 0))
            mast.addLine(to: CGPoint(x: 0, y: -20))
            layer.stroke(mast, with: .color(Palette.ink), lineWidth: 1.5)

            // Sail
            var sail = Path()
            sail.move(to: CGPoint(x: 1.6, y: -19))
            sail.addLine(to: CGPoint(x: 1.6, y: -2))
            sail.addQuadCurve(to: CGPoint(x: 10.5, y: -5), control: CGPoint(x: 7.5, y: -14))
            sail.closeSubpath()
            layer.fill(sail, with: .color(Palette.blue))
        }
    }

    // MARK: Travel window

    /// (from, to, center) of the travel light. Travels −0.16 → 1.0 over 5.5s
    /// (eased), then holds 2.5s off the end. `center` is unclamped so nodes near
    /// the ends still pulse as the light passes.
    private func travelWindow(_ time: Double) -> (CGFloat, CGFloat, CGFloat) {
        let cycle = config.travelDur + config.holdDur
        let x = time.truncatingRemainder(dividingBy: cycle)
        let u = x < config.travelDur ? Motion.standardEase(x / config.travelDur) : 1.0
        let from = -config.windowLen + CGFloat(u) * (1.0 + config.windowLen)
        let to = from + config.windowLen
        return (from, to, from + config.windowLen / 2)
    }

    private func disc(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
}

// MARK: - Config

/// Every magic number for the river lives here — no literals in the drawing code
/// except the boat's local geometry.
struct RiverConfig {
    var height: CGFloat = 200
    var accessibilityHeight: CGFloat = 160

    // Anchor points as fractions of (W, H). The path bleeds 6% off each edge.
    let p0 = CGPoint(x: -0.06, y: 0.60)
    let p1 = CGPoint(x: 0.28, y: 0.38)
    let p2 = CGPoint(x: 0.62, y: 0.60)
    let p3 = CGPoint(x: 1.06, y: 0.34)
    // Horizontal control-handle lengths as fractions of W.
    let h01: CGFloat = 0.16
    let h12: CGFloat = 0.16
    let h23: CGFloat = 0.18

    let nodeTs: [CGFloat] = [0.28, 0.58, 0.88]
    let labels = ["FIND", "JOIN", "BELONG"]
    let labelBelow = [true, false, true]

    let boatT: CGFloat = 0.08

    let windowLen: CGFloat = 0.16
    let travelDur: Double = 5.5
    let holdDur: Double = 2.5

    func path(width W: CGFloat, height H: CGFloat) -> Path {
        func pt(_ f: CGPoint) -> CGPoint { CGPoint(x: f.x * W, y: f.y * H) }
        let a = pt(p0), b = pt(p1), c = pt(p2), d = pt(p3)
        var path = Path()
        path.move(to: a)
        path.addCurve(to: b, control1: CGPoint(x: a.x + h01 * W, y: a.y), control2: CGPoint(x: b.x - h01 * W, y: b.y))
        path.addCurve(to: c, control1: CGPoint(x: b.x + h12 * W, y: b.y), control2: CGPoint(x: c.x - h12 * W, y: c.y))
        path.addCurve(to: d, control1: CGPoint(x: c.x + h23 * W, y: c.y), control2: CGPoint(x: d.x - h23 * W, y: d.y))
        return path
    }
}

// MARK: - Sample cache

/// Path + static sample points (nodes, boat, boat tangent), recomputed only when
/// the width changes — not every frame.
private final class SampleCache {
    private(set) var path = Path()
    private(set) var nodes: [CGPoint] = []
    private(set) var boat: CGPoint = .zero
    private(set) var boatTangent: CGFloat = 0
    private var width: CGFloat = -1

    func refresh(config: RiverConfig, width W: CGFloat, height H: CGFloat) {
        guard W != width else { return }
        width = W
        path = config.path(width: W, height: H)
        nodes = config.nodeTs.map { point(at: $0) }
        boat = point(at: config.boatT)
        let before = point(at: max(0, config.boatT - 0.01))
        let after = point(at: config.boatT + 0.01)
        boatTangent = atan2(after.y - before.y, after.x - before.x)
    }

    private func point(at t: CGFloat) -> CGPoint {
        path.trimmedPath(from: 0, to: max(0.0001, min(1, t))).currentPoint ?? .zero
    }
}

// MARK: - Previews

#Preview("Default") {
    WelcomeRiver().frame(maxWidth: .infinity).background(Palette.paper)
}

#Preview("Reduce Motion") {
    WelcomeRiver(forceReduceMotion: true).frame(maxWidth: .infinity).background(Palette.paper)
}

#Preview("Mid-travel (t = 0.5)") {
    // 0.5 of the 5.5s travel cycle.
    WelcomeRiver(frozenTime: 2.75).frame(maxWidth: .infinity).background(Palette.paper)
}
