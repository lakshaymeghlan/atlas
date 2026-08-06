import SwiftUI
import UIKit

/// The full-screen river on the Analysing screen — three drifting sine waves,
/// the CV dissolving into them as falling "lines of text", a cycling status
/// line, and an optional Metal ripple. The moment the app earns its metaphor.
struct RiverCanvas: View {
    /// After ~12s of parsing, swap the cycling copy for a reassuring line.
    var isLongRunning: Bool = false

    @State private var statusIndex = 0

    private let running = ["READING YOUR CV", "MAPPING YOUR EXPERIENCE", "FINDING THE PATTERN"]
    private var phrases: [String] { isLongRunning ? ["STILL WORKING · LONGER CVS TAKE A MOMENT"] : running }
    private var currentPhrase: String { phrases[min(statusIndex, phrases.count - 1)] }

    var body: some View {
        ZStack {
            if Motion.reduceMotion {
                ReducedRiver()
            } else {
                water
            }
            Eyebrow(currentPhrase, color: Color.canopy600)
                .id(currentPhrase)
                .transition(.opacity)
                .padding(.horizontal, Space.screen)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: -40)
        }
        // Canvas is decorative; the status line reaches VoiceOver as a live
        // announcement (posted below) rather than as a focusable element.
        .accessibilityHidden(true)
        .task(id: isLongRunning) { await cycleStatus() }
        .onAppear { UIAccessibility.post(notification: .announcement, argument: currentPhrase) }
        .onChange(of: currentPhrase) { _, new in
            UIAccessibility.post(notification: .announcement, argument: new)
        }
    }

    private func cycleStatus() async {
        guard !Motion.reduceMotion, !isLongRunning else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2.2))
            if Task.isCancelled { break }
            withAnimation(.easeInOut(duration: 0.4)) {
                statusIndex = (statusIndex + 1) % running.count
            }
        }
    }

    @ViewBuilder private var water: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let canvas = Canvas { ctx, size in
                drawWaves(&ctx, size, t: t)
                drawSurfaceSheen(&ctx, size, t: t)
                drawParticles(&ctx, size, t: t)
            }
            .ignoresSafeArea()

            if Config.useShaders {
                // Bound the time before narrowing to Float so the ripple stays
                // smooth (raw seconds-since-2001 would lose precision as Float).
                let shaderTime = Float(t.truncatingRemainder(dividingBy: 3600))
                canvas.distortionEffect(
                    ShaderLibrary.riverRipple(.float(shaderTime)),
                    maxSampleOffset: CGSize(width: 3, height: 0)
                )
            } else {
                canvas
            }
        }
    }

    // MARK: Waves

    private struct Wave {
        let amplitude: CGFloat
        let cycles: CGFloat      // full cycles across the width
        let period: Double       // seconds per drift cycle
        let midFraction: CGFloat // baseline as a fraction of height
        let opacity: CGFloat
    }

    private let waves = [
        Wave(amplitude: 14, cycles: 0.625, period: 20, midFraction: 0.56, opacity: 0.08),
        Wave(amplitude: 18, cycles: 0.833, period: 14, midFraction: 0.58, opacity: 0.10),
        Wave(amplitude: 26, cycles: 1.25,  period: 9,  midFraction: 0.62, opacity: 0.16),
    ]

    private func drawWaves(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double) {
        for wave in waves {
            let phase = 2 * .pi * (t.truncatingRemainder(dividingBy: wave.period) / wave.period)
            let pts = RiverShapes.points(
                width: size.width,
                midY: size.height * wave.midFraction,
                amplitude: wave.amplitude,
                wavelengths: wave.cycles,
                phase: phase
            )
            ctx.fill(RiverShapes.fillPath(pts, size: size),
                     with: .color(Color.canopy600.opacity(wave.opacity)))
        }
    }

    /// A specular glass rim on the frontmost wave, plus soft light glints
    /// drifting along it — the same glass language as the Welcome river.
    private func drawSurfaceSheen(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double) {
        let wave = waves[2]
        let phase = 2 * .pi * (t.truncatingRemainder(dividingBy: wave.period) / wave.period)
        let midY = size.height * wave.midFraction
        let pts = RiverShapes.points(width: size.width, midY: midY, amplitude: wave.amplitude,
                                     wavelengths: wave.cycles, phase: phase)
        let path = RiverShapes.smoothPath(pts)
        ctx.stroke(path, with: .color(Color.canopy600.opacity(0.28)),
                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        ctx.stroke(path.applying(.init(translationX: 0, y: -1)),
                   with: .color(.white.opacity(0.4)), style: StrokeStyle(lineWidth: 1, lineCap: .round))

        let glints: [(speed: Double, phase: Double, maxOpacity: Double)] = [
            (30, 0.0, 0.5), (46, 0.35, 0.4), (22, 0.7, 0.35),
        ]
        ctx.drawLayer { layer in
            layer.blendMode = .plusLighter
            layer.addFilter(.blur(radius: 4))
            for g in glints {
                let x = (t * g.speed + g.phase * Double(size.width)).truncatingRemainder(dividingBy: Double(size.width))
                let y = RiverShapes.y(atX: CGFloat(x), width: size.width, midY: midY,
                                      amplitude: wave.amplitude, wavelengths: wave.cycles, phase: phase)
                let twinkle = 0.5 + 0.5 * sin(t * 1.3 + g.phase * 6.28)
                let rect = CGRect(x: CGFloat(x) - 16, y: y - 3, width: 32, height: 6)
                layer.fill(Path(ellipseIn: rect), with: .color(.white.opacity(g.maxOpacity * twinkle)))
            }
        }
    }

    // MARK: Particles (fixed pool — no allocation of models in the draw loop)

    private struct Particle {
        let xFraction: CGFloat
        let width: CGFloat
        let speed: CGFloat
        let phase: CGFloat
    }

    private static let particles: [Particle] = (0..<52).map { i in
        // Low-discrepancy (golden-ratio) spread — deterministic, no RNG needed.
        func frac(_ m: Double) -> CGFloat { CGFloat((Double(i) + 1) * m).truncatingRemainder(dividingBy: 1) }
        return Particle(
            xFraction: frac(0.61803),
            width: 2 + 6 * frac(0.75487),
            speed: 0.6 + 0.7 * frac(0.35112),
            phase: frac(0.12931)
        )
    }

    private func drawParticles(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double) {
        let startY = size.height * 0.10
        let waterline = size.height * 0.52
        for p in Self.particles {
            let raw = (t * Double(p.speed) * 0.35 + Double(p.phase)).truncatingRemainder(dividingBy: 1)
            let progress = CGFloat(raw)
            let eased = pow(progress, 1.4) // accelerate slightly on the way down
            let y = startY + (waterline - startY) * eased
            let x = p.xFraction * size.width
            let opacity = max(0, 1 - progress) * 0.6
            let rect = CGRect(x: x, y: y, width: p.width, height: 2)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 1),
                     with: .color(Color.canopy600.opacity(opacity)))
        }
    }
}

/// Reduce Motion stand-in: static three-band gradient + a gentle pulsing dot.
private struct ReducedRiver: View {
    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            let band = geo.size.height * 0.15 // three bands = lower 45%
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Rectangle().fill(Color.canopy600.opacity(0.08)).frame(height: band)
                Rectangle().fill(Color.canopy600.opacity(0.12)).frame(height: band)
                Rectangle().fill(Color.canopy600.opacity(0.16)).frame(height: band)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .overlay {
            Circle()
                .fill(Color.canopy600)
                .frame(width: 12, height: 12)
                .opacity(pulse ? 1 : 0.35)
                .offset(y: -40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview("River") {
    struct Harness: View {
        @State private var long = false
        var body: some View {
            ZStack {
                Color.canopyPaper.ignoresSafeArea()
                RiverCanvas(isLongRunning: long)
                VStack {
                    Toggle("Long running", isOn: $long).padding(Space.screen)
                    Spacer()
                }
            }
        }
    }
    return Harness()
}
