import Foundation

/// Stand-in GitHub + LinkedIn data for the prototype. With the real backend this
/// comes from the GitHub API (repos, contributions) and LinkedIn OIDC/activity.
enum MockIntegrations {
    static let github = GitHubData(
        username: "you",
        repoCount: 34,
        contributionsLastYear: 1284,
        followers: 210,
        projects: [
            GitHubProject(name: "atlas-ios", description: "The Atlas iOS app — SwiftUI, MV, Observable.",
                          language: "Swift", stars: 128, forks: 12, pinned: true),
            GitHubProject(name: "river-kit", description: "Fluid Canvas + Metal animations for SwiftUI.",
                          language: "Swift", stars: 342, forks: 28, pinned: true),
            GitHubProject(name: "cv-parser", description: "Structured CV extraction with LLMs.",
                          language: "TypeScript", stars: 89, forks: 7, pinned: true),
            GitHubProject(name: "metal-playground", description: "Shader experiments and ripple effects.",
                          language: "Metal", stars: 54, forks: 4),
            GitHubProject(name: "notes-cli", description: "Fast terminal note-taking.",
                          language: "Rust", stars: 76, forks: 9),
            GitHubProject(name: "dotfiles", description: "My dev environment, one command away.",
                          language: "Shell", stars: 23, forks: 3),
        ]
    )

    static let linkedIn = LinkedInData(connections: 1240, followers: 860, posts: 42)
}
