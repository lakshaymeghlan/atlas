import SwiftUI

/// The Welcome hero — deliberately minimal. A single elegant journey line
/// carries the Find·Join·Belong ring nodes; a soft light glides along it,
/// briefly lifting each node as it passes, then rests and repeats. No literal
/// water, no boat — just one calm, premium motion. Reduce Motion → still line.
struct RiverBand: View {
    var tint: Color
    var nodeInset: CGFloat = 24

    private let bandHeight: CGFloat = 108
    private let nodeFractions: [CGFloat] = [1.0 / 6, 0.5, 5.0 / 6]
    private let lineY: CGFloat = 40
    private let lineAmp: CGFloat = 8
    private let cycle: Double = 6.5
    private let travelDur: Double = 4.5

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
        let span = size.width - nodeInset * 2
        let drift = animate ? CGFloat(2 * .pi * (t.truncatingRemainder(dividingBy: 18) / 18)) : 0
        let pts = RiverShapes.points(width: span, midY: lineY, amplitude: lineAmp,
                                     wavelengths: 1.1, phase: drift)
            .map { CGPoint(x: $0.x + nodeInset, y: $0.y) }
        let line = RiverShapes.smoothPath(pts)

        // A soft sheen beneath the line gives it a premium glow.
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 7))
            layer.stroke(line, with: .color(tint.opacity(0.12)),
                         style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }

        // Base line — a hairline that fades to nothing at both edges.
        ctx.stroke(
            line,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: tint.opacity(0), location: 0),
                    .init(color: tint.opacity(0.32), location: 0.12),
                    .init(color: tint.opacity(0.32), location: 0.88),
                    .init(color: tint.opacity(0), location: 1),
                ]),
                startPoint: CGPoint(x: 0, y: lineY), endPoint: CGPoint(x: size.width, y: lineY)
            ),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
        )

        // The journey runs Find → Belong, then a soft pulse settles at Belong.
        let travelStart = nodeFractions[0], travelEnd = nodeFractions[2]
        var lightF: CGFloat = -1
        var lightOpacity: CGFloat = 0
        var settle: Double = 0
        if animate {
            let x = t.truncatingRemainder(dividingBy: cycle)
            if x < travelDur {
                let u = CGFloat(Motion.standardEase(x / travelDur))
                lightF = travelStart + u * (travelEnd - travelStart)
            } else {
                lightF = travelEnd
                settle = min(1, (x - travelDur) / 1.0) // 0…1 over the first second of rest
            }
            lightOpacity = fadeEnvelope(x)

            if lightOpacity > 0.01 {
                // Longer comet trail with a soft gradient.
                let a = max(0.0001, lightF - 0.24)
                let trail = line.trimmedPath(from: a, to: min(1, lightF))
                ctx.stroke(trail, with: .linearGradient(
                    Gradient(colors: [tint.opacity(0), tint.opacity(0.85 * lightOpacity)]),
                    startPoint: point(on: line, at: a), endPoint: point(on: line, at: lightF)),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                let p = point(on: line, at: lightF)
                ctx.drawLayer { layer in
                    layer.addFilter(.blur(radius: 7))
                    layer.fill(disc(p, 7), with: .color(tint.opacity(0.55 * lightOpacity)))
                }
                ctx.fill(disc(p, 4), with: .color(tint.opacity(0.32 * lightOpacity)))
                ctx.fill(disc(p, 2.4), with: .color(.white.opacity(lightOpacity)))
            }
        }

        // Nodes — quiet rings that lift as the light passes.
        for frac in nodeFractions {
            let p = point(on: line, at: frac)
            let d = lightF < 0 ? 1 : abs(lightF - frac)
            let glow = d < 0.085 ? exp(-pow(Double(d) / 0.045, 2)) * Double(lightOpacity) : 0
            let r = 6.0 + 1.2 * glow
            ctx.fill(disc(p, CGFloat(r) + 1.5), with: .color(Color(hex: "FCFBF8")))
            if glow > 0.02 {
                ctx.drawLayer { layer in
                    layer.addFilter(.blur(radius: 5))
                    layer.fill(disc(p, CGFloat(r)), with: .color(tint.opacity(0.5 * glow)))
                }
            }
            ctx.stroke(disc(p, CGFloat(r)), with: .color(tint.opacity(0.5 + 0.5 * glow)),
                       lineWidth: 2)
        }

        // Arrival: one soft expanding ring at Belong.
        if settle > 0, settle < 1, lightOpacity > 0.01 {
            let p = point(on: line, at: travelEnd)
            let e = Motion.standardEase(settle)
            let radius = 6 + 16 * CGFloat(e)
            ctx.stroke(disc(p, radius),
                       with: .color(tint.opacity((1 - settle) * 0.45 * Double(lightOpacity))),
                       lineWidth: 1.5)
        }
    }

    /// Fade in at the start, hold through travel + rest, fade out just before reset.
    private func fadeEnvelope(_ x: Double) -> CGFloat {
        if x < 0.45 { return CGFloat(x / 0.45) }
        if x > cycle - 0.7 { return CGFloat(max(0, (cycle - x) / 0.7)) }
        return 1
    }

    private func point(on path: Path, at frac: CGFloat) -> CGPoint {
        path.trimmedPath(from: 0, to: max(0.0001, min(1, frac))).currentPoint ?? .zero
    }

    private func disc(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
}

#Preview {
    RiverBand(tint: Color(hex: "7A8FFF"))
        .frame(maxWidth: .infinity)
        .background(Color(hex: "FCFBF8"))
}
