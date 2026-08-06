import SwiftUI

// MARK: - Geometry (shared by the shape and the node overlay)

/// The single source of the trunk curve. Both `CanopyTrunk` (the drawn line) and
/// the node overlay read this, so a node always sits exactly on the trunk.
func canopyTrunkX(yFraction y: CGFloat, width: CGFloat) -> CGFloat {
    width * 0.5 + sin(y * .pi * 1.6 - 0.3) * (width * 0.045)
}

/// A waypoint on the trunk. `side` is which side its label sits on.
struct CanopyNode {
    let yFraction: CGFloat
    let label: String
    let side: HorizontalEdge
}

enum CanopyPathStyle { case hero, rail }

private extension CGFloat {
    /// Clamp to 0…1 and drop NaN — safe for unit-point anchors during layout.
    var clampedUnit: CGFloat { isFinite ? Swift.max(0, Swift.min(1, self)) : 0.5 }
}

/// The trunk spans this vertical band of the region; the crown sits above it and
/// the line fades to clear before the bottom so a headline can follow. `trunkTop`
/// is set low enough that the crown's upward-reaching leaves stay inside the zone
/// (never colliding with the wordmark above it).
private let trunkTop: CGFloat = 0.22
private let trunkBottom: CGFloat = 0.98

// MARK: - Shapes

/// The trunk: a gentle vertical curve, trimmable so it can draw itself in.
struct CanopyTrunk: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            var first = true
            var y = rect.height * trunkTop
            let end = rect.height * trunkBottom
            while y <= end {
                let pt = CGPoint(x: canopyTrunkX(yFraction: y / rect.height, width: rect.width), y: y)
                if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
                y += 2
            }
        }
    }
}

/// A single leaf: a tapered almond with a center vein. Drawn as a fill plus a
/// hairline vein so it reads as a leaf, not a blob. Point it with `.rotationEffect`.
struct Leaf: View {
    var length: CGFloat = 26
    var fill: Color = .canopy400
    var opacity: Double = 1

    var body: some View {
        let w = length * 0.52
        ZStack {
            LeafShape()
                .fill(fill)
                .opacity(opacity)
            // center vein
            Path { p in
                p.move(to: CGPoint(x: w / 2, y: length))
                p.addLine(to: CGPoint(x: w / 2, y: 0))
            }
            .stroke(Color.canopyPaper.opacity(0.55 * opacity), lineWidth: max(0.6, length * 0.03))
        }
        .frame(width: w, height: length)
    }
}

/// The almond outline: two symmetric quadratic curves from base tip to top tip.
struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        return Path { p in
            p.move(to: CGPoint(x: w / 2, y: h))                 // base tip
            p.addQuadCurve(to: CGPoint(x: w / 2, y: 0),          // top tip
                           control: CGPoint(x: w * 1.05, y: h * 0.42))
            p.addQuadCurve(to: CGPoint(x: w / 2, y: h),
                           control: CGPoint(x: -w * 0.05, y: h * 0.42))
            p.closeSubpath()
        }
    }
}

// MARK: - The path illustration

/// The Canopy path — trunk, crown, and three waypoints. Navigation, not
/// decoration: `.hero` is the onboarding illustration; `.rail` is the same
/// geometry as a slim progress rail (nodes fill with `sun` as phases complete).
///
/// The view is a pure renderer of its inputs so the opening sequence can be
/// orchestrated from one timeline upstream:
///   • `trunkProgress` / `crownProgress` — 0…1 draw-in
///   • `nodesRevealed` — per-node pop (the spring gives the 1.08 overshoot)
///   • `completed` — nodes filled with `sun` (rail only)
struct CanopyPath: View {
    var style: CanopyPathStyle = .hero
    var trunkProgress: CGFloat = 1
    var crownProgress: CGFloat = 1
    var nodesRevealed: [Bool] = [true, true, true]
    var completed: Set<Int> = []

    /// The waypoints, alternating sides. Order is the journey order.
    static let nodes: [CanopyNode] = [
        CanopyNode(yFraction: 0.34, label: "Match", side: .trailing),
        CanopyNode(yFraction: 0.58, label: "Navigate", side: .leading),
        CanopyNode(yFraction: 0.80, label: "Belong", side: .trailing),
    ]

    /// Fraction of the *drawn* trunk length at which each node is reached — used
    /// upstream to schedule the node pops off the draw, no magic timestamps.
    static var nodeDrawFractions: [CGFloat] {
        nodes.map { ($0.yFraction - trunkTop) / (trunkBottom - trunkTop) }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                crown(w: w, h: h)

                // Soft mist glow behind the trunk.
                CanopyTrunk()
                    .trim(from: 0, to: trunkProgress)
                    .stroke(Color.canopyMist, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                    .blur(radius: 12)

                // The trunk line — canopy shade, fading to clear at the bottom.
                CanopyTrunk()
                    .trim(from: 0, to: trunkProgress)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .canopy600, location: 0),
                                .init(color: .canopy600, location: 0.62),
                                .init(color: .canopy600.opacity(0), location: 1),
                            ],
                            startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                // Waypoints.
                ForEach(Array(Self.nodes.enumerated()), id: \.offset) { i, node in
                    let p = CGPoint(x: canopyTrunkX(yFraction: node.yFraction, width: w),
                                    y: node.yFraction * h)
                    let revealed = i < nodesRevealed.count ? nodesRevealed[i] : true
                    nodeDot(index: i)
                        .scaleEffect(revealed ? 1 : 0.5)
                        .opacity(revealed ? 1 : 0)
                        .position(p)
                        .animation(.spring(response: 0.26, dampingFraction: 0.55), value: revealed)
                    Text(node.label)
                        .atlasText(.caption)
                        .foregroundStyle(Color.canopy600)
                        .fixedSize()
                        .position(x: p.x + (node.side == .trailing ? 52 : -52), y: p.y)
                        .opacity(revealed ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.06), value: revealed)
                }
            }
        }
    }

    // A node: mist fill, canopy stroke. Completed nodes fill with sun (rail).
    private func nodeDot(index: Int) -> some View {
        let done = completed.contains(index)
        return Circle()
            .fill(done ? Color.sun : Color.canopyMist)
            .frame(width: 18, height: 18)
            .overlay(Circle().strokeBorder(done ? Color.sun : Color.canopy600, lineWidth: 1.5))
    }

    // The crown: a few branches fanning up, with leaves clustered along them.
    private func crown(w: CGFloat, h: CGFloat) -> some View {
        let base = CGPoint(x: canopyTrunkX(yFraction: trunkTop, width: w), y: h * trunkTop)
        return ZStack {
            // Branches.
            ForEach(Array(Self.branches.enumerated()), id: \.offset) { _, b in
                Path { p in
                    p.move(to: base)
                    p.addQuadCurve(
                        to: CGPoint(x: base.x + b.dx * w, y: base.y + b.dy * h),
                        control: CGPoint(x: base.x + b.cx * w, y: base.y + b.cy * h))
                }
                .stroke(Color.canopy600.opacity(0.5), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
            // Foliage.
            ForEach(Array(Self.foliage.enumerated()), id: \.offset) { _, leaf in
                Leaf(length: leaf.len * min(w, 300) / 300, fill: leaf.shade, opacity: 0.9)
                    .rotationEffect(.degrees(leaf.rot))
                    .position(x: base.x + leaf.dx * w, y: base.y + leaf.dy * h)
            }
        }
        .scaleEffect(0.7 + 0.3 * crownProgress,
                     anchor: .init(x: (base.x / max(w, 1)).clampedUnit, y: (base.y / max(h, 1)).clampedUnit))
        .opacity(Double(crownProgress))
    }

    // Static crown layout (fractions of region size, relative to the trunk base).
    private struct Branch { let dx, dy, cx, cy: CGFloat }
    private static let branches: [Branch] = [
        Branch(dx: -0.34, dy: -0.10, cx: -0.16, cy: -0.02),
        Branch(dx: 0.34, dy: -0.10, cx: 0.16, cy: -0.02),
        Branch(dx: -0.16, dy: -0.13, cx: -0.06, cy: -0.05),
        Branch(dx: 0.16, dy: -0.13, cx: 0.06, cy: -0.05),
    ]
    private struct Foliage { let dx, dy, len, rot: CGFloat; let shade: Color }
    private static let foliage: [Foliage] = [
        Foliage(dx: -0.34, dy: -0.11, len: 30, rot: -40, shade: .canopy400),
        Foliage(dx: -0.20, dy: -0.15, len: 26, rot: -20, shade: .canopy600),
        Foliage(dx: -0.06, dy: -0.16, len: 30, rot: -6,  shade: .canopy400),
        Foliage(dx: 0.08,  dy: -0.16, len: 28, rot: 8,   shade: .canopy600),
        Foliage(dx: 0.22,  dy: -0.15, len: 26, rot: 22,  shade: .canopy400),
        Foliage(dx: 0.34,  dy: -0.11, len: 30, rot: 42,  shade: .canopy600),
        Foliage(dx: 0.0,   dy: -0.09, len: 24, rot: 0,   shade: .canopy200),
    ]
}

#Preview {
    CanopyPath()
        .frame(width: 320, height: 460)
        .padding()
        .background(Color.canopyPaper)
}
