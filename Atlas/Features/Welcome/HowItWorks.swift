import SwiftUI

/// A compact, self-explaining "how it works" strip for the Welcome screen:
/// Upload CV → Build profile → Get matched. A soft highlight steps through the
/// three in sequence so the screen quietly demonstrates the product and stays
/// alive without any heavy illustration. Reduce Motion → all three shown calm.
struct HowItWorks: View {
    struct Step { let icon: String; let label: String }

    var accent: Color
    var accentTint: Color
    var chip: Color
    var ink: Color
    var inkTertiary: Color

    private let steps = [
        Step(icon: "arrow.up.doc.fill", label: "Upload CV"),
        Step(icon: "sparkles", label: "Build profile"),
        Step(icon: "checkmark.seal.fill", label: "Get matched"),
    ]

    var body: some View {
        if Motion.reduceMotion {
            row(active: -1)
        } else {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let active = Int((t / 1.25).truncatingRemainder(dividingBy: Double(steps.count)))
                row(active: active)
            }
        }
    }

    private func row(active: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                stepView(step, isActive: i == active)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("How it works: upload your CV, Atlas builds your profile, then matches you to roles.")
    }

    private func stepView(_ step: Step, isActive: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(isActive ? accentTint : chip)
                Image(systemName: step.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isActive ? accent : inkTertiary)
            }
            .frame(width: 50, height: 50)
            .scaleEffect(isActive ? 1.09 : 1)
            .shadow(color: isActive ? accent.opacity(0.28) : .clear,
                    radius: isActive ? 12 : 0, x: 0, y: isActive ? 5 : 0)

            Text(step.label)
                .font(.system(size: 12.5, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? ink : inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: isActive)
    }
}

#Preview {
    HowItWorks(accent: Color(hex: "4F63F0"), accentTint: Color(hex: "ECEEFE"),
               chip: Color(hex: "F1EFEA"), ink: Color(hex: "0C0C0D"),
               inkTertiary: Color(hex: "9A9A9F"))
        .padding()
        .background(Color(hex: "FCFBF8"))
}
