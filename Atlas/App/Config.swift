import Foundation

/// App-wide configuration. In the prototype there is no backend, so this only
/// carries feature flags. Backend URLs/keys move here (read from Secrets.xcconfig)
/// when Supabase lands — see DECISIONS.md.
enum Config {
    /// Gate for the `River.metal` distortion effect on the Analysing screen.
    /// Flip off if Instruments shows dropped frames on older devices.
    static let useShaders = true

    /// OAuth callback scheme (registered in Info.plist). Unused until real auth.
    static let oauthScheme = "atlas"
}
