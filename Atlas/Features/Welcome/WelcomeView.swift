import SwiftUI
import UIKit

/// S01 · Welcome — minimal and clean. A wordmark, one strong headline, one line
/// of support, two crisp sign-in buttons, and a quiet trust line. No
/// illustration, no chrome — just the value prop and the obvious next step.
struct WelcomeView: View {
    var onSignedIn: () -> Void

    @Environment(AuthStore.self) private var auth
    @State private var appeared = false

    private let margin: CGFloat = 26
    private var reduce: Bool { Motion.reduceMotion }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("ATLAS")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(9)
                    .foregroundStyle(WP.ink)
                    .padding(.top, Space.s)
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0), value: appeared)

                Spacer().frame(height: 208)

                Text("Your career,\nwithout\nthe chaos.")
                    .font(Typeface.display(44))
                    .tracking(-0.9)
                    .lineSpacing(-1)
                    .foregroundStyle(WP.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 14))
                    .animation(reveal(0.06), value: appeared)

                Text("Upload your CV once. Atlas builds your profile and connects you to work that fits.")
                    .font(.system(size: 17, weight: .regular))
                    .lineSpacing(6)
                    .foregroundStyle(WP.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.top, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 14))
                    .animation(reveal(0.12), value: appeared)

                Spacer(minLength: 40)

                authButton(.linkedIn, "Continue with LinkedIn")
                    .opacity(appeared ? 1 : 0)
                    .offset(y: rise(appeared ? 0 : 22))
                    .animation(reveal(0.22), value: appeared)

                footer
                    .padding(.top, 18)
                    .opacity(appeared ? 1 : 0)
                    .animation(reveal(0.34), value: appeared)
            }
            .padding(.horizontal, margin)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear { appeared = true }
    }

    private var background: some View {
        ZStack(alignment: .top) {
            WP.paper
            SkyBackdrop().ignoresSafeArea(edges: .top)
        }
    }

    private func authButton(_ mark: BrandMark, _ title: String) -> some View {
        Button {
            signIn(mark == .linkedIn ? .linkedIn : .github)
        } label: {
            HStack(spacing: 12) {
                BrandMarkView(mark: mark, size: 24, monoColor: WP.ink)
                Text(title).font(.system(size: 16, weight: .semibold))
            }
        }
        .buttonStyle(CleanButtonStyle())
        .disabled(auth.isAuthenticating)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock").font(.system(size: 11, weight: .regular))
            Text("We only read what you approve.").font(.system(size: 13, weight: .regular))
        }
        .foregroundStyle(WP.inkTertiary)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func signIn(_ provider: AuthProvider) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
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

// MARK: - Palette (Welcome, light)

private enum WP {
    static let paper = Color(hex: "FCFBF8")
    static let ink = Color(hex: "0C0C0D")
    static let inkSecondary = Color(hex: "5B5B60")
    static let inkTertiary = Color(hex: "9A9A9F")
    static let hairline = Color(hex: "E7E5E0")
    static let accent = Color(hex: "4F63F0")
    static let accentTint = Color(hex: "ECEEFE")
    static let chip = Color(hex: "F1EFEA")
}

// MARK: - Clean button

/// Crisp white button: hairline border, one soft shadow, centred logo + label,
/// a quiet spring press. No gloss — clean over clever.
private struct CleanButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        configuration.label
            .foregroundStyle(WP.ink)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(shape.fill(.white))
            .overlay(shape.strokeBorder(WP.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(pressed ? 0.03 : 0.05), radius: pressed ? 4 : 12, x: 0, y: pressed ? 2 : 6)
            .scaleEffect(pressed ? 0.985 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: pressed)
    }
}

#Preview {
    WelcomeView(onSignedIn: {})
        .environment(AuthStore())
}
