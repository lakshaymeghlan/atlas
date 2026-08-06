import SwiftUI
import UIKit

/// Jobs tab — a one-at-a-time card deck. The top role fills the section; Pass or
/// Accept (buttons or swipe) advances to the next. Tap a card to flip it and see
/// the company; bookmark to save it to the Saved tab. When the deck empties, a
/// calm message explains that more roles arrive as Atlas learns your profile.
struct JobsView: View {
    @Environment(JobsStore.self) private var jobs

    @State private var accepting: JobMatch?
    @State private var drag: CGSize = .zero
    @State private var flipped = false
    @State private var busy = false

    var body: some View {
        VStack(spacing: 0) {
            header

            if jobs.matches.isEmpty {
                Spacer(); endState; Spacer()
            } else {
                deck.padding(.horizontal, Space.screen)
                buttons.padding(.top, Space.l).padding(.bottom, Space.s)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $accepting) { match in
            AcceptSheet(match: match) { _ in
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private var header: some View {
        HStack {
            Eyebrow("JOBS")
            Spacer()
            if !jobs.matches.isEmpty {
                Text("\(jobs.matches.count) to review").atlasText(.meta).foregroundStyle(Palette.inkTertiary)
            }
        }
        .padding(.horizontal, Space.screen)
        .padding(.top, Space.m)
        .padding(.bottom, Space.m)
    }

    // MARK: Deck

    private var deck: some View {
        ZStack {
            ForEach(Array(jobs.matches.prefix(2).enumerated()), id: \.element.id) { index, match in
                let isTop = index == 0
                JobCardView(
                    match: match,
                    flipped: isTop ? $flipped : .constant(false),
                    isSaved: jobs.isSaved(match.id),
                    onToggleSave: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { jobs.toggleSave(match) } }
                )
                .overlay { if isTop { stamps } }
                .scaleEffect(isTop ? 1 : 0.93)
                .offset(y: isTop ? 0 : 18)
                .offset(x: isTop ? drag.width : 0, y: isTop ? drag.height * 0.15 : 0)
                .rotationEffect(.degrees(isTop ? Double(drag.width / 18) : 0), anchor: .bottom)
                .opacity(isTop ? 1 : 0.55)
                .allowsHitTesting(isTop)
                .gesture(dragGesture)
                .zIndex(isTop ? 2 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stamps: some View {
        ZStack {
            stamp("PASS", color: Palette.error, angle: -14)
                .opacity(Double(max(0, -drag.width) / 90))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            stamp("ACCEPT", color: Palette.success, angle: 14)
                .opacity(Double(max(0, drag.width) / 90))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(Space.block)
        .allowsHitTesting(false)
    }

    private func stamp(_ text: String, color: Color, angle: Double) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .heavy)).tracking(1)
            .foregroundStyle(color)
            .padding(.vertical, 6).padding(.horizontal, 12)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color, lineWidth: 3))
            .rotationEffect(.degrees(angle))
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in if !busy { drag = value.translation } }
            .onEnded { value in
                guard !busy else { return }
                if value.translation.width < -110 { swipe(pass: true) }
                else if value.translation.width > 110 { swipe(pass: false) }
                else { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero } }
            }
    }

    private func swipe(pass: Bool) {
        guard !busy, let top = jobs.matches.first else { return }
        busy = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeIn(duration: 0.3)) {
            drag = CGSize(width: pass ? -760 : 760, height: drag.height)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if pass { jobs.reject(top.id) } else { jobs.accept(top.id, note: nil); accepting = top }
            drag = .zero
            flipped = false
            busy = false
        }
    }

    // MARK: Buttons

    private var buttons: some View {
        HStack(spacing: 40) {
            deckButton(icon: "xmark", label: "Pass", filled: false) { swipe(pass: true) }
            deckButton(icon: "checkmark", label: "Accept", filled: true) { swipe(pass: false) }
        }
        .disabled(busy)
        .frame(maxWidth: .infinity)
    }

    private func deckButton(icon: String, label: String, filled: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 7) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(filled ? .white : Palette.ink)
                    .frame(width: 66, height: 66)
                    .background(Circle().fill(filled ? Palette.ink : .white))
                    .overlay(Circle().strokeBorder(Palette.border, lineWidth: filled ? 0 : 1))
                    .shadow(color: filled ? Palette.ink.opacity(0.22) : .black.opacity(0.06),
                            radius: 14, x: 0, y: 7)
            }
            .buttonStyle(.plain)
            Text(label).atlasText(.meta).foregroundStyle(Palette.inkTertiary)
        }
        .accessibilityLabel(label)
    }

    // MARK: End state

    private var endState: some View {
        VStack(spacing: Space.m) {
            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Palette.blue)
            Text("That's everyone for now.")
                .atlasText(.title).foregroundStyle(Palette.ink)
            Text("Canopy keeps learning your profile. The moment new roles that fit open up, they'll appear here — and we'll let you know.")
                .atlasText(.body).foregroundStyle(Palette.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .padding(.horizontal, Space.screen)
    }
}

#Preview {
    JobsView().environment(JobsStore())
}
