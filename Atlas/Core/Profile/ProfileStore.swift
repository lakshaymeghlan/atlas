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
    /// Connectors (GitHub / LinkedIn) are NOT attached here — they're opt-in on
    /// the profile, so a non-tech person never sees an empty tech widget.
    func apply(_ result: CVParseResult, email: String?) {
        var next = profile
        next.apply(result)
        if let email { next.email = email }
        profile = next
        log.info("Applied parse: \(result.experiences.count) roles, \(result.skills.count) skills")
    }

    func setDesiredRoles(_ roles: [String]) {
        profile.desiredRoles = roles
    }

    func setPortfolioURL(_ url: String?) {
        profile.portfolioURL = url
    }

    // Optional, reversible connectors (mocked). Reconnect any time.
    func connectGitHub() { profile.github = MockIntegrations.github }
    func disconnectGitHub() { profile.github = nil }
    func connectLinkedIn() { profile.linkedIn = MockIntegrations.linkedIn }
    func disconnectLinkedIn() { profile.linkedIn = nil }

    /// Pin / unpin a GitHub project — at most three pinned at a time.
    func togglePin(_ id: UUID) {
        guard var gh = profile.github,
              let i = gh.projects.firstIndex(where: { $0.id == id }) else { return }
        if gh.projects[i].pinned {
            gh.projects[i].pinned = false
        } else if gh.projects.filter({ $0.pinned }).count < 3 {
            gh.projects[i].pinned = true
        }
        profile.github = gh
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
