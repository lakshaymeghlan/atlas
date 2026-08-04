import Foundation
import Observation
import os

/// Drives the journey. Owns `JourneyState` and the transitions between screens,
/// and resolves where to resume on launch so a force-quit never dumps the user
/// back at Welcome.
@MainActor
@Observable
final class AppRouter {
    private(set) var state: JourneyState

    private let auth: AuthStore
    private let profile: ProfileStore
    private let log = Logger(subsystem: "ai.sofsuite.atlas", category: "router")

    init(auth: AuthStore, profile: ProfileStore) {
        self.auth = auth
        self.profile = profile
        self.state = AppRouter.resolveInitialState(auth: auth, profile: profile)
    }

    static func resolveInitialState(auth: AuthStore, profile: ProfileStore) -> JourneyState {
        initialState(isSignedIn: auth.isSignedIn, profile: profile.profile)
    }

    /// Restoration logic (pure, testable): session + onboarded → home; session
    /// but not onboarded → the furthest completed step; no session → welcome.
    nonisolated static func initialState(isSignedIn: Bool, profile: UserProfile) -> JourneyState {
        guard isSignedIn else { return .welcome }
        if profile.isOnboarded { return .home }
        if profile.hasParsedContent {
            return profile.desiredRoles.isEmpty ? .rolePreferences : .confirmProfile
        }
        return .uploadCV
    }

    // MARK: Transitions

    func didSignIn() {
        // They signed in with LinkedIn, so LinkedIn is connected from the start.
        profile.connectLinkedIn()
        go(.uploadCV)
    }

    func didPickSource(_ source: CVSource) {
        if case .link(let url) = source { profile.setPortfolioURL(url) }
        go(.analysing(source: source))
    }

    func parsingSucceeded() { go(.rolePreferences) }

    /// From the Analysing failure state: build the profile by hand.
    func enterManualEntry() { go(.rolePreferences) }

    func didChooseRoles(_ roles: [String]) {
        profile.setDesiredRoles(roles)
        go(.confirmProfile)
    }

    func retryUpload() { go(.uploadCV) }

    func didConfirmProfile() {
        profile.completeOnboarding()
        go(.home)
    }

    func signOut() {
        auth.signOut()
        profile.reset()
        go(.welcome)
    }

    private func go(_ next: JourneyState) {
        log.info("Journey → \(String(describing: next), privacy: .public)")
        state = next
    }
}
