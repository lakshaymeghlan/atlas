import SwiftUI

/// A soft, atmospheric sky for the top of the Welcome screen: a warm sunrise
/// glow with gentle clouds that drift slowly and dissolve into the ivory. Kept
/// low-contrast and blurred so it reads as light and weather, not clip-art.
/// Reduce Motion → still.
struct SkyBackdrop: View {
    var height: CGFloat = 440
    /// Scales the whole sky down for inner screens (0…1).
    var intensity: CGFloat = 1
    /// How many clouds to draw (inner screens use fewer).
    var maxClouds: Int = 4

    // (yFraction, scale, seconds per screen, phase 0…1, opacity)
    private let clouds: [(CGFloat, CGFloat, Double, CGFloat, CGFloat)] = [
        (0.30, 50, 90, 0.05, 1.0),
        (0.46, 38, 130, 0.5, 0.95),
        (0.22, 32, 70, 0.72, 0.9),
        (0.56, 28, 160, 0.28, 0.82),
    ]
    private let sun = Color(hex: "AEE4F0")
    private let sunCore = Color(hex: "E6F7FB")

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
        .frame(height: height)
        .frame(maxWidth: .infinity)
        // Dissolve into the ivory toward the bottom so it blends seamlessly.
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.5),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: inout GraphicsContext, _ size: CGSize, t: Double, animate: Bool) {
        guard size.width > 1 else { return }
        let rect = Path(CGRect(origin: .zero, size: size))
        let sunCenter = CGPoint(x: size.width * 0.72, y: size.height * 0.30)

        let k = intensity
        // Warm sky wash from the top — gives the clouds something to sit against.
        ctx.fill(
            rect,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "C6EAF3").opacity(0.7 * k),
                                  Color(hex: "DFF3F8").opacity(0.28 * k), .clear]),
                startPoint: CGPoint(x: size.width / 2, y: 0),
                endPoint: CGPoint(x: size.width / 2, y: size.height * 0.82)
            )
        )
        // Warm sun glow.
        ctx.fill(
            rect,
            with: .radialGradient(
                Gradient(colors: [sun.opacity(0.62 * k), sun.opacity(0.24 * k), .clear]),
                center: sunCenter, startRadius: 4, endRadius: size.height * 0.85
            )
        )
        // A soft sun disc with a brighter core.
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 8))
            layer.fill(disc(sunCenter, 32), with: .color(sunCore.opacity(0.9 * k)))
            layer.fill(disc(sunCenter, 17), with: .color(.white.opacity(0.55 * k)))
        }

        // Gentle clouds — softly blurred so they read as clouds, not blobs.
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 7))
            for (yFrac, scale, period, phase, op) in clouds.prefix(maxClouds) {
                let margin = scale * 3
                let span = Double(size.width + margin * 2)
                let base = Double(phase) * span
                let offset = animate ? (t / period * span + base) : base
                let x = -Double(margin) + offset.truncatingRemainder(dividingBy: span)
                cloud(&layer, at: CGPoint(x: CGFloat(x), y: size.height * yFrac),
                      scale: scale, opacity: op * k)
            }
        }
    }

    private func cloud(_ ctx: inout GraphicsContext, at p: CGPoint, scale s: CGFloat, opacity: CGFloat) {
        let blobs: [(CGFloat, CGFloat, CGFloat)] = [
            (-1.15, 0.16, 0.55), (-0.4, -0.14, 0.82), (0.45, -0.06, 0.66),
            (1.15, 0.18, 0.5), (0.05, 0.24, 0.78),
        ]
        for (dx, dy, r) in blobs {
            let radius = r * s
            let rect = CGRect(x: p.x + dx * s - radius, y: p.y + dy * s - radius,
                              width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
        }
    }

    private func disc(_ p: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
}

extension View {
    /// Ivory background with the warm sky at the top — the shared Atlas surface.
    func atlasSky(height: CGFloat = 440, intensity: CGFloat = 1, maxClouds: Int = 4) -> some View {
        background(
            ZStack(alignment: .top) {
                Palette.paper
                SkyBackdrop(height: height, intensity: intensity, maxClouds: maxClouds)
                    .ignoresSafeArea(edges: .top)
            }
            .ignoresSafeArea()
        )
    }
}

#Preview {
    ZStack(alignment: .top) {
        Color(hex: "FCFBF8").ignoresSafeArea()
        SkyBackdrop()
    }
}
