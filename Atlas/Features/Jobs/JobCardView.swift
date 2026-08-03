import SwiftUI
import UIKit

/// A match card that flips in 3D on tap: front shows the role + fit + actions,
/// back shows everything about the company. Pass / Accept live on the front.
struct JobCardView: View {
    let match: JobMatch
    var onPass: () -> Void
    var onAccept: () -> Void

    @State private var flipped = false
    private let faceHeight: CGFloat = 250

    var body: some View {
        ZStack {
            front.opacity(flipped ? 0 : 1)
            back
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: flipped)
    }

    private func flip() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
        flipped.toggle()
    }

    // MARK: Front

    private var front: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tapping the info area flips the card; buttons keep their own taps.
            VStack(alignment: .leading, spacing: Space.m) {
                HStack(alignment: .top, spacing: Space.m) {
                    companyWell
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.role).atlasText(.bodyStrong).foregroundStyle(Palette.ink)
                        Text("\(match.company) · \(match.location)")
                            .atlasText(.caption).foregroundStyle(Palette.inkSecondary)
                    }
                    Spacer(minLength: Space.s)
                    matchBadge
                }
                if !match.tags.isEmpty {
                    FlowLayout(spacing: Space.s) {
                        ForEach(match.tags, id: \.self) { ChipView(text: $0) }
                    }
                }
                if let salary = match.salary {
                    HStack(spacing: 5) {
                        Image(systemName: "banknote").font(.system(size: 12))
                        Text(salary).atlasText(.caption)
                    }
                    .foregroundStyle(Palette.inkTertiary)
                }
                HStack(spacing: 5) {
                    Text("Tap for company").atlasText(.meta)
                    Image(systemName: "arrow.right").font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(Palette.inkTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { flip() }

            Spacer(minLength: Space.m)

            HStack(spacing: Space.m) {
                AtlasButton("Pass", kind: .secondary) { onPass() }
                AtlasButton("Accept") { onAccept() }
            }
        }
        .frame(height: faceHeight, alignment: .top)
        .cardSurface()
    }

    // MARK: Back

    private var back: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            HStack(alignment: .top, spacing: Space.m) {
                companyWell
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.company).atlasText(.title).foregroundStyle(Palette.ink)
                    Text("\(match.industry) · \(match.size) · \(match.stage)")
                        .atlasText(.caption).foregroundStyle(Palette.inkSecondary)
                }
                Spacer(minLength: Space.s)
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }

            Text(match.about)
                .atlasText(.caption).foregroundStyle(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Eyebrow("WHY IT FITS")
                ForEach(match.reasons.prefix(3), id: \.self) { reason in
                    HStack(alignment: .top, spacing: Space.s) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12)).foregroundStyle(Palette.blue)
                            .padding(.top, 1)
                        Text(reason).atlasText(.caption).foregroundStyle(Palette.ink)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(height: faceHeight, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture { flip() }
        .cardSurface()
    }

    // MARK: Bits

    private var companyWell: some View {
        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
            .fill(Palette.blueTint)
            .frame(width: 40, height: 40)
            .overlay(
                Text(String(match.company.prefix(1)))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.blue)
            )
    }

    private var matchBadge: some View {
        Text("\(match.match)% match")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Palette.blue)
            .padding(.vertical, 5)
            .padding(.horizontal, 9)
            .background(Capsule().fill(Palette.blueTint))
    }
}

private extension View {
    /// The card face surface — padded frosted glass, matching AtlasCard.
    func cardSurface() -> some View {
        padding(Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassSurface(Radius.card, tint: .white.opacity(0.55))
    }
}
