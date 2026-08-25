import Foundation

/// App-wide configuration: feature flags and where the backend lives.
enum Config {
    /// Gate for the `River.metal` distortion effect on the Analysing screen.
    /// Off in the prototype: the shader is excluded from the build (needs the
    /// on-demand Metal Toolchain). Re-include River.metal in project.yml and
    /// flip this on to enable the ripple. Also our frame-budget escape hatch.
    static let useShaders = false

    /// OAuth callback scheme (registered in Info.plist). Unused until real auth.
    static let oauthScheme = "canopy"

    /// Demo mode: offer the bundled sample CVs instead of opening the Files
    /// picker, for hosted previews (Appetize) that have no filesystem. The
    /// samples are real PDFs, so the rest of the path is unchanged.
    /// ponytail: single flag, remove once upload is wired to Storage.
    static let demoMode = true

    /// Where the edge functions live. `nil` falls back to the mock parser and
    /// mock connectors — no network, everything canned.
    ///
    /// `.localDev` points at functions served on this Mac, which the simulator
    /// reaches over localhost; that's the fastest way to work against real
    /// parsing without deploying anything. Swap in `.supabase(...)` once the
    /// project is deployed.
    static let backend: Backend? = .localDev

    struct Backend {
        let parseCVEndpoint: String
        let importGitHubEndpoint: String
        /// Supabase gates functions on the anon key; local serving ignores it.
        let anonKey: String?

        var parseCV: URL? { URL(string: parseCVEndpoint) }
        var importGitHub: URL? { URL(string: importGitHubEndpoint) }

        /// Functions served on this Mac (see supabase/functions/README.md).
        /// Needs the ATS local-networking exception, which project.yml sets.
        static let localDev = Backend(
            parseCVEndpoint: "http://localhost:8791",
            importGitHubEndpoint: "http://localhost:8792",
            anonKey: nil
        )

        /// A deployed Supabase project.
        static func supabase(ref: String, anonKey: String) -> Backend {
            Backend(
                parseCVEndpoint: "https://\(ref).supabase.co/functions/v1/parse-cv",
                importGitHubEndpoint: "https://\(ref).supabase.co/functions/v1/import-github",
                anonKey: anonKey
            )
        }
    }
}
