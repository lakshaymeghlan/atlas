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
    private let log = Logger(subsystem: "canopy.ai", category: "router")

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
        guard profile.hasParsedContent else { return .uploadCV }
        return profile.preferences.isComplete ? .confirmProfile : .preferences
    }

    // MARK: Transitions

    func didBegin() {
        // From the tree onboarding → the "what brings you here?" chooser. No
        // session yet; it starts once they pick a path.
        go(.chooseIntent)
    }

    /// Chooser → candidate path. Start the session and go to the CV step.
    func chooseExplore() {
        auth.begin()
        go(.uploadCV)
    }

    /// Chooser → joining through a company. Same profile build for now (the
    /// company-code/invite flow isn't built yet).
    /// ponytail: placeholder — routes into the CV flow until the company path exists.
    func chooseCompany() {
        auth.begin()
        go(.uploadCV)
    }

    /// Back out of the CV step to the chooser — undoes the session so re-picking
    /// a path is clean.
    func backToIntent() {
        auth.signOut()
        profile.reset()
        go(.chooseIntent)
    }

    func didPickSource(_ source: CVSource) {
        go(.analysing(source: source))
    }

    // Onboarding: analysing → preferences wizard → profile review. (The old
    // roles step is parked — RolePreferences/didChooseRoles kept for later.)
    func parsingSucceeded() { go(.preferences) }

    /// From the Analysing failure state: build the profile by hand.
    func enterManualEntry() { go(.preferences) }

    /// Preferences wizard finished → the profile review.
    func preferencesCompleted() { go(.confirmProfile) }

    func didChooseRoles(_ roles: [String]) {
        profile.setDesiredRoles(roles)
        go(.confirmProfile)
    }

    func retryUpload() { go(.uploadCV) }

    /// Back out of the CV step to Welcome — undoes the "begin" session so a
    /// mistaken tap isn't a dead end (nothing's been entered yet).
    func backToWelcome() {
        auth.signOut()
        profile.reset()
        go(.welcome)
    }

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
