import SwiftUI

/// S02 · Career path. Two cards; only "looking for a job" navigates in Phase 1.
/// The employed card stays legible but shows an inline "coming soon" note.
struct CareerPathView: View {
    var onChooseSeeking: () -> Void

    @State private var showComingSoon = false

    var body: some View {
        OnboardingScaffold(stageIndex: 0) {
            VStack(alignment: .leading, spacing: Space.l) {
                Eyebrow("CAREER PATH · 1 OF 3")
                Text("Where are you\nin your career\nright now?")
                    .atlasText(.display)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("We'll shape Atlas around what you need today. You can change this later.")
                    .atlasText(.body)
                    .foregroundStyle(Palette.inkSecondary)
            }

            VStack(alignment: .leading, spacing: Space.l) {
                seekingCard
                employedCard
                if showComingSoon {
                    Text("Coming soon — we're building this next.")
                        .atlasText(.caption)
                        .foregroundStyle(Palette.inkTertiary)
                        .transition(.opacity)
                }
            }
        }
    }

    private var seekingCard: some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: Space.m) {
                iconWell("magnifyingglass", fill: Palette.blueTint, tint: Palette.blue)
                Text("I'm looking for a job").atlasText(.title)
                Text("Discover roles matched to your experience, interests, and goals.")
                    .atlasText(.body)
                    .foregroundStyle(Palette.inkSecondary)
                AtlasButton("Find my next role →", action: onChooseSeeking)
                    .padding(.top, Space.xs)
            }
        }
    }

    private var employedCard: some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: Space.m) {
                iconWell("person.2", fill: Palette.chip, tint: Palette.inkSecondary)
                Text("I'm currently employed").atlasText(.title)
                Text("Find your company, meet colleagues, and discover professional communities.")
                    .atlasText(.body)
                    .foregroundStyle(Palette.inkSecondary)
                AtlasButton("Connect with my workplace →", kind: .secondary) {
                    withAnimation(Motion.standard(0.2)) { showComingSoon = true }
                }
                .padding(.top, Space.xs)
            }
        }
    }

    private func iconWell(_ symbol: String, fill: Color, tint: Color) -> some View {
        RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
            .fill(fill)
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(tint)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    CareerPathView(onChooseSeeking: {})
}
