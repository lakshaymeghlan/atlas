import SwiftUI

/// S01 · Welcome — rebuilt as a premium, editorial onboarding screen. Warm ivory
/// with a whisper of a radial glow, a wordmark + theme toggle, a Find·Join·Belong
/// rail over a flowing river with a drifting paper boat, a large left-aligned
/// hero, and two glass sign-in buttons. Everything breathes; everything eases in.
struct WelcomeView: View {
    var onSignedIn: () -> Void

    @Environment(AuthStore.self) private var auth
    @State private var isDark = false
    @State private var appeared = false

    private let margin: CGFloat = 24
    private var theme: WelcomeTheme { WelcomeTheme(isDark: isDark) }
    private var reduce: Bool { Motion.reduceMotion }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, margin)
                    .padding(.top, Space.s)
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0), value: appeared)

                Spacer(minLength: 36)

                stageRail
                    .padding(.horizontal, margin + 4)
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0.04), value: appeared)

                RiverBand(tint: theme.river, isDark: isDark)
                    .padding(.top, 18)
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0.08), value: appeared)

                Spacer(minLength: 44)

                hero
                    .padding(.horizontal, margin)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 16))
                    .animation(reveal(0.1), value: appeared)

                supporting
                    .padding(.horizontal, margin)
                    .padding(.top, 22)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 16))
                    .animation(reveal(0.16), value: appeared)

                Spacer(minLength: 40)

                buttons
                    .padding(.horizontal, margin)

                footer
                    .padding(.horizontal, margin)
                    .padding(.top, 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0.34), value: appeared)
            }
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .environment(\.colorScheme, theme.colorScheme)
        .onAppear { appeared = true }
    }

    // MARK: Background

    private var background: some View {
        ZStack {
            theme.paper
            RadialGradient(
                gradient: Gradient(colors: [
                    isDark ? theme.river.opacity(0.07) : .white.opacity(0.55),
                    .clear,
                ]),
                center: UnitPoint(x: 0.5, y: 0.14),
                startRadius: 6,
                endRadius: 560
            )
        }
        .animation(.easeInOut(duration: 0.45), value: isDark)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("ATLAS")
                .font(.system(size: 14, weight: .semibold, design: .default))
                .tracking(3)
                .foregroundStyle(theme.ink)
            Spacer()
            themeToggle
        }
    }

    private var themeToggle: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { isDark.toggle() }
        } label: {
            Image(systemName: isDark ? "moon.stars.fill" : "sun.max.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.ink)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(theme.hairline, lineWidth: 1))
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(isDark ? "Switch to light appearance" : "Switch to dark appearance")
    }

    // MARK: Stage rail

    private var stageRail: some View {
        HStack(spacing: 12) {
            stageLabel("Find")
            connector
            stageLabel("Join")
            connector
            stageLabel("Belong")
        }
    }

    private func stageLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .tracking(0.6)
            .foregroundStyle(theme.inkTertiary)
            .fixedSize()
    }

    private var connector: some View {
        Rectangle()
            .fill(theme.hairline)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }

    // MARK: Hero

    private var hero: some View {
        Text("Your career,\nwithout\nthe chaos.")
            .font(.system(size: 54, weight: .bold, design: .default))
            .tracking(-1.4)
            .lineSpacing(-3)
            .foregroundStyle(theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.9)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var supporting: some View {
        Text("Atlas learns your story and connects you to work that actually fits.")
            .font(.system(size: 16, weight: .regular))
            .lineSpacing(8)
            .foregroundStyle(theme.inkSecondary)
            .frame(maxWidth: 300, alignment: .leading)
    }

    // MARK: Buttons

    private var buttons: some View {
        VStack(spacing: 14) {
            authButton(.linkedIn, "Continue with LinkedIn")
                .opacity(appeared ? 1 : 0)
                .offset(y: rise(appeared ? 0 : 30))
                .animation(reveal(0.22), value: appeared)
            authButton(.github, "Continue with GitHub")
                .opacity(appeared ? 1 : 0)
                .offset(y: rise(appeared ? 0 : 30))
                .animation(reveal(0.29), value: appeared)
        }
    }

    private func authButton(_ provider: AuthProvider, _ title: String) -> some View {
        Button {
            signIn(provider)
        } label: {
            HStack(spacing: 12) {
                authMark(provider)
                Text(title).font(.system(size: 17, weight: .semibold))
            }
        }
        .buttonStyle(GlassAuthButtonStyle(ink: theme.ink, hairline: theme.hairline))
        .disabled(auth.isAuthenticating)
    }

    @ViewBuilder private func authMark(_ provider: AuthProvider) -> some View {
        Group {
            switch provider {
            case .linkedIn: Text("in").font(.system(size: 17, weight: .heavy))
            case .github:
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .foregroundStyle(theme.ink)
        .frame(width: 22, height: 22)
    }

    // MARK: Footer

    private var footer: some View {
        Text("We only read what you approve.")
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(theme.inkTertiary)
    }

    // MARK: Behaviour

    private func signIn(_ provider: AuthProvider) {
        Task {
            await auth.signIn(with: provider)
            if auth.isSignedIn { onSignedIn() }
        }
    }

    /// Vertical rise offset for entrance — flattened under Reduce Motion.
    private func rise(_ y: CGFloat) -> CGFloat { reduce ? 0 : y }

    /// Staggered spring reveal (a quick fade under Reduce Motion).
    private func reveal(_ delay: Double) -> Animation {
        reduce ? .easeOut(duration: 0.25).delay(delay)
               : .spring(response: 0.62, dampingFraction: 0.86).delay(delay)
    }
}

// MARK: - Theme

/// A self-contained light/dark palette for the Welcome screen. The rest of the
/// app stays light in the prototype; this drives the on-screen theme toggle.
private struct WelcomeTheme {
    let isDark: Bool

    var paper: Color { isDark ? Color(hex: "1A1915") : Color(hex: "FCFBF8") }
    var ink: Color { isDark ? Color(hex: "F7F6F1") : Color(hex: "0C0C0D") }
    var inkSecondary: Color { isDark ? Color(hex: "AEACA4") : Color(hex: "6E6E73") }
    var inkTertiary: Color { isDark ? Color(hex: "78766E") : Color(hex: "9A9A9F") }
    var hairline: Color { isDark ? Color.white.opacity(0.14) : Color(hex: "E7E5E0") }
    var river: Color { Color(hex: "7A8FFF") }
    var colorScheme: ColorScheme { isDark ? .dark : .light }
}

// MARK: - Glass button

/// Glassmorphism sign-in button: 60pt tall, 18pt radius, frosted material with a
/// top sheen and specular rim, a soft shadow, and a spring press (scale + shadow
/// deflate). Hover isn't a touch concept — the press is the premium tactile beat.
private struct GlassAuthButtonStyle: ButtonStyle {
    let ink: Color
    let hairline: Color

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        configuration.label
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background {
                shape.fill(.ultraThinMaterial)
                    .overlay {
                        shape.fill(
                            LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0)],
                                           startPoint: .top, endPoint: .center)
                        )
                        .blendMode(.plusLighter)
                    }
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.6), hairline],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
            }
            .clipShape(shape)
            .shadow(color: .black.opacity(pressed ? 0.04 : 0.10),
                    radius: pressed ? 6 : 16, x: 0, y: pressed ? 3 : 9)
            .scaleEffect(pressed ? 0.975 : 1)
            .animation(.spring(response: 0.34, dampingFraction: 0.7), value: pressed)
    }
}

#Preview {
    WelcomeView(onSignedIn: {})
        .environment(AuthStore())
}
