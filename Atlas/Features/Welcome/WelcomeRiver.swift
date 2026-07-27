import SwiftUI

/// S01 hero. A full-bleed band of *glass water* previewing the whole Atlas
/// journey — FIND · JOIN · BELONG — with a boat waiting at the start. The water
/// is a translucent glass ribbon with a specular rim; light glints drift across
/// it and one slow travel light runs the length and rests. Nothing is complete
/// and nothing is in progress: it's a promise, not a status.
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
        cache.refresh(config: config, width: size.width, height: size.height)

        drawGlassBody(&ctx, size: size)
        drawSurface(&ctx)
        if animate { drawGlints(&ctx, time: time) }

        // Travel light + resulting node pulses.
        var lightCenter: CGFloat = 2 // off-river by default (no pulse at rest)
        if animate {
            let (from, to, center) = travelWindow(time)
            lightCenter = center
            drawTravelLight(&ctx, from: from, to: to)
        }

        drawNodesAndLabels(&ctx, size: size, lightCenter: lightCenter)
        drawBoat(&ctx, time: time, animate: animate)
    }

    // MARK: Glass water

    private func drawGlassBody(_ ctx: inout GraphicsContext, size: CGSize) {
        // Soft glow beneath the glass gives it depth against the paper.
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 10))
            layer.stroke(cache.path, with: .color(Palette.blue.opacity(0.10)), lineWidth: 16)
        }
        // The glass body: a translucent ribbon, lit at the top, deepening down.
        ctx.fill(
            cache.ribbon,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(0.34), location: 0.0),
                    .init(color: Palette.blue.opacity(0.24), location: 0.30),
                    .init(color: Palette.blue.opacity(0.06), location: 1.0),
                ]),
                startPoint: CGPoint(x: size.width / 2, y: cache.topY),
                endPoint: CGPoint(x: size.width / 2, y: cache.bottomY)
            )
        )
    }

    private func drawSurface(_ ctx: inout GraphicsContext) {
        // Waterline, then a brighter specular edge riding just above it.
        ctx.stroke(cache.path, with: .color(Palette.blue.opacity(0.45)),
                   style: StrokeStyle(lineWidth: 2, lineCap: .round))
        ctx.stroke(cache.path.applying(.init(translationX: 0, y: -0.9)),
                   with: .color(.white.opacity(0.55)),
                   style: StrokeStyle(lineWidth: 1, lineCap: .round))
    }

    private func drawGlints(_ ctx: inout GraphicsContext, time: Double) {
        // Soft highlights drifting along the surface — light catching glass.
        let glints: [(speed: Double, phase: Double, maxOpacity: Double)] = [
            (0.045, 0.00, 0.55), (0.028, 0.40, 0.42), (0.065, 0.72, 0.36),
        ]
        ctx.drawLayer { layer in
            layer.blendMode = .plusLighter
            layer.addFilter(.blur(radius: 3))
            for g in glints {
                let tg = (time * g.speed + g.phase).truncatingRemainder(dividingBy: 1)
                let p = cache.point(at: CGFloat(tg))
                let twinkle = 0.45 + 0.55 * (0.5 + 0.5 * sin(time * 1.7 + g.phase * 6.28))
                let op = g.maxOpacity * twinkle
                let rect = CGRect(x: p.x - 10, y: p.y - 2.4, width: 20, height: 4.8)
                layer.fill(Path(ellipseIn: rect), with: .color(.white.opacity(op)))
            }
        }
    }

    private func drawTravelLight(_ ctx: inout GraphicsContext, from: CGFloat, to: CGFloat) {
        let a = max(0, min(1, from)), b = max(0, min(1, to))
        guard b > a else { return }
        let seg = cache.path.trimmedPath(from: a, to: b)
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 5))
            layer.stroke(seg, with: .color(Palette.blue.opacity(0.28)),
                         style: StrokeStyle(lineWidth: 9, lineCap: .round))
        }
        ctx.stroke(seg, with: .color(Palette.blue),
                   style: StrokeStyle(lineWidth: 3, lineCap: .round))
        // A hot white core makes it read as light refracting through the glass.
        ctx.drawLayer { layer in
            layer.blendMode = .plusLighter
            layer.stroke(seg, with: .color(.white.opacity(0.5)),
                         style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
    }

    private func drawNodesAndLabels(_ ctx: inout GraphicsContext, size: CGSize, lightCenter: CGFloat) {
        for (i, node) in cache.nodes.enumerated() {
            let d = abs(lightCenter - config.nodeTs[i])
            let pulse = d < 0.08 ? exp(-pow(d / 0.035, 2)) : 0
            let radius = 4.5 + 0.8 * pulse
            let ringOpacity = 0.4 + 0.6 * pulse

            // Glass bead: punch the paper, frost fill, ring, specular highlight.
            ctx.fill(disc(node, radius + 1.5), with: .color(Palette.paper))
            ctx.fill(disc(node, radius), with: .color(.white.opacity(0.6)))
            ctx.fill(disc(node, radius), with: .color(Palette.blue.opacity(0.12 + 0.25 * pulse)))
            ctx.stroke(disc(node, radius), with: .color(Palette.blue.opacity(ringOpacity)), lineWidth: 1.5)
            ctx.drawLayer { layer in
                layer.blendMode = .plusLighter
                layer.fill(disc(CGPoint(x: node.x - radius * 0.35, y: node.y - radius * 0.4), radius * 0.32),
                           with: .color(.white.opacity(0.9)))
            }

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

            // Sail + a glassy highlight down its leading edge.
            var sail = Path()
            sail.move(to: CGPoint(x: 1.6, y: -19))
            sail.addLine(to: CGPoint(x: 1.6, y: -2))
            sail.addQuadCurve(to: CGPoint(x: 10.5, y: -5), control: CGPoint(x: 7.5, y: -14))
            sail.closeSubpath()
            layer.fill(sail, with: .color(Palette.blue))
            var sheen = Path()
            sheen.move(to: CGPoint(x: 2.6, y: -17.5))
            sheen.addLine(to: CGPoint(x: 2.6, y: -4))
            layer.stroke(sheen, with: .color(.white.opacity(0.35)), lineWidth: 1)
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
    /// Thickness of the glass water below the surface line.
    let bodyDepth: CGFloat = 26

    let nodeTs: [CGFloat] = [0.28, 0.58, 0.88]
    let labels = ["FIND", "JOIN", "BELONG"]
    let labelBelow = [true, false, true]

    let boatT: CGFloat = 0.08

    let windowLen: CGFloat = 0.16
    let travelDur: Double = 5.5
    let holdDur: Double = 2.5

    /// The surface curve (top edge of the water).
    func path(width W: CGFloat, height H: CGFloat) -> Path {
        let s = segments(width: W, height: H)
        var path = Path()
        path.move(to: s.a)
        path.addCurve(to: s.b, control1: s.a1, control2: s.b2)
        path.addCurve(to: s.c, control1: s.b1, control2: s.c2)
        path.addCurve(to: s.d, control1: s.c1, control2: s.d2)
        return path
    }

    /// The glass body: the surface curve, down one edge, back along an offset
    /// bottom edge, closed — a ribbon of constant thickness `bodyDepth`.
    func ribbonPath(width W: CGFloat, height H: CGFloat) -> Path {
        let s = segments(width: W, height: H)
        func off(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x, y: p.y + bodyDepth) }
        var path = Path()
        path.move(to: s.a)
        path.addCurve(to: s.b, control1: s.a1, control2: s.b2)
        path.addCurve(to: s.c, control1: s.b1, control2: s.c2)
        path.addCurve(to: s.d, control1: s.c1, control2: s.d2)
        path.addLine(to: off(s.d))
        path.addCurve(to: off(s.c), control1: off(s.d2), control2: off(s.c1))
        path.addCurve(to: off(s.b), control1: off(s.c2), control2: off(s.b1))
        path.addCurve(to: off(s.a), control1: off(s.b2), control2: off(s.a1))
        path.closeSubpath()
        return path
    }

    private typealias Segments = (a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint,
                                  a1: CGPoint, b2: CGPoint, b1: CGPoint, c2: CGPoint, c1: CGPoint, d2: CGPoint)

    private func segments(width W: CGFloat, height H: CGFloat) -> Segments {
        func pt(_ f: CGPoint) -> CGPoint { CGPoint(x: f.x * W, y: f.y * H) }
        let a = pt(p0), b = pt(p1), c = pt(p2), d = pt(p3)
        return (a, b, c, d,
                CGPoint(x: a.x + h01 * W, y: a.y), CGPoint(x: b.x - h01 * W, y: b.y),
                CGPoint(x: b.x + h12 * W, y: b.y), CGPoint(x: c.x - h12 * W, y: c.y),
                CGPoint(x: c.x + h23 * W, y: c.y), CGPoint(x: d.x - h23 * W, y: d.y))
    }
}

// MARK: - Sample cache

/// Path, glass ribbon, gradient bounds and static sample points, recomputed only
/// when the width changes — not every frame.
private final class SampleCache {
    private(set) var path = Path()
    private(set) var ribbon = Path()
    private(set) var nodes: [CGPoint] = []
    private(set) var boat: CGPoint = .zero
    private(set) var boatTangent: CGFloat = 0
    private(set) var topY: CGFloat = 0
    private(set) var bottomY: CGFloat = 0
    private var width: CGFloat = -1

    func refresh(config: RiverConfig, width W: CGFloat, height H: CGFloat) {
        guard W != width else { return }
        width = W
        path = config.path(width: W, height: H)
        ribbon = config.ribbonPath(width: W, height: H)
        let bounds = path.boundingRect
        topY = bounds.minY
        bottomY = bounds.maxY + config.bodyDepth
        nodes = config.nodeTs.map { point(at: $0) }
        boat = point(at: config.boatT)
        let before = point(at: max(0, config.boatT - 0.01))
        let after = point(at: config.boatT + 0.01)
        boatTangent = atan2(after.y - before.y, after.x - before.x)
    }

    func point(at t: CGFloat) -> CGPoint {
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
