import Foundation
import Observation
import os

/// Session + sign-in. Prototype only: there's no real OAuth — tapping a
/// provider simulates the web-auth sheet and fabricates a user. The real
/// Supabase `signInWithOAuth` drops in behind the same method signatures.
@MainActor
@Observable
final class AuthStore {
    private(set) var user: AuthUser?
    private(set) var isAuthenticating = false

    var isSignedIn: Bool { user != nil }

    private let log = Logger(subsystem: "ai.sofsuite.atlas", category: "auth")

    init() {
        user = LocalStore.load(AuthUser.self, for: .authUser)
    }

    func signIn(with provider: AuthProvider) async {
        isAuthenticating = true
        defer { isAuthenticating = false }

        // Stand-in for ASWebAuthenticationSession + Supabase token exchange.
        try? await Task.sleep(for: .milliseconds(600))

        let signedIn = AuthUser(fullName: nil, email: "you@example.com", provider: provider)
        user = signedIn
        LocalStore.save(signedIn, for: .authUser)
        log.info("Stub sign-in via \(provider.rawValue, privacy: .public)")
    }

    /// Start a session without OAuth — the "Begin with my CV" path. Connectors
    /// (LinkedIn/GitHub) become optional enrichers on the profile later.
    func begin() {
        let started = AuthUser(fullName: nil, email: nil, provider: .direct)
        user = started
        LocalStore.save(started, for: .authUser)
        log.info("Session started (direct)")
    }

    func signOut() {
        user = nil
        LocalStore.remove(.authUser)
        log.info("Signed out")
    }
}
