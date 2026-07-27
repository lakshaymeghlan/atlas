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
        if profile.hasParsedContent { return .confirmProfile }
        if profile.careerPath != nil { return .uploadCV }
        return .careerPath
    }

    // MARK: Transitions

    func didSignIn() { go(.careerPath) }

    func chooseSeeking() {
        profile.profile.careerPath = .seeking
        go(.uploadCV)
    }

    func didPickCV(_ cv: PickedCV) { go(.analysing(cv: cv)) }

    func parsingSucceeded() { go(.confirmProfile) }

    /// From the Analysing failure state: build the profile by hand.
    func enterManualEntry() { go(.confirmProfile) }

    func retryUpload() { go(.uploadCV) }

    func backToCareerPath() { go(.careerPath) }

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
