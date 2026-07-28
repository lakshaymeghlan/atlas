import SwiftUI

/// S01 · Welcome — premium editorial onboarding. Warm ivory with a whisper of a
/// radial glow; a wordmark + theme toggle; a Find·Join·Belong rail over a
/// silk-flow river with a drifting paper boat; a large left-aligned hero, a
/// reassurance pill, two glass sign-in buttons, and a locked footer. Everything
/// breathes; everything eases in.
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

                Spacer().frame(height: 22)

                Group {
                    stageLabels.padding(.horizontal, margin)
                    RiverBand(tint: theme.river, isDark: isDark, nodeInset: margin)
                }
                .opacity(appeared ? 1 : 0)
                .animation(reveal(0.06), value: appeared)

                Spacer().frame(height: 26)

                hero
                    .padding(.horizontal, margin)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 16))
                    .animation(reveal(0.1), value: appeared)

                supporting
                    .padding(.horizontal, margin)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 16))
                    .animation(reveal(0.15), value: appeared)

                badge
                    .padding(.horizontal, margin)
                    .padding(.top, 18)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 16))
                    .animation(reveal(0.2), value: appeared)

                Spacer(minLength: 24)

                buttons.padding(.horizontal, margin)

                footer
                    .padding(.horizontal, margin)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0.36), value: appeared)
            }
            .padding(.bottom, 14)
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
                    isDark ? theme.river.opacity(0.07) : .white.opacity(0.5),
                    .clear,
                ]),
                center: UnitPoint(x: 0.5, y: 0.16),
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
                .font(.system(size: 15, weight: .semibold))
                .tracking(9)
                .foregroundStyle(theme.ink)
            Spacer()
            themeToggle
        }
    }

    private var themeToggle: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { isDark.toggle() }
        } label: {
            Image(systemName: isDark ? "moon.stars" : "sun.max")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(theme.ink)
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(theme.hairline, lineWidth: 1))
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(isDark ? "Switch to light appearance" : "Switch to dark appearance")
    }

    // MARK: Stage labels (aligned over the river's ring nodes)

    private var stageLabels: some View {
        HStack(spacing: 0) {
            ForEach(["Find", "Join", "Belong"], id: \.self) { title in
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(theme.ink.opacity(0.72))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Hero

    private var hero: some View {
        Text("Your career,\nwithout\nthe chaos.")
            .font(.system(size: 40, weight: .semibold))
            .tracking(-0.6)
            .lineSpacing(-1)
            .foregroundStyle(theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var supporting: some View {
        Text("Atlas learns your story and connects you to work that actually fits.")
            .font(.system(size: 17, weight: .regular))
            .lineSpacing(6)
            .foregroundStyle(theme.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 260, alignment: .leading)
    }

    private var badge: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.river)
            Text("No forms. No endless applications. Just forward.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(theme.inkSecondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.hairline, lineWidth: 1))
    }

    // MARK: Buttons

    private var buttons: some View {
        VStack(spacing: 14) {
            authButton(.linkedIn, "Continue with LinkedIn")
                .opacity(appeared ? 1 : 0)
                .offset(y: rise(appeared ? 0 : 30))
                .animation(reveal(0.24), value: appeared)
            authButton(.github, "Continue with GitHub")
                .opacity(appeared ? 1 : 0)
                .offset(y: rise(appeared ? 0 : 30))
                .animation(reveal(0.3), value: appeared)
        }
    }

    private func authButton(_ mark: BrandMark, _ title: String) -> some View {
        Button {
            signIn(mark == .linkedIn ? .linkedIn : .github)
        } label: {
            HStack(spacing: 14) {
                BrandMarkView(mark: mark, size: 26, monoColor: theme.ink)
                Text(title).font(.system(size: 16, weight: .medium))
                Spacer(minLength: 8)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(theme.ink.opacity(0.55))
            }
        }
        .buttonStyle(GlassAuthButtonStyle(ink: theme.ink, hairline: theme.hairline))
        .disabled(auth.isAuthenticating)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock")
                .font(.system(size: 11, weight: .regular))
            Text("We only read what you approve.")
                .font(.system(size: 13, weight: .regular))
        }
        .foregroundStyle(theme.inkTertiary)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: Behaviour

    private func signIn(_ provider: AuthProvider) {
        Task {
            await auth.signIn(with: provider)
            if auth.isSignedIn { onSignedIn() }
        }
    }

    private func rise(_ y: CGFloat) -> CGFloat { reduce ? 0 : y }

    private func reveal(_ delay: Double) -> Animation {
        reduce ? .easeOut(duration: 0.25).delay(delay)
               : .spring(response: 0.62, dampingFraction: 0.86).delay(delay)
    }
}

// MARK: - Theme

/// Self-contained light/dark palette for the Welcome screen (the rest of the app
/// stays light in the prototype; this drives the on-screen theme toggle).
private struct WelcomeTheme {
    let isDark: Bool

    var paper: Color { isDark ? Color(hex: "1A1915") : Color(hex: "FCFBF8") }
    var ink: Color { isDark ? Color(hex: "F7F6F1") : Color(hex: "0C0C0D") }
    var inkSecondary: Color { isDark ? Color(hex: "AEACA4") : Color(hex: "5B5B60") }
    var inkTertiary: Color { isDark ? Color(hex: "78766E") : Color(hex: "9A9A9F") }
    var hairline: Color { isDark ? Color.white.opacity(0.14) : Color(hex: "E7E5E0") }
    var river: Color { Color(hex: "7A8FFF") }
    var colorScheme: ColorScheme { isDark ? .dark : .light }
}

// MARK: - Glass button

/// Glassmorphism sign-in button: 64pt tall, 18pt radius, frosted material with a
/// top sheen and specular rim, a soft shadow, and a spring press.
private struct GlassAuthButtonStyle: ButtonStyle {
    let ink: Color
    let hairline: Color

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        configuration.label
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 20)
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
                    LinearGradient(colors: [.white.opacity(0.55), hairline],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
            }
            .clipShape(shape)
            .shadow(color: .black.opacity(pressed ? 0.04 : 0.09),
                    radius: pressed ? 6 : 16, x: 0, y: pressed ? 3 : 9)
            .scaleEffect(pressed ? 0.985 : 1)
            .animation(.spring(response: 0.34, dampingFraction: 0.7), value: pressed)
    }
}

#Preview {
    WelcomeView(onSignedIn: {})
        .environment(AuthStore())
}
