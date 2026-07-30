import SwiftUI

/// Shared layout for the three onboarding stages: the `Current` river under a
/// (optional) back nav, scrolling content, and a bottom-pinned action slot.
struct OnboardingScaffold<Content: View, Bottom: View>: View {
    let stageIndex: Int
    var onBack: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content
    @ViewBuilder var bottom: () -> Bottom

    var body: some View {
        VStack(spacing: 0) {
            navBar
            StageProgress(current: stageIndex, count: Journey.stageTitles.count)
                .padding(.horizontal, Space.screen)
                .padding(.bottom, Space.l)

            ScrollView {
                VStack(alignment: .leading, spacing: Space.block) {
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Space.screen)
                .padding(.bottom, Space.block)
            }

            bottom()
                .padding(.horizontal, Space.screen)
                .padding(.top, Space.m)
                .padding(.bottom, Space.screen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .atlasSky(height: 240, intensity: 0.7, maxClouds: 3)
    }

    @ViewBuilder private var navBar: some View {
        HStack {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .accessibilityLabel("Back")
            }
            Spacer()
        }
        .frame(height: 44)
        .padding(.horizontal, Space.m)
    }
}

extension OnboardingScaffold where Bottom == EmptyView {
    init(stageIndex: Int, onBack: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.init(stageIndex: stageIndex, onBack: onBack, content: content, bottom: { EmptyView() })
    }
}

/// Minimal step indicator — a row of thin segments, filled up to the current
/// stage. Replaces the boat river with something quiet and clean.
struct StageProgress: View {
    let current: Int
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Palette.blue : Palette.border)
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: current)
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}
