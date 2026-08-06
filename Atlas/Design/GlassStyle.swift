import SwiftUI

/// Apple-style "liquid glass": frosted material, a soft top-down sheen, and a
/// specular rim that's brightest at the top edge. Built once here and reused by
/// every surface (buttons, cards, sheets) so the glass reads as one material.
struct GlassSurface: ViewModifier {
    var cornerRadius: CGFloat
    /// Tint painted under the frost — controls how light/opaque the glass reads.
    var tint: Color = .white.opacity(0.45)
    /// Scales the whole treatment down for small elements (chips, nodes).
    var intensity: CGFloat = 1

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape.fill(tint).background(.ultraThinMaterial, in: shape)
            }
            .overlay {
                // Sheen — light gathers at the top and fades by the middle.
                shape.fill(
                    LinearGradient(
                        colors: [.white.opacity(0.38 * intensity), .white.opacity(0)],
                        startPoint: .top, endPoint: .center
                    )
                )
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            }
            .overlay {
                // Specular rim — a bright top edge easing into a hairline.
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.75 * intensity), Color.canopyPaperLine.opacity(0.9)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .clipShape(shape)
            .shadow(color: Color.canopy900.opacity(0.05 * intensity), radius: 12, x: 0, y: 5)
    }
}

extension View {
    func glassSurface(_ cornerRadius: CGFloat, tint: Color = .white.opacity(0.45), intensity: CGFloat = 1) -> some View {
        modifier(GlassSurface(cornerRadius: cornerRadius, tint: tint, intensity: intensity))
    }
}
