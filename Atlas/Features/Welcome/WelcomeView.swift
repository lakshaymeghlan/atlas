import SwiftUI
import UIKit

/// S01 · Welcome — the Canopy path. One trunk drawn through a tree, three phases
/// as waypoints, light coming down through the leaves. The opening is a single
/// ~2.4s timeline: paper → wordmark → the path draws itself (nodes surfacing as
/// the draw reaches them) → one light shaft → a single fall of leaves → headline
/// → CTA. Every animation fires once and resolves. Tap anywhere to skip to the
/// end; Reduce Motion jumps straight there.
struct WelcomeView: View {
    var onBegin: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Opening-sequence state (all driven by one timeline).
    @State private var rootIn = false
    @State private var wordIn = false
    @State private var wordTracking: CGFloat = 9.9      // 0.45em @ 22 → settles to 0.24em (5.28)
    @State private var trunkProgress: CGFloat = 0
    @State private var crownProgress: CGFloat = 0
    @State private var nodesRevealed = [false, false, false]
    @State private var shaftActive = false
    @State private var leavesActive = false
    @State private var headlineIn = [false, false]
    @State private var ctaIn = false
    @State private var ctaBreath = false

    @State private var skipped = false
    @State private var timeline: Task<Void, Never>?
    @State private var pathSize: CGSize = .zero

    private let margin: CGFloat = 26
    private let wordSettled: CGFloat = 5.28

    private let ease = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.5)
    private func ease(_ d: Double) -> Animation { .timingCurve(0.22, 1, 0.36, 1, duration: d) }

    var body: some View {
        ZStack {
            Color.canopyPaper.ignoresSafeArea()

            VStack(spacing: 0) {
                wordmark.padding(.top, Space.l).padding(.bottom, 12).zIndex(1)

                ZStack {
                    CanopyPath(trunkProgress: trunkProgress,
                               crownProgress: crownProgress,
                               nodesRevealed: nodesRevealed,
                               active: 0)
                    if shaftActive, pathSize.height > 0 { LightShaft(area: pathSize) }
                    if leavesActive, pathSize.height > 0 { FallingLeaves(area: pathSize) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    GeometryReader { g in
                        Color.clear
                            .onAppear { pathSize = g.size }
                            .onChange(of: g.size) { _, newValue in pathSize = newValue }
                    }
                )

                headline.padding(.top, 4)
                subhead.padding(.top, 12)
                cta.padding(.top, 24)
                footer.padding(.top, 16)
            }
            .padding(.horizontal, margin)
            .padding(.bottom, 18)
        }
        .canopyGrain()
        .opacity(rootIn ? 1 : 0)
        .contentShape(Rectangle())
        .onTapGesture { skip() }
        .onAppear {
            guard timeline == nil else { return }
            timeline = Task { await runTimeline() }
        }
        .onDisappear { timeline?.cancel() }
    }

    // MARK: Pieces

    private var wordmark: some View {
        Text("canopy")
            .font(Typeface.display(22))
            .tracking(wordTracking)
            .foregroundStyle(Color.canopy800)
            .opacity(wordIn ? 1 : 0)
            .accessibilityAddTraits(.isHeader)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 0) {
            revealLine("See the whole path", shown: headlineIn[0])
            revealLine("before you take it.", shown: headlineIn[1])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func revealLine(_ text: String, shown: Bool) -> some View {
        Text(text)
            .atlasText(.displayLarge)
            .foregroundStyle(Color.canopy900)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(y: shown ? 0 : 46)
            .opacity(shown ? 1 : 0)
            .clipped()
    }

    private var subhead: some View {
        Text("Upload your CV once. Canopy finds roles that actually fit, walks you through every interview, and introduces you to your people once you land.")
            .atlasText(.body)
            .foregroundStyle(Color.canopy600.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(ctaIn ? 1 : 0)
    }

    private var cta: some View {
        Button(action: begin) {
            Text("Get started")
                .font(Typeface.body(17, weight: .medium))
        }
        .buttonStyle(CanopyCTAStyle())
        .scaleEffect(ctaBreath ? 1.008 : 1)
        .offset(y: ctaIn ? 0 : 12)
        .opacity(ctaIn ? 1 : 0)
    }

    private var footer: some View {
        Text("Your CV stays yours. Delete it anytime.")
            .font(Typeface.body(13))
            .foregroundStyle(Color.canopy400)
            .opacity(ctaIn ? 1 : 0)
    }

    // MARK: Actions

    private func begin() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
        onBegin()
    }

    private func skip() {
        guard !skipped, !allShown else { return }
        skipped = true
        timeline?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { showEndState() }
    }

    private var allShown: Bool { ctaIn && trunkProgress == 1 }

    private func showEndState() {
        rootIn = true; wordIn = true; wordTracking = wordSettled
        trunkProgress = 1; crownProgress = 1
        nodesRevealed = [true, true, true]
        headlineIn = [true, true]; ctaIn = true
    }

    // MARK: The one timeline

    @MainActor private func runTimeline() async {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.2)) { showEndState() }
            return
        }

        let drawStart = 300, drawDur = 1300
        var events: [(t: Int, run: () -> Void)] = [
            (0,   { withAnimation(.easeOut(duration: 0.4)) { rootIn = true } }),
            (100, { withAnimation(ease(0.7)) { wordIn = true; wordTracking = wordSettled } }),
            (drawStart, {
                withAnimation(ease(1.3)) { trunkProgress = 1 }
                withAnimation(ease(0.5)) { crownProgress = 1 }
            }),
            (1200, { withAnimation(.linear(duration: 0.01)) { shaftActive = true } }),
            (1400, { leavesActive = true }),
            (1600, { withAnimation(ease(0.6)) { headlineIn[0] = true } }),
            (1680, { withAnimation(ease(0.6)) { headlineIn[1] = true } }),
            (2000, { withAnimation(ease(0.5)) { ctaIn = true } }),
        ]
        // Node pops derived from the trunk geometry, not magic timestamps.
        for (i, frac) in CanopyPath.nodeDrawFractions.enumerated() {
            let t = drawStart + Int(frac * CGFloat(drawDur))
            events.append((t, {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.26, dampingFraction: 0.55)) { nodesRevealed[i] = true }
            }))
        }
        events.sort { $0.t < $1.t }

        do {
            var last = 0
            for e in events {
                if e.t > last { try await Task.sleep(for: .milliseconds(e.t - last)); last = e.t }
                e.run()
            }
            // CTA: exactly one slow breath, then stop.
            try await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeInOut(duration: 2)) { ctaBreath = true }
            try await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 2)) { ctaBreath = false }
        } catch {
            return // cancelled by skip — end state already applied
        }
    }
}

// MARK: - Primary CTA

/// Full-width canopy-shade CTA: 56pt, 18pt radius, paper label. No shadow (the
/// only motion it gets is the single breath applied by the caller).
private struct CanopyCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(Color.canopyPaper)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(pressed ? Color.canopy900 : Color.canopy800))
            .animation(.easeOut(duration: 0.15), value: pressed)
    }
}

// MARK: - Light shaft (one pass)

/// A vertical `sun-wash` band that sweeps down the trunk once — sun moving
/// through leaves. This is the only place amber appears on this screen. Rendered
/// only while active; plays its keyframes once on appear.
private struct LightShaft: View {
    let area: CGSize
    @State private var progress: CGFloat = 0   // 0 = above the frame → 1 = below it

    var body: some View {
        let h = max(1, area.height.isFinite ? area.height : 1)
        let w = max(1, area.width.isFinite ? area.width : 1)
        let bandH = h * 0.34
        let y = -bandH + progress * (h + 2 * bandH)          // sweeps top → bottom, once
        let op = 0.18 * (progress < 0.5 ? progress * 2 : (1 - progress) * 2)  // fade in then out

        Rectangle()
            .fill(LinearGradient(colors: [.clear, .sunWash, .clear],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 96, height: bandH)
            .blur(radius: 16)
            .opacity(Double(op))
            .position(x: w / 2, y: y)
            .frame(width: w, height: h)
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { withAnimation(.easeInOut(duration: 1.6)) { progress = 1 } }
    }
}

// MARK: - Falling leaves (one pass, then gone)

private struct FallingLeaves: View {
    // (xFraction, size, baseRotation, sway px, delay s, duration s)
    private let specs: [(x: CGFloat, size: CGFloat, rot: Double, sway: CGFloat, delay: Double, dur: Double)] = [
        (0.30, 20, -14, 22, 0.00, 2.4),
        (0.52, 16, 10, 30, 0.18, 2.7),
        (0.44, 22, -6, 18, 0.36, 2.3),
        (0.64, 15, 20, 26, 0.54, 2.8),
        (0.38, 18, 4, 24, 0.72, 2.5),
    ]
    let area: CGSize
    var body: some View {
        ZStack {
            ForEach(specs.indices, id: \.self) { i in
                FallingLeaf(spec: specs[i], area: area)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct FallingLeaf: View {
    let spec: (x: CGFloat, size: CGFloat, rot: Double, sway: CGFloat, delay: Double, dur: Double)
    let area: CGSize
    @State private var fall: CGFloat = 0

    var body: some View {
        Leaf(length: spec.size, fill: .canopy400, opacity: 1)
            .rotationEffect(.degrees(spec.rot + Double(fall) * 40))
            .opacity(0.12 * Double(min(1, (1 - fall) * 3)))
            .position(x: area.width * spec.x + sin(fall * .pi * 2) * spec.sway,
                      y: -24 + fall * (area.height + 48))
            .onAppear {
                withAnimation(.easeIn(duration: spec.dur).delay(spec.delay)) { fall = 1 }
            }
    }
}

#Preview {
    WelcomeView(onBegin: {})
}
