import SwiftUI
import UIKit

/// S02 · What brings you here — the intent split. Two individual paths (exploring
/// roles vs. joining through a company); employers are pointed to the web. Styled
/// to match the Ink & Brass system: warm paper, one filled ink card, one paper
/// card, a quiet concentric "light through the canopy" motif.
struct ChooseIntentView: View {
    var onExplore: () -> Void
    var onJoinCompany: () -> Void
    var onBack: (() -> Void)? = nil

    @State private var appeared = false
    private let margin: CGFloat = 26

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.canopyPaper.ignoresSafeArea()
            ringMotif.allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                header

                Text("Welcome to\nCanopy.")
                    .atlasText(.displayLarge)
                    .foregroundStyle(Color.canopy900)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 28)

                Text("Your working life, carried forward.")
                    .atlasText(.body)
                    .foregroundStyle(Color.canopy600)
                    .padding(.top, 10)

                Text("What brings you here?")
                    .atlasText(.bodyStrong)
                    .foregroundStyle(Color.canopy900)
                    .padding(.top, 40)
                    .padding(.bottom, 14)

                intentCard(
                    icon: "signpost.right.fill",
                    title: "I'm exploring my next move",
                    subtitle: "Find roles that fit your experience, priorities, and life.",
                    filled: true,
                    action: onExplore)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(reveal(0.05), value: appeared)

                intentCard(
                    icon: "building.2.fill",
                    title: "I'm joining through my company",
                    subtitle: "Access your company profile, team, and internal opportunities.",
                    filled: false,
                    action: onJoinCompany)
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(reveal(0.12), value: appeared)

                Spacer(minLength: Space.l)
                footer
            }
            .padding(.horizontal, margin)
            .padding(.top, Space.s)
            .padding(.bottom, 20)
        }
        .onAppear { appeared = true }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.canopy900)
                        .frame(width: 32, height: 44, alignment: .leading)
                }
                .accessibilityLabel("Back")
            }
            Text("canopy")
                .font(Typeface.display(21))
                .tracking(4.5)
                .foregroundStyle(Color.canopy800)
            Spacer()
        }
    }

    // MARK: Cards

    private func intentCard(icon: String, title: String, subtitle: String,
                            filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
            action()
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(filled ? Color.canopy600 : Color.canopyMist)
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: icon)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(filled ? Color.canopyPaper : Color.canopy600))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Typeface.body(17, weight: .medium))
                        .foregroundStyle(filled ? Color.canopyPaper : Color.canopy900)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(Typeface.body(14))
                        .foregroundStyle(filled ? Color.canopyPaper.opacity(0.72) : Color.canopy600)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(filled ? Color.canopyPaper.opacity(0.6) : Color.canopy400)
            }
            .multilineTextAlignment(.leading)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(filled ? Color.canopy800 : Color.canopyPaper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.canopyPaperLine, lineWidth: filled ? 0 : 1)
            )
        }
        .buttonStyle(PressCard())
    }

    private var footer: some View {
        HStack(spacing: 7) {
            Image(systemName: "building.columns")
                .font(.system(size: 12))
            Text("Hiring with Canopy? Visit Canopy for employers.")
                .font(Typeface.body(13))
        }
        .foregroundStyle(Color.canopy400)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(appeared ? 1 : 0)
        .animation(reveal(0.2), value: appeared)
    }

    // Quiet concentric rings, top-trailing — light through the canopy.
    private var ringMotif: some View {
        GeometryReader { geo in
            ZStack {
                Circle().strokeBorder(Color.canopyPaperLine, lineWidth: 1).frame(width: 150, height: 150)
                Circle().strokeBorder(Color.canopyPaperLine.opacity(0.6), lineWidth: 1).frame(width: 108, height: 108)
            }
            .position(x: geo.size.width - 34, y: 150)
        }
    }

    private func reveal(_ delay: Double) -> Animation {
        Motion.reduceMotion ? .easeOut(duration: 0.2).delay(delay)
                            : .spring(response: 0.55, dampingFraction: 0.9).delay(delay)
    }
}

/// Card press: a quiet scale + settle, no shadow.
private struct PressCard: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ChooseIntentView(onExplore: {}, onJoinCompany: {}, onBack: {})
}
