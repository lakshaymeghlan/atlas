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

    private let log = Logger(subsystem: "canopy.ai", category: "profile")

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

    // Optional, reversible connectors. Reconnect any time.

    /// Attach a real GitHub import, merging its languages in as skills.
    func connectGitHub(_ data: GitHubData, skills: [Skill]) {
        var next = profile
        next.github = data
        next.skills = merge(skills, into: next.skills)
        profile = next
        log.info("GitHub imported: \(data.projects.count) repos, \(skills.count) languages")
    }

    func disconnectGitHub() {
        var next = profile
        next.github = nil
        // Skills that only existed because of GitHub go with it.
        next.skills.removeAll { $0.source == .github }
        profile = next
    }

    /// Merge a profile parsed from a LinkedIn PDF export. Experience and skills
    /// are additive — an export supplements the CV rather than replacing it.
    func applyLinkedIn(_ result: CVParseResult) {
        var next = profile
        if next.fullName == nil { next.fullName = result.fullName }
        if next.headline == nil { next.headline = result.headline }
        if next.location == nil { next.location = result.location }

        let roles = result.experiences.map {
            Experience(role: $0.role, company: $0.company, startDate: $0.startDate,
                       endDate: $0.endDate, description: $0.description, confidence: $0.confidence)
        }
        let known = Set(next.experiences.map { "\($0.role)|\($0.company)".lowercased() })
        next.experiences += roles.filter { !known.contains("\($0.role)|\($0.company)".lowercased()) }

        next.skills = merge(result.skills.map { Skill(name: $0.name, source: .cv, confidence: $0.confidence) },
                            into: next.skills)
        let languages = result.languages.map { Language(name: $0.name, level: $0.level) }
        let haveLanguages = Set(next.languages.map { $0.name.lowercased() })
        next.languages += languages.filter { !haveLanguages.contains($0.name.lowercased()) }

        next.linkedIn = LinkedInData(importedAt: Date(), roles: roles.count, skills: result.skills.count)
        profile = next
        log.info("LinkedIn import: \(roles.count) roles, \(result.skills.count) skills")
    }

    func disconnectLinkedIn() { profile.linkedIn = nil }

    /// Add skills that aren't already on the profile, matched case-insensitively.
    private func merge(_ incoming: [Skill], into existing: [Skill]) -> [Skill] {
        let have = Set(existing.map { $0.name.lowercased() })
        return existing + incoming.filter { !have.contains($0.name.lowercased()) }
    }

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
