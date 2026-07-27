import Foundation
import Observation
import os

/// The person's profile. Autosaves every mutation to `LocalStore` (prototype
/// persistence), so a force-quit at any point restores intact. The Supabase
/// upsert/hydrate calls replace the `didSet` and `init` bodies later.
@MainActor
@Observable
final class ProfileStore {
    var profile: UserProfile {
        didSet { LocalStore.save(profile, for: .profile) }
    }

    private let log = Logger(subsystem: "ai.sofsuite.atlas", category: "profile")

    init() {
        profile = LocalStore.load(UserProfile.self, for: .profile) ?? UserProfile()
    }

    /// Merge a CV parse result (from the mock or the real function) into the profile.
    func apply(_ result: CVParseResult, email: String?) {
        var next = profile
        next.apply(result)
        if let email { next.email = email }
        profile = next
        log.info("Applied parse: \(result.experiences.count) roles, \(result.skills.count) skills")
    }

    func completeOnboarding() {
        profile.onboardedAt = Date()
        log.info("Onboarding complete")
    }

    /// Clear everything (used on sign-out).
    func reset() {
        profile = UserProfile()
        LocalStore.remove(.profile)
    }
}
