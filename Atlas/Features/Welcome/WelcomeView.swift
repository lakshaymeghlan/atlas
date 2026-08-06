import SwiftUI
import UIKit

/// S01 · Welcome — the journey, as a flowing ocean river. A wordmark, a living
/// blue current threading three waypoints (Begin · Prepare · Find), one editorial
/// headline, and a single obvious next step: begin with your CV.
struct WelcomeView: View {
    var onBegin: () -> Void

    @State private var appeared = false
    private let margin: CGFloat = 26
    private var reduce: Bool { Motion.reduceMotion }

    var body: some View {
        ZStack {
            Ocean.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0), value: appeared)

                Text("c a n o p y")
                    .font(Typeface.display(21))
                    .tracking(2)
                    .foregroundStyle(Ocean.deep)
                    .padding(.top, 2)
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0.05), value: appeared)

                RiverJourney(appeared: appeared)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("Your next move,\ncarried forward.")
                    .font(Typeface.display(30))
                    .tracking(-0.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Ocean.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 14))
                    .animation(reveal(0.18), value: appeared)

                Text("Canopy helps you see the path and\nmove through it with confidence.")
                    .font(.system(size: 15.5, weight: .regular))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Ocean.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 14))
                    .animation(reveal(0.24), value: appeared)

                beginButton
                    .padding(.top, 26)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 22))
                    .animation(reveal(0.30), value: appeared)

                Text("You remain in control at every step.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Ocean.inkTertiary)
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0.38), value: appeared)
            }
            .padding(.horizontal, margin)
            .padding(.bottom, 18)
        }
        .onAppear { appeared = true }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: begin) {
                Text("Skip")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Ocean.inkSecondary)
            }
        }
        .padding(.top, Space.s)
    }

    private var beginButton: some View {
        Button(action: begin) {
            Text("Begin with my CV")
                .font(.system(size: 17, weight: .semibold))
        }
        .buttonStyle(OceanButtonStyle())
    }

    private func begin() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
        onBegin()
    }

    private func rise(_ y: CGFloat) -> CGFloat { reduce ? 0 : y }
    private func reveal(_ delay: Double) -> Animation {
        reduce ? .easeOut(duration: 0.25).delay(delay)
               : .spring(response: 0.6, dampingFraction: 0.9).delay(delay)
    }
}

// MARK: - The river (draws itself in once, then rests)

/// A gently curving ocean current with a soft glow, two tributaries, and three
/// waypoints. On appear the river strokes itself in from source to mouth and the
/// waypoints surface as the water reaches them — a single opening flourish, then
/// everything holds still.
private struct RiverJourney: View {
    var appeared: Bool
    private var reduce: Bool { Motion.reduceMotion }

    @State private var draw: CGFloat = 0   // 0 → 1, the one opening animation

    // Waypoints as vertical fractions of the region.
    private let nodes: [(y: CGFloat, label: String, side: Side)] = [
        (0.30, "Begin", .right),
        (0.56, "Prepare", .left),
        (0.82, "Find", .right),
    ]
    private enum Side { case left, right }

    // Source above the first node, mouth below the last.
    private let top: CGFloat = 0.10
    private let bottom: CGFloat = 0.96

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // Soft glow band, revealed with the draw.
                RiverSpine(top: top, bottom: bottom)
                    .trim(from: 0, to: draw)
                    .stroke(Ocean.band.opacity(0.55),
                            style: StrokeStyle(lineWidth: 26, lineCap: .round))
                    .blur(radius: 12)

                // Tributaries fan up from the source once the head is drawn.
                Tributaries(headY: top)
                    .stroke(Ocean.mid.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                    .opacity(Double(tribProgress))

                // The river line — aqua at the source, deep at the mouth.
                RiverSpine(top: top, bottom: bottom)
                    .trim(from: 0, to: draw)
                    .stroke(
                        LinearGradient(colors: [Ocean.aqua, Ocean.mid, Ocean.deep],
                                       startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 2.8, lineCap: .round))

                // Journey icons — fade + settle in, then still.
                journeyIcon("house", x: w * 0.24, y: h * 0.30, order: 0)
                journeyIcon("mappin.and.ellipse", x: w * 0.75, y: h * 0.55, order: 1)
                journeyIcon("briefcase", x: w * 0.24, y: h * 0.80, order: 2)

                // Waypoint nodes + labels — surface as the water reaches them.
                ForEach(Array(nodes.enumerated()), id: \.offset) { i, node in
                    let p = CGPoint(x: spineX(node.y, width: w), y: node.y * h)
                    let reached = draw >= node.y - 0.02
                    nodeDot(active: i == 0)
                        .scaleEffect(reached ? 1 : 0.1)
                        .opacity(reached ? 1 : 0)
                        .position(p)
                        .animation(.spring(response: 0.45, dampingFraction: 0.68), value: reached)
                    Text(node.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Ocean.inkSecondary)
                        .position(x: p.x + (node.side == .right ? 46 : -46), y: p.y)
                        .opacity(reached ? 1 : 0)
                        .animation(.easeOut(duration: 0.35), value: reached)
                }
            }
            .onAppear {
                guard draw == 0 else { return }
                if reduce { draw = 1 }
                else { withAnimation(.easeInOut(duration: 1.25)) { draw = 1 } }
            }
        }
    }

    // Tributaries start drawing once the spine passes the source.
    private var tribProgress: CGFloat { max(0, min(1, (draw - top) / 0.35)) }

    // Same spine equation the RiverSpine shape uses — for node placement.
    private func spineX(_ yFrac: CGFloat, width: CGFloat) -> CGFloat {
        width * 0.5 + sin(yFrac * .pi * 2.1) * (width * 0.05)
    }

    private func nodeDot(active: Bool) -> some View {
        ZStack {
            Circle().fill(Ocean.paper).frame(width: 18, height: 18)
            Circle().strokeBorder(active ? Ocean.deep : Ocean.mid, lineWidth: active ? 3 : 2)
                .frame(width: 18, height: 18)
            if active { Circle().fill(Ocean.deep).frame(width: 7, height: 7) }
        }
        .shadow(color: Ocean.deep.opacity(0.20), radius: 4, y: 1)
    }

    private func journeyIcon(_ name: String, x: CGFloat, y: CGFloat, order: Int) -> some View {
        Image(systemName: name)
            .font(.system(size: 22, weight: .regular))
            .foregroundStyle(Ocean.mid.opacity(0.85))
            .position(x: x, y: y)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.easeOut(duration: 0.5).delay(0.55 + Double(order) * 0.18), value: appeared)
    }
}

/// The river spine: a gentle sine curve down the region. Trimmable so it can
/// stroke itself in.
private struct RiverSpine: Shape {
    var top: CGFloat
    var bottom: CGFloat
    func path(in rect: CGRect) -> Path {
        Path { p in
            var first = true
            var y = rect.height * top
            let end = rect.height * bottom
            while y <= end {
                let x = rect.width * 0.5 + sin((y / rect.height) * .pi * 2.1) * (rect.width * 0.05)
                let pt = CGPoint(x: x, y: y)
                if first { p.move(to: pt); first = false } else { p.addLine(to: pt) }
                y += 2
            }
        }
    }
}

/// Two tributaries fanning up and out from the source point.
private struct Tributaries: Shape {
    var headY: CGFloat
    func path(in rect: CGRect) -> Path {
        let head = CGPoint(
            x: rect.width * 0.5 + sin(headY * .pi * 2.1) * (rect.width * 0.05),
            y: rect.height * headY)
        return Path { p in
            for dir in [-1.0, 1.0] as [CGFloat] {
                p.move(to: head)
                p.addQuadCurve(
                    to: CGPoint(x: head.x + dir * rect.width * 0.46, y: rect.height * 0.02),
                    control: CGPoint(x: head.x + dir * rect.width * 0.22, y: rect.height * 0.06))
            }
        }
    }
}

// MARK: - Ocean palette + button (Welcome-local, cool & happy)

private enum Ocean {
    static let paper = Color(hex: "F3FAFB")
    static let ink = Color(hex: "0C2A31")
    static let inkSecondary = Color(hex: "4E6B72")
    static let inkTertiary = Color(hex: "8AA4AB")
    static let deep = Color(hex: "0C6B7A")
    static let mid = Color(hex: "1E90A8")
    static let aqua = Color(hex: "35B7CE")
    static let foam = Color(hex: "BEF0F7")
    static let band = Color(hex: "8FD9E6")
}

/// Solid ocean button — deep teal fill, soft lift, quiet spring press.
private struct OceanButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(shape.fill(pressed ? Ocean.deep.opacity(0.9) : Ocean.deep))
            .shadow(color: Ocean.deep.opacity(pressed ? 0.15 : 0.28), radius: pressed ? 5 : 14, x: 0, y: pressed ? 2 : 7)
            .scaleEffect(pressed ? 0.985 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: pressed)
    }
}

#Preview {
    WelcomeView(onBegin: {})
}
