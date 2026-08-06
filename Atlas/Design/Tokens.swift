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

// Colour lives in one place only — `Color.canopy*` (see DesignSystem/CanopyColor.swift,
// backed by asset-catalog colour sets). There is no colour token type here by design.

// MARK: - Type

/// The Canopy type roles. Display is Instrument Serif (headlines + wordmark);
/// everything else is Geist Sans at 400/500. Fixed scale — 40/30/22/17/15/13,
/// nothing between. Meta is the one uppercase, tracked eyebrow.
enum TextRole {
    case displayLarge, display, title, body, bodyStrong, caption, meta
}

extension TextRole {
    /// Point size for the role, from the fixed scale.
    var size: CGFloat {
        switch self {
        case .displayLarge: return 40
        case .display:      return 30
        case .title:        return 22
        case .body:         return 17
        case .bodyStrong:   return 17
        case .caption:      return 15
        case .meta:         return 13
        }
    }

    var font: Font {
        switch self {
        case .displayLarge, .display, .title:
            return Typeface.display(size)                 // Instrument Serif
        case .bodyStrong:
            return Typeface.body(size, weight: .medium)   // Geist Medium
        case .body, .caption, .meta:
            return Typeface.body(size)                    // Geist Regular
        }
    }

    /// Letter spacing in points. Serif display settles slightly tight; meta is
    /// the wide uppercase eyebrow (+0.14em @ 13).
    var tracking: CGFloat {
        switch self {
        case .displayLarge: return -0.6
        case .display:      return -0.4
        case .meta:         return 1.8
        default:            return 0
        }
    }

    /// Additional spacing between lines (target line-height minus font size).
    var lineSpacing: CGFloat {
        switch self {
        case .displayLarge: return 3
        case .display:      return 3
        case .title:        return 4
        case .body:         return 7
        case .bodyStrong:   return 7
        case .caption:      return 5
        case .meta:         return 2
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
    /// Apply a Canopy type role. Headlines still need explicit `\n` +
    /// `.fixedSize(horizontal: false, vertical: true)` at the call site.
    func atlasText(_ role: TextRole) -> some View {
        modifier(AtlasTextStyle(role: role))
    }
}

/// The two Canopy faces, each with a graceful system fallback. Drop
/// `InstrumentSerif-Regular` and `Geist-Regular/-Medium` into `Resources/Fonts/`
/// and register them in project.yml's `UIAppFonts`; until then Display renders as
/// the system serif and Body as SF, so the layout is identical either way.
enum Typeface {
    static let displayName = "InstrumentSerif-Regular"
    static let bodyName = "Geist-Regular"
    static let bodyMediumName = "Geist-Medium"

    /// Instrument Serif (regular only) for headlines and the wordmark.
    static func display(_ size: CGFloat) -> Font {
        if UIFont(name: displayName, size: size) != nil {
            return .custom(displayName, size: size)
        }
        return .system(size: size, weight: .regular, design: .serif)
    }

    /// Geist Sans for body/UI — regular and medium only.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = weight == .medium ? bodyMediumName : bodyName
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: .default)
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
    /// The one and only card shadow: canopy shade @ 4%, radius 12, y 4.
    func atlasCardShadow() -> some View {
        shadow(color: Color.canopy900.opacity(0.04), radius: 12, x: 0, y: 4)
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

    /// Numeric evaluation of the standard curve (for manually-driven Canvas
    /// animation, where `Animation` values can't be used). x, result in 0…1.
    static func standardEase(_ x: Double) -> Double {
        cubicBezier(max(0, min(1, x)), standardCurve.0, standardCurve.1, standardCurve.2, standardCurve.3)
    }

    /// y at position x on a cubic-bezier easing curve through (0,0),(p1),(p2),(1,1).
    private static func cubicBezier(_ x: Double, _ p1x: Double, _ p1y: Double, _ p2x: Double, _ p2y: Double) -> Double {
        func curveX(_ t: Double) -> Double { let c = 3 * p1x, b = 3 * (p2x - p1x) - 3 * p1x, a = 1 - 3 * p2x + 3 * p1x; return ((a * t + b) * t + c) * t }
        func curveY(_ t: Double) -> Double { let c = 3 * p1y, b = 3 * (p2y - p1y) - 3 * p1y, a = 1 - 3 * p2y + 3 * p1y; return ((a * t + b) * t + c) * t }
        func derivX(_ t: Double) -> Double { let c = 3 * p1x, b = 3 * (p2x - p1x) - 3 * p1x, a = 1 - 3 * p2x + 3 * p1x; return (3 * a * t + 2 * b) * t + c }
        var t = x
        for _ in 0..<8 {
            let err = curveX(t) - x
            if Swift.abs(err) < 1e-5 { break }
            let d = derivX(t)
            if Swift.abs(d) < 1e-6 { break }
            t -= err / d
        }
        return curveY(t)
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
