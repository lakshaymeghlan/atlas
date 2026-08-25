import XCTest
@testable import Atlas

/// Exercises the app's networking and decoding against the *real* edge functions.
///
/// Start them first (see supabase/functions/README.md):
///   PORT=8791 deno run --allow-all _serve.ts ./parse-cv/index.ts
///   PORT=8792 deno run --allow-all _serve.ts ./import-github/index.ts
///
/// Each test skips — rather than fails — when the backend isn't running, so the
/// suite stays green offline while still covering the wiring when it matters.
final class BackendClientTests: XCTestCase {
    private func requireBackend(_ url: URL?) async throws {
        guard let url else { throw XCTSkip("No backend configured") }
        var request = URLRequest(url: url)
        request.httpMethod = "OPTIONS"
        request.timeoutInterval = 3
        do {
            _ = try await URLSession.shared.data(for: request)
        } catch {
            throw XCTSkip("Backend not reachable at \(url) — start the functions to run this")
        }
    }

    // MARK: parse-cv

    func testParsesBundledCVIntoTheProfileShape() async throws {
        try await requireBackend(Config.backend?.parseCV)
        let cv = try XCTUnwrap(SampleCV.conventional.load(), "sample CV missing from the bundle")

        let result = try await BackendClient.parseCV(.file(cv))

        XCTAssertEqual(result.fullName, "Alex Rivera")
        XCTAssertEqual(result.location, "Berlin, Germany")
        XCTAssertEqual(result.experiences.count, 3)

        let first = try XCTUnwrap(result.experiences.first)
        XCTAssertEqual(first.role, "Senior iOS Engineer")
        XCTAssertEqual(first.company, "Riverbank")
        XCTAssertEqual(first.startDate, "March 2022")
        XCTAssertNil(first.endDate, "a current role must decode as nil, not a string")

        XCTAssertEqual(result.education.first?.institution, "Technical University of Berlin")
        XCTAssertFalse(result.skills.isEmpty)
        XCTAssertEqual(result.languages.first?.name, "English")
        // Confidence must survive the round trip and stay in range.
        XCTAssertTrue(result.experiences.allSatisfy { (0...1).contains($0.confidence) })
    }

    /// The LinkedIn export is the real import path, and its layout is inverted —
    /// company above role. If that regresses, every role/company is swapped.
    func testParsesLinkedInExportWithoutSwappingRoleAndCompany() async throws {
        try await requireBackend(Config.backend?.parseCV)
        let cv = try XCTUnwrap(SampleCV.linkedIn.load(), "sample LinkedIn export missing")

        let result = try await BackendClient.parseCV(.file(cv))

        XCTAssertEqual(result.fullName, "Priya Nair")
        let first = try XCTUnwrap(result.experiences.first)
        XCTAssertEqual(first.role, "Senior Product Manager")
        XCTAssertEqual(first.company, "Lumen")
        XCTAssertNil(first.endDate)
        XCTAssertFalse(
            result.experiences.contains { $0.role.contains("year") || $0.company.contains("year") },
            "LinkedIn's duration suffix leaked into a field"
        )
    }

    func testScannedPDFSurfacesAsAPermanentFailure() async throws {
        try await requireBackend(Config.backend?.parseCV)
        let cv = try XCTUnwrap(SampleCV.scan.load(), "sample scan missing")

        do {
            _ = try await BackendClient.parseCV(.file(cv))
            XCTFail("an image-only PDF should not parse")
        } catch let failure as BackendClient.Failure {
            guard case .noText = failure else {
                return XCTFail("expected .noText, got \(failure)")
            }
            XCTAssertTrue(failure.isPermanent, "retrying the same scan can't help")
            XCTAssertNotNil(failure.errorDescription, "the user needs something to read")
        }
    }

    // MARK: import-github

    func testImportsRealGitHubProfile() async throws {
        try await requireBackend(Config.backend?.importGitHub)

        let (github, skills) = try await BackendClient.importGitHub(username: "octocat")

        XCTAssertEqual(github.username, "octocat")
        XCTAssertGreaterThan(github.repoCount, 0)
        XCTAssertFalse(github.projects.isEmpty)
        XCTAssertLessThanOrEqual(github.pinnedProjects.count, 3, "at most three pinned")
        XCTAssertTrue(skills.allSatisfy { $0.source == .github },
                      "languages must be attributed to GitHub, not the CV")
        XCTAssertTrue(skills.allSatisfy { (0...1).contains($0.confidence) })
    }

    func testUnknownGitHubUserIsReportedNotCrashed() async throws {
        try await requireBackend(Config.backend?.importGitHub)

        do {
            _ = try await BackendClient.importGitHub(username: "this-user-should-not-exist-9f3a2b")
            XCTFail("expected a failure for a nonexistent user")
        } catch let failure as BackendClient.Failure {
            guard case .server(let code, _) = failure else {
                return XCTFail("expected .server, got \(failure)")
            }
            XCTAssertEqual(code, 404)
        }
    }

    // MARK: merging

    func testGitHubLanguagesMergeWithoutDuplicatingCVSkills() async throws {
        // Persist to a throwaway suite: ProfileStore autosaves, and the tests run
        // inside the app process — writing to the real store would wipe whatever
        // profile the app on this simulator was holding.
        let suite = "atlas.tests.\(UUID().uuidString)"
        LocalStore.defaults = UserDefaults(suiteName: suite) ?? .standard
        defer {
            UserDefaults.standard.removeSuite(named: suite)
            LocalStore.defaults = .standard
        }

        let store = await ProfileStore()
        await MainActor.run {
            store.reset()
            store.profile.skills = [Skill(name: "Swift", source: .cv, confidence: 0.9)]
            store.connectGitHub(
                GitHubData(username: "someone", repoCount: 2, contributionsLastYear: 0, followers: 1),
                skills: [Skill(name: "swift", source: .github, confidence: 0.8),
                         Skill(name: "Rust", source: .github, confidence: 0.5)]
            )
            // "swift" duplicates the CV's "Swift" case-insensitively and is dropped.
            XCTAssertEqual(store.profile.skills.map(\.name), ["Swift", "Rust"])

            store.disconnectGitHub()
            XCTAssertEqual(store.profile.skills.map(\.name), ["Swift"],
                           "disconnecting GitHub must take only its own skills")
        }
    }
}
