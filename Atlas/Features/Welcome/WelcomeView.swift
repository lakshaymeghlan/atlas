import SwiftUI

/// S01 · Welcome — editorial luxury layout. Warm off-white, a serif hero on the
/// left, a tone-on-tone white river flowing down the right with a paper boat, a
/// three-column Find·Join·Belong feature grid, and two white sign-in cards.
/// Light only.
struct WelcomeView: View {
    var onSignedIn: () -> Void

    @Environment(AuthStore.self) private var auth
    @State private var appeared = false

    private let margin: CGFloat = 24
    private var reduce: Bool { Motion.reduceMotion }

    // Palette (light only)
    private let bg = Color(hex: "F3F2EF")
    private let ink = Color(hex: "1A1A1C")
    private let inkSecondary = Color(hex: "6B6B70")
    private let inkTertiary = Color(hex: "9A9A9F")
    private let wellBg = Color(hex: "EAE9E5")
    private let iconTint = Color(hex: "3C3C40")
    private let cardBorder = Color(hex: "ECEBE7")

    private let features: [(String, String, String)] = [
        ("magnifyingglass", "Find", "Discover roles\nthat fit you."),
        ("briefcase", "Join", "Navigate hiring\nwith confidence."),
        ("person.2", "Belong", "Build meaningful\nconnections."),
    ]

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            WhiteRibbon(background: bg).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0), value: appeared)

                Spacer().frame(height: 78)

                hero
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 14))
                    .animation(reveal(0.06), value: appeared)

                supporting
                    .padding(.top, 22)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 14))
                    .animation(reveal(0.12), value: appeared)

                featureGrid
                    .padding(.top, 34)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 14))
                    .animation(reveal(0.18), value: appeared)

                Spacer(minLength: 34)

                buttons
                footer.padding(.top, 18)
            }
            .padding(.horizontal, margin)
            .padding(.top, Space.s)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear { appeared = true }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("ATLAS")
                .font(.system(size: 15, weight: .semibold))
                .tracking(9)
                .foregroundStyle(ink)
            Spacer()
            Image(systemName: "sun.max")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(.white))
                .overlay(Circle().strokeBorder(cardBorder, lineWidth: 1))
                .accessibilityHidden(true)
        }
    }

    // MARK: Hero + support

    private var hero: some View {
        Text("Your career,\nwithout\nthe chaos.")
            .font(.system(size: 46, weight: .medium, design: .serif))
            .foregroundStyle(ink)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var supporting: some View {
        Text("Atlas learns your story and connects you to work that actually fits.")
            .font(.system(size: 17, weight: .regular))
            .lineSpacing(5)
            .foregroundStyle(inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 250, alignment: .leading)
    }

    // MARK: Feature grid

    private var featureGrid: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(features, id: \.1) { symbol, title, desc in
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(wellBg)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: symbol)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(iconTint)
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ink)
                        Text(desc)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(inkSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Buttons

    private var buttons: some View {
        VStack(spacing: 16) {
            authButton(.linkedIn, "Continue with LinkedIn")
                .opacity(appeared ? 1 : 0)
                .offset(y: rise(appeared ? 0 : 26))
                .animation(reveal(0.24), value: appeared)
            authButton(.github, "Continue with GitHub")
                .opacity(appeared ? 1 : 0)
                .offset(y: rise(appeared ? 0 : 26))
                .animation(reveal(0.3), value: appeared)
        }
    }

    private func authButton(_ mark: BrandMark, _ title: String) -> some View {
        Button {
            signIn(mark == .linkedIn ? .linkedIn : .github)
        } label: {
            HStack(spacing: 16) {
                BrandMarkView(mark: mark, size: 30, monoColor: ink)
                Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(ink)
                Spacer(minLength: 8)
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(ink.opacity(0.85))
            }
        }
        .buttonStyle(CardButtonStyle(border: cardBorder))
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
        .foregroundStyle(inkTertiary)
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
               : .spring(response: 0.6, dampingFraction: 0.9).delay(delay)
    }
}

// MARK: - White card button

private struct CardButtonStyle: ButtonStyle {
    let border: Color

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 18)
            .background(shape.fill(.white))
            .overlay(shape.strokeBorder(border, lineWidth: 1))
            .clipShape(shape)
            .shadow(color: .black.opacity(pressed ? 0.03 : 0.06),
                    radius: pressed ? 5 : 12, x: 0, y: pressed ? 2 : 6)
            .scaleEffect(pressed ? 0.99 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
    }
}

#Preview {
    WelcomeView(onSignedIn: {})
        .environment(AuthStore())
}
