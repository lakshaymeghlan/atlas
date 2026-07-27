import SwiftUI
import UIKit

// MARK: - Colour

extension Color {
    /// Init from a 6-digit hex string ("#RRGGBB" or "RRGGBB").
    init(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let v = UInt64(s, radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// The full Atlas palette. These are the only colours in the app.
enum Palette {
    // Surface
    static let paper = Color(hex: "F5F4F0")
    static let card = Color(hex: "FFFFFF")
    static let border = Color(hex: "E7E5E0")
    static let chip = Color(hex: "F0EEE9")

    // Ink
    static let ink = Color(hex: "0C0C0D")
    static let inkSecondary = Color(hex: "6E6E73")
    static let inkTertiary = Color(hex: "9A9A9F")

    // Action — the only saturated colour in the app
    static let blue = Color(hex: "2F4FE8")
    static let bluePressed = Color(hex: "2440C4")
    static let blueTint = Color(hex: "E9EDFD")

    // Status — used almost never
    static let success = Color(hex: "2E7D5B")
    static let error = Color(hex: "C0392B")
}

// MARK: - Type

/// The three type roles: Display (headlines), Interface (SF Pro, body/UI),
/// Meta (SF Mono, uppercase eyebrows and measured numbers).
enum TextRole {
    case displayLarge, display, title, body, bodyStrong, caption, meta
}

extension TextRole {
    /// General Sans if the .otf is installed (see DECISIONS.md); SwiftUI falls
    /// back to SF Pro Display automatically when the custom font is absent.
    private static let displayFace = "GeneralSans-Bold"

    var font: Font {
        switch self {
        case .displayLarge: return .custom(Self.displayFace, size: 42).weight(.bold)
        case .display:      return .custom(Self.displayFace, size: 34).weight(.bold)
        case .title:        return .system(size: 20, weight: .semibold)
        case .body:         return .system(size: 15, weight: .regular)
        case .bodyStrong:   return .system(size: 15, weight: .semibold)
        case .caption:      return .system(size: 13, weight: .regular)
        case .meta:         return .system(size: 11, weight: .medium, design: .monospaced)
        }
    }

    /// Letter spacing in points (converted from the em values in the spec).
    var tracking: CGFloat {
        switch self {
        case .displayLarge: return -1.26 // -0.03em @ 42
        case .display:      return -1.02 // -0.03em @ 34
        case .meta:         return 1.98  // +0.18em @ 11
        default:            return 0
        }
    }

    /// Additional spacing between lines (target line-height minus font size).
    var lineSpacing: CGFloat {
        switch self {
        case .displayLarge: return 2  // 44 line / 42
        case .display:      return 2  // 36 / 34
        case .title:        return 6  // 26 / 20
        case .body:         return 8  // 23 / 15
        case .bodyStrong:   return 8
        case .caption:      return 5  // 18 / 13
        case .meta:         return 3  // 14 / 11
        }
    }

    var isUppercase: Bool { self == .meta }
}

private struct AtlasTextStyle: ViewModifier {
    let role: TextRole
    func body(content: Content) -> some View {
        content
            .font(role.font)
            .tracking(role.tracking)
            .lineSpacing(role.lineSpacing)
            .textCase(role.isUppercase ? .uppercase : nil)
    }
}

extension View {
    /// Apply an Atlas type role. Headlines still need explicit `\n` +
    /// `.fixedSize(horizontal: false, vertical: true)` at the call site.
    func atlasText(_ role: TextRole) -> some View {
        modifier(AtlasTextStyle(role: role))
    }
}

// MARK: - Space, radius, elevation

enum Space {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let screen: CGFloat = 20      // screen margin
    static let block: CGFloat = 32       // between blocks
    static let aboveHeadline: CGFloat = 56
}

enum Radius {
    static let chip: CGFloat = 10
    static let button: CGFloat = 16
    static let card: CGFloat = 20
    static let sheet: CGFloat = 28
    static let pill: CGFloat = 999
}

extension View {
    /// The one and only card shadow: ink @ 4%, radius 12, y 4.
    func atlasCardShadow() -> some View {
        shadow(color: Palette.ink.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Motion

enum Motion {
    /// True when the user has asked the system to reduce motion. Read here so
    /// callers branch in one place, not in twelve views.
    static var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    // Durations (seconds)
    static let tap = 0.12
    static let open = 0.40         // cold start: content fades up
    static let transition = 0.34
    static let river = 0.70        // a river segment completing

    static let standardCurve = (0.32, 0.72, 0.0, 1.0)
    static let enterCurve = (0.16, 1.0, 0.3, 1.0)

    static func standard(_ duration: Double = transition) -> Animation {
        .timingCurve(standardCurve.0, standardCurve.1, standardCurve.2, standardCurve.3, duration: duration)
    }

    static func enter(_ duration: Double = open) -> Animation {
        .timingCurve(enterCurve.0, enterCurve.1, enterCurve.2, enterCurve.3, duration: duration)
    }

    /// Screen-to-screen transition: 24pt horizontal push + fade downstream.
    /// Collapses to a 160ms fade under Reduce Motion.
    static var screenTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .offset(x: 24).combined(with: .opacity),
            removal: .offset(x: -24).combined(with: .opacity)
        )
    }

    static var screenTransitionAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.16) : standard(transition)
    }
}
