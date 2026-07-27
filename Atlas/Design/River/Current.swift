import SwiftUI
import UIKit

/// The persistent progress river at the top of every onboarding screen — a
/// gentle sine curve with a glowing travelled portion, a breathing current
/// node, and a slow phase drift. Replaces the idea of a progress bar entirely.
struct Current: View {
    /// One title per stage, e.g. ["welcome", "career path", "upload CV"].
    let stageTitles: [String]
    /// 0-based index of the current (breathing) stage.
    let currentStage: Int

    @State private var animatedProgress: CGFloat = 0

    private let amplitude: CGFloat = 6
    private let wavelengths: CGFloat = 1.4
    private let inset: CGFloat = 12

    private var count: Int { stageTitles.count }
    private func fraction(_ i: Int) -> CGFloat {
        count <= 1 ? 0 : CGFloat(i) / CGFloat(count - 1)
    }

    var body: some View {
        canvas
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .onAppear { animatedProgress = fraction(currentStage) }
            .onChange(of: currentStage) { old, new in
                let anim = Motion.reduceMotion
                    ? Animation.easeInOut(duration: 0.16)
                    : Motion.standard(Motion.river)
                withAnimation(anim) { animatedProgress = fraction(new) }
                if new > old { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            }
            .accessibilityRepresentation {
                HStack(spacing: 0) {
                    ForEach(Array(stageTitles.enumerated()), id: \.offset) { i, title in
                        Text("Stage \(i + 1) of \(count), \(title)")
                            .accessibilityAddTraits(i == currentStage ? [.isSelected] : [])
                    }
                }
            }
    }

    @ViewBuilder private var canvas: some View {
        if Motion.reduceMotion {
            Canvas { ctx, size in draw(&ctx, size, phase: 0, breath: 1) }
        } else {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let phase = 2 * .pi * (t.truncatingRemainder(dividingBy: 12) / 12)
                let breath = 1.03 + 0.03 * sin(2 * .pi * t / 3.2)
                Canvas { ctx, size in draw(&ctx, size, phase: phase, breath: breath) }
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, phase: CGFloat, breath: CGFloat) {
        let w = size.width - inset * 2
        guard w > 0 else { return }
        let midY = size.height / 2

        let pts = RiverShapes.points(width: w, midY: midY, amplitude: amplitude,
                                     wavelengths: wavelengths, phase: phase)
            .map { CGPoint(x: $0.x + inset, y: $0.y) }
        let full = RiverShapes.smoothPath(pts)

        // Untravelled: thin border hairline.
        ctx.stroke(full, with: .color(Palette.border), lineWidth: 2)

        // Travelled: blurred glow behind a solid blue stroke — reads as water.
        if animatedProgress > 0.001 {
            let travelled = full.trimmedPath(from: 0, to: animatedProgress)
            ctx.drawLayer { layer in
                layer.addFilter(.blur(radius: 8))
                layer.stroke(travelled, with: .color(Palette.blue.opacity(0.25)), lineWidth: 10)
            }
            ctx.stroke(travelled, with: .color(Palette.blue),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }

        // Nodes.
        for i in 0..<count {
            let x = inset + w * fraction(i)
            let y = RiverShapes.y(atX: x - inset, width: w, midY: midY,
                                  amplitude: amplitude, wavelengths: wavelengths, phase: phase)
            let p = CGPoint(x: x, y: y)
            if i < currentStage {
                drawCompleted(&ctx, at: p)
            } else if i == currentStage {
                drawCurrent(&ctx, at: p, breath: breath)
            } else {
                drawAhead(&ctx, at: p)
            }
        }
    }

    private func disc(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }

    private func drawCompleted(_ ctx: inout GraphicsContext, at p: CGPoint) {
        ctx.fill(disc(p, 4), with: .color(Palette.paper)) // mask the hairline
        ctx.fill(disc(p, 3.5), with: .color(Palette.blue))
        var check = Path()
        check.move(to: CGPoint(x: p.x - 1.8, y: p.y + 0.2))
        check.addLine(to: CGPoint(x: p.x - 0.5, y: p.y + 1.5))
        check.addLine(to: CGPoint(x: p.x + 2.0, y: p.y - 1.6))
        ctx.stroke(check, with: .color(.white),
                   style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
    }

    private func drawCurrent(_ ctx: inout GraphicsContext, at p: CGPoint, breath: CGFloat) {
        let outer = 4.5 * breath
        ctx.fill(disc(p, outer + 1.5), with: .color(Palette.paper))
        ctx.stroke(disc(p, outer), with: .color(Palette.blue), lineWidth: 3)
        ctx.fill(disc(p, 1.75 * breath), with: .color(Palette.blue))
    }

    private func drawAhead(_ ctx: inout GraphicsContext, at p: CGPoint) {
        ctx.fill(disc(p, 4), with: .color(Palette.paper)) // mask the hairline
        ctx.stroke(disc(p, 3), with: .color(Palette.border), lineWidth: 2)
    }
}

#Preview {
    struct Harness: View {
        @State private var stage = 1
        let titles = ["welcome", "career path", "upload CV"]
        var body: some View {
            VStack(spacing: Space.block) {
                Current(stageTitles: titles, currentStage: stage)
                    .padding(.horizontal, Space.screen)
                Stepper("Stage \(stage + 1) of \(titles.count)", value: $stage, in: 0...(titles.count - 1))
                    .padding(.horizontal, Space.screen)
            }
            .frame(maxHeight: .infinity)
            .background(Palette.paper)
        }
    }
    return Harness()
}
