import SwiftUI

/// The Welcome hero: a calm scene that fills the space above the headline —
/// soft drifting clouds over the river, with the raft waiting at the first
/// checkpoint. A promise of the journey, in the product's own metaphor.
struct WelcomeRiverHero: View {
    private let amplitude: CGFloat = 10
    private let wavelengths: CGFloat = 1.2
    private let inset: CGFloat = 24
    private let stageCount = Journey.stageTitles.count

    // (yFraction, scale, speed pt/s, phase 0…1, colour)
    private let clouds: [(CGFloat, CGFloat, Double, CGFloat, Color)] = [
        (0.16, 27, 6.0, 0.00, Color.white.opacity(0.9)),
        (0.30, 18, 9.5, 0.45, Palette.blueTint.opacity(0.8)),
        (0.21, 22, 4.5, 0.70, Color.white.opacity(0.75)),
        (0.40, 14, 11.5, 0.20, Palette.blueTint.opacity(0.7)),
    ]

    var body: some View {
        Group {
            if Motion.reduceMotion {
                Canvas { ctx, size in draw(&ctx, size, t: 0, bob: 0, drift: false) }
            } else {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let bob = 2.0 * sin(2 * .pi * t / 2.6)
                    Canvas { ctx, size in draw(&ctx, size, t: t, bob: bob, drift: true) }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, bob: CGFloat, drift: Bool) {
        guard size.width > 0 else { return }
        drawClouds(&ctx, size, t: t, drift: drift)

        let w = size.width - inset * 2
        let midY = size.height * 0.78
        let phase = drift ? 2 * .pi * (t.truncatingRemainder(dividingBy: 16) / 16) : 0

        let pts = RiverShapes.points(width: w, midY: midY, amplitude: amplitude,
                                     wavelengths: wavelengths, phase: phase)
            .map { CGPoint(x: $0.x + inset, y: $0.y) }
        ctx.stroke(RiverShapes.smoothPath(pts), with: .color(Palette.border), lineWidth: 2)

        // Checkpoints 1… as rings; the raft sits at checkpoint 0.
        for i in 1..<stageCount {
            let x = inset + w * CGFloat(i) / CGFloat(stageCount - 1)
            let y = RiverShapes.y(atX: x - inset, width: w, midY: midY,
                                  amplitude: amplitude, wavelengths: wavelengths, phase: phase)
            ctx.fill(disc(CGPoint(x: x, y: y), 5), with: .color(Palette.paper))
            ctx.stroke(disc(CGPoint(x: x, y: y), 4), with: .color(Palette.border), lineWidth: 2)
        }

        let boatX = inset
        let boatY = RiverShapes.y(atX: 0, width: w, midY: midY,
                                  amplitude: amplitude, wavelengths: wavelengths, phase: phase)
        // Soft reflection to anchor the boat on the water.
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 6))
            layer.fill(Path(ellipseIn: CGRect(x: boatX - 16, y: boatY + 2, width: 32, height: 8)),
                       with: .color(Palette.blue.opacity(0.18)))
        }
        let tilt = RiverArt.tilt(atX: 0, width: w, amplitude: amplitude,
                                 wavelengths: wavelengths, phase: phase)
        RiverArt.drawBoat(in: &ctx, at: CGPoint(x: boatX, y: boatY - bob), scale: 11, tilt: tilt)
    }

    private func drawClouds(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, drift: Bool) {
        for (yFrac, scale, speed, phase, color) in clouds {
            let margin = scale * 2.5
            let span = Double(size.width + margin * 2)
            let base = Double(phase) * span
            let offset = drift ? (t * speed + base) : base
            let x = -Double(margin) + offset.truncatingRemainder(dividingBy: span)
            RiverArt.drawCloud(in: &ctx, at: CGPoint(x: CGFloat(x), y: size.height * yFrac),
                               scale: scale, color: color)
        }
    }

    private func disc(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
}

#Preview {
    WelcomeRiverHero()
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .background(Palette.paper)
}
