import SwiftUI
import UIKit

/// A big, solid match card that flips in 3D on tap. Front shows the role, fit and
/// skills with a bookmark to save; back shows everything about the company. The
/// flip swaps faces at the 90° edge so the card is never transparent mid-turn.
struct JobCardView: View {
    let match: JobMatch
    @Binding var flipped: Bool
    var isSaved: Bool
    var onToggleSave: () -> Void

    var body: some View {
        ZStack {
            front.modifier(FlipFace(angle: flipped ? 180 : 0, back: false))
            back.modifier(FlipFace(angle: flipped ? 180 : 0, back: true))
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: flipped)
    }

    private func flip() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
        flipped.toggle()
    }

    // MARK: Front

    private var front: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            HStack(alignment: .top, spacing: Space.m) {
                companyWell(56)
                Spacer(minLength: Space.s)
                matchBadge
                saveButton
            }

            Spacer(minLength: Space.l)

            VStack(alignment: .leading, spacing: Space.s) {
                Text(match.role)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.canopy900)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(match.company) · \(match.location)")
                    .atlasText(.body).foregroundStyle(Color.canopy600)
            }

            FlowLayout(spacing: Space.s) {
                ForEach(match.tags, id: \.self) { ChipView(text: $0) }
            }

            if let salary = match.salary {
                HStack(spacing: 6) {
                    Image(systemName: "banknote").font(.system(size: 13))
                    Text(salary).atlasText(.body)
                }
                .foregroundStyle(Color.canopy600)
            }

            Spacer(minLength: Space.m)

            HStack(spacing: 5) {
                Text("Tap to see \(match.company)").atlasText(.meta)
                Image(systemName: "arrow.right").font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(Color.canopy400)
        }
        .cardFace(onTap: flip)
    }

    // MARK: Back

    private var back: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            HStack(alignment: .top, spacing: Space.m) {
                companyWell(56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(match.company).atlasText(.title).foregroundStyle(Color.canopy900)
                    Text("\(match.industry) · \(match.size) · \(match.stage)")
                        .atlasText(.caption).foregroundStyle(Color.canopy600)
                }
                Spacer(minLength: Space.s)
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.canopy400)
            }

            Text(match.about)
                .atlasText(.body).foregroundStyle(Color.canopy600)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: Space.s) {
                Eyebrow("WHY IT FITS")
                ForEach(match.reasons, id: \.self) { reason in
                    HStack(alignment: .top, spacing: Space.s) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14)).foregroundStyle(Color.canopy600)
                            .padding(.top, 1)
                        Text(reason).atlasText(.body).foregroundStyle(Color.canopy900)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                Image(systemName: "arrow.uturn.backward").font(.system(size: 9, weight: .semibold))
                Text("Tap to flip back").atlasText(.meta)
            }
            .foregroundStyle(Color.canopy400)
        }
        .cardFace(onTap: flip)
    }

    // MARK: Bits

    private func companyWell(_ size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            .fill(Color.canopyMist)
            .frame(width: size, height: size)
            .overlay(
                Text(String(match.company.prefix(1)))
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(Color.canopy600)
            )
    }

    private var matchBadge: some View {
        Text("\(match.match)% match")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.canopy600)
            .padding(.vertical, 6)
            .padding(.horizontal, 11)
            .background(Capsule().fill(Color.canopyMist))
    }

    private var saveButton: some View {
        Button(action: onToggleSave) {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSaved ? Color.canopy600 : Color.canopy600)
                .frame(width: 40, height: 40)
                .background(Circle().fill(isSaved ? Color.canopyMist : Color.canopyMist))
        }
        .accessibilityLabel(isSaved ? "Saved" : "Save job")
    }
}

/// Animatable flip: rotates the face and shows it only on its own half of the
/// turn, so exactly one opaque face is visible at a time.
private struct FlipFace: ViewModifier, Animatable {
    var angle: Double
    let back: Bool

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        let visible = back ? angle >= 90 : angle < 90
        return content
            .opacity(visible ? 1 : 0)
            .rotation3DEffect(.degrees(back ? angle - 180 : angle),
                              axis: (x: 0, y: 1, z: 0), perspective: 0.35)
    }
}

private extension View {
    /// A full-bleed, solid (opaque) card face.
    func cardFace(onTap: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous)
        return padding(Space.screen)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(shape.fill(.white))
            .overlay(shape.strokeBorder(Color.canopyPaperLine.opacity(0.7), lineWidth: 1))
            .clipShape(shape)
            .shadow(color: Color.canopy900.opacity(0.07), radius: 18, x: 0, y: 10)
            .contentShape(shape)
            .onTapGesture(perform: onTap)
    }
}
