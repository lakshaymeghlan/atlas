import SwiftUI

/// The Welcome hero: a living scene above the headline. Visible clouds drift
/// over a visible river lane; the raft sails smoothly checkpoint to checkpoint
/// — IN PROGRESS → FINDING JOBS → INTERVIEW PREP — the active milestone
/// lighting up as it arrives, then the journey loops. The product's promise,
/// in its own metaphor.
struct WelcomeRiverHero: View {
    private let amplitude: CGFloat = 12
    private let wavelengths: CGFloat = 1.15
    private let inset: CGFloat = 52
    private let labels = ["IN PROGRESS", "FINDING JOBS", "INTERVIEW PREP"]
    private var count: Int { labels.count }

    // (yFraction, scale, speed pt/s, phase 0…1, colour)
    private let clouds: [(CGFloat, CGFloat, Double, CGFloat, Color)] = [
        (0.12, 30, 5.0, 0.05, Color.white),
        (0.26, 22, 8.0, 0.42, Color.white.opacity(0.92)),
        (0.15, 24, 3.4, 0.72, Palette.blueTint),
        (0.32, 17, 10.5, 0.20, Color.white.opacity(0.85)),
        (0.20, 20, 6.4, 0.90, Palette.blueTint.opacity(0.9)),
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
        .accessibilityElement()
        .accessibilityLabel("Atlas carries you from finding jobs to interview-ready.")
    }

    // MARK: Scene

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        guard size.width > 0 else { return }

        drawClouds(&ctx, size, t: t, animate: animate)

        let w = size.width - inset * 2
        let midY = size.height * 0.60
        let phase = animate ? 2 * .pi * (t.truncatingRemainder(dividingBy: 16) / 16) : 0
        let bob = animate ? 2.0 * sin(2 * .pi * t / 2.6) : 0

        let (pos, boatOpacity) = animate ? journey(t) : (0, 1)

        let pts = RiverShapes.points(width: w, midY: midY, amplitude: amplitude,
                                     wavelengths: wavelengths, phase: phase)
            .map { CGPoint(x: $0.x + inset, y: $0.y) }
        let path = RiverShapes.smoothPath(pts)

        // The river lane — a soft channel of water you can see.
        ctx.stroke(path, with: .color(Palette.blue.opacity(0.07)),
                   style: StrokeStyle(lineWidth: 22, lineCap: .round))
        ctx.stroke(path, with: .color(Palette.blue.opacity(0.13)),
                   style: StrokeStyle(lineWidth: 13, lineCap: .round))
        ctx.stroke(path, with: .color(Palette.blue.opacity(0.35)),
                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

        // The travelled wake behind the boat — brighter, with a glow.
        let posFrac = count > 1 ? pos / CGFloat(count - 1) : 0
        if posFrac > 0.001 {
            let wake = path.trimmedPath(from: 0, to: posFrac)
            ctx.drawLayer { layer in
                layer.addFilter(.blur(radius: 9))
                layer.stroke(wake, with: .color(Palette.blue.opacity(0.3)), lineWidth: 12)
            }
            ctx.stroke(wake, with: .color(Palette.blue),
                       style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }

        drawNodesAndLabels(&ctx, w: w, midY: midY, phase: phase, pos: pos)
        drawBoat(&ctx, w: w, midY: midY, phase: phase, pos: pos, bob: bob, opacity: boatOpacity)
    }

    private func drawNodesAndLabels(_ ctx: inout GraphicsContext, w: CGFloat, midY: CGFloat, phase: CGFloat, pos: CGFloat) {
        for i in 0..<count {
            let x = inset + w * CGFloat(i) / CGFloat(count - 1)
            let y = RiverShapes.y(atX: x - inset, width: w, midY: midY,
                                  amplitude: amplitude, wavelengths: wavelengths, phase: phase)
            let p = CGPoint(x: x, y: y)
            let distance = abs(pos - CGFloat(i))
            let reached = pos > CGFloat(i) + 0.5
            let active = distance <= 0.5

            // Node
            ctx.fill(disc(p, 6), with: .color(Palette.paper)) // mask the lane
            if reached {
                ctx.fill(disc(p, 4), with: .color(Palette.blue))
                var check = Path()
                check.move(to: CGPoint(x: p.x - 2.0, y: p.y + 0.2))
                check.addLine(to: CGPoint(x: p.x - 0.6, y: p.y + 1.7))
                check.addLine(to: CGPoint(x: p.x + 2.3, y: p.y - 1.9))
                ctx.stroke(check, with: .color(.white),
                           style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
            } else if active {
                ctx.fill(disc(p, 5), with: .color(Palette.paper))
                ctx.stroke(disc(p, 5), with: .color(Palette.blue), lineWidth: 3)
                ctx.fill(disc(p, 2), with: .color(Palette.blue))
            } else {
                ctx.stroke(disc(p, 4), with: .color(Palette.border), lineWidth: 2)
            }

            // Label
            let color: Color = active ? Palette.blue : (reached ? Palette.inkSecondary : Palette.inkTertiary)
            var text = ctx.resolve(Text(labels[i])
                .font(.system(size: 9.5, weight: active ? .bold : .medium, design: .monospaced)))
            text.shading = .color(color)
            ctx.draw(text, at: CGPoint(x: x, y: y + 20), anchor: .top)
        }
    }

    private func drawBoat(_ ctx: inout GraphicsContext, w: CGFloat, midY: CGFloat, phase: CGFloat, pos: CGFloat, bob: CGFloat, opacity: CGFloat) {
        let boatX = inset + w * (count > 1 ? pos / CGFloat(count - 1) : 0)
        let boatY = RiverShapes.y(atX: boatX - inset, width: w, midY: midY,
                                  amplitude: amplitude, wavelengths: wavelengths, phase: phase)
        let tilt = RiverArt.tilt(atX: boatX - inset, width: w, amplitude: amplitude,
                                 wavelengths: wavelengths, phase: phase)
        ctx.drawLayer { layer in
            layer.opacity = Double(opacity)
            // Reflection under the hull anchors it to the water.
            layer.drawLayer { glow in
                glow.addFilter(.blur(radius: 6))
                glow.fill(Path(ellipseIn: CGRect(x: boatX - 17, y: boatY + 3, width: 34, height: 9)),
                          with: .color(Palette.blue.opacity(0.2)))
            }
            RiverArt.drawBoat(in: &layer, at: CGPoint(x: boatX, y: boatY - bob), scale: 12, tilt: tilt)
        }
    }

    private func drawClouds(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        for (yFrac, scale, speed, phase, color) in clouds {
            let margin = scale * 2.5
            let span = Double(size.width + margin * 2)
            let base = Double(phase) * span
            let offset = animate ? (t * speed + base) : base
            let x = -Double(margin) + offset.truncatingRemainder(dividingBy: span)
            RiverArt.drawCloud(in: &ctx, at: CGPoint(x: CGFloat(x), y: size.height * yFrac),
                               scale: scale, color: color, blur: 3)
        }
    }

    // MARK: Journey timeline

    /// Boat position in [0, count-1] and its opacity over an 11s loop:
    /// dwell at each checkpoint, ease between them, then fade out, reset, fade in.
    private func journey(_ t: Double) -> (CGFloat, CGFloat) {
        let loop = 11.0
        let x = t.truncatingRemainder(dividingBy: loop)
        let posKeys: [(Double, Double)] = [
            (0.0, 0), (1.0, 0), (2.8, 1), (4.2, 1), (6.0, 2), (8.4, 2),
            (9.0, 2), (9.2, 0), (loop, 0),
        ]
        let opacityKeys: [(Double, Double)] = [
            (0.0, 0), (0.9, 1), (8.4, 1), (9.0, 0), (10.0, 0), (10.7, 1), (loop, 1),
        ]
        return (CGFloat(sample(posKeys, x)), CGFloat(sample(opacityKeys, x)))
    }

    /// Piecewise smoothstep interpolation over (time, value) keyframes.
    private func sample(_ keys: [(Double, Double)], _ x: Double) -> Double {
        guard let first = keys.first, let last = keys.last else { return 0 }
        if x <= first.0 { return first.1 }
        if x >= last.0 { return last.1 }
        for i in 1..<keys.count where x <= keys[i].0 {
            let (t0, v0) = keys[i - 1]
            let (t1, v1) = keys[i]
            guard t1 > t0 else { return v1 }
            let u = (x - t0) / (t1 - t0)
            return v0 + (v1 - v0) * (u * u * (3 - 2 * u))
        }
        return last.1
    }

    private func disc(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
}

#Preview {
    WelcomeRiverHero()
        .frame(height: 340)
        .frame(maxWidth: .infinity)
        .background(Palette.paper)
}
