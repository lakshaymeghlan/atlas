import SwiftUI

/// S01 · Welcome. No form, no splash — the app is simply already there. The
/// river band bleeds edge to edge; everything else keeps the 20pt margin.
/// Content fades up on cold start. Sign-in is stubbed (see AuthStore).
struct WelcomeView: View {
    var onSignedIn: () -> Void

    @Environment(AuthStore.self) private var auth
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("ATLAS")
                .padding(.horizontal, Space.screen)
                .padding(.top, Space.screen)

            // The river previews the journey — full-bleed, no side margin.
            WelcomeRiver()
                .padding(.top, 28)

            Spacer(minLength: 40)

            VStack(alignment: .leading, spacing: 0) {
                Text("Your career,\nwithout\nthe chaos.")
                    .atlasText(.displayLarge)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Atlas learns your story and connects you to work that actually fits.")
                    .atlasText(.body)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineLimit(2)
                    .padding(.top, Space.l)
            }
            .padding(.horizontal, Space.screen)

            Spacer(minLength: 32)

            VStack(spacing: Space.m) {
                AtlasButton(title: "Continue with LinkedIn", kind: .secondary,
                            isEnabled: !auth.isAuthenticating,
                            leading: { ProviderMark(.linkedIn) }) {
                    signIn(.linkedIn)
                }
                AtlasButton(title: "Continue with GitHub", kind: .secondary,
                            isEnabled: !auth.isAuthenticating,
                            leading: { ProviderMark(.github) }) {
                    signIn(.github)
                }
            }
            .padding(.horizontal, Space.screen)

            Text("We only read what you approve.")
                .atlasText(.caption)
                .foregroundStyle(Palette.inkTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, Space.l)
                .padding(.horizontal, Space.screen)
        }
        .padding(.bottom, Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.paper)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || Motion.reduceMotion ? 0 : 8)
        .onAppear {
            withAnimation(Motion.enter(Motion.open)) { appeared = true }
        }
    }

    private func signIn(_ provider: AuthProvider) {
        Task {
            await auth.signIn(with: provider)
            if auth.isSignedIn { onSignedIn() }
        }
    }
}

#Preview {
    WelcomeView(onSignedIn: {})
        .environment(AuthStore())
}
