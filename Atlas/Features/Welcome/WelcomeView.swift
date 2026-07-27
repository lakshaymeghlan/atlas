import SwiftUI

/// S01 · Welcome. No form, no splash — the app is simply already there. Content
/// fades up on cold start. Sign-in is stubbed (see AuthStore).
struct WelcomeView: View {
    var onSignedIn: () -> Void

    @Environment(AuthStore.self) private var auth
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("ATLAS")

            Spacer(minLength: Space.block)

            // The river appears once here, small and unlabelled, as a promise.
            Current(stageTitles: Journey.stageTitles, currentStage: 0)
                .frame(height: 44)
                .accessibilityHidden(true)
                .padding(.bottom, Space.block)

            Text("Your career,\nwithout\nthe chaos.")
                .atlasText(.displayLarge)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("Atlas learns your story and connects you to work that actually fits.")
                .atlasText(.body)
                .foregroundStyle(Palette.inkSecondary)
                .lineLimit(3)
                .padding(.top, Space.l)

            Spacer().frame(height: 40)

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
                Text("We only read what you approve.")
                    .atlasText(.caption)
                    .foregroundStyle(Palette.inkTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Space.xs)
            }
        }
        .padding(Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
