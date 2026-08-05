import Foundation

/// App-wide configuration. In the prototype there is no backend, so this only
/// carries feature flags. Backend URLs/keys move here (read from Secrets.xcconfig)
/// when Supabase lands — see DECISIONS.md.
enum Config {
    /// Gate for the `River.metal` distortion effect on the Analysing screen.
    /// Off in the prototype: the shader is excluded from the build (needs the
    /// on-demand Metal Toolchain). Re-include River.metal in project.yml and
    /// flip this on to enable the ripple. Also our frame-budget escape hatch.
    static let useShaders = false

    /// OAuth callback scheme (registered in Info.plist). Unused until real auth.
    static let oauthScheme = "atlas"

    /// Demo mode for hosted previews (Appetize) where the Files picker can't reach
    /// a real filesystem. On: tapping "Upload" attaches a sample CV so a reviewer
    /// can walk the whole flow. Off for real device builds — the picker works there.
    /// ponytail: single flag, remove once real upload is wired to a backend.
    static let demoMode = true
}
