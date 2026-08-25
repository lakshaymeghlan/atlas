import Foundation
import os

/// Talks to the Canopy edge functions. One place for every network call, so
/// switching from a locally-served function to a deployed Supabase project is a
/// change in `Config.backend` and nothing else.
enum BackendClient {
    enum Failure: LocalizedError {
        case notConfigured
        case unreachable(String)
        case noText
        case server(Int, String?)
        case badResponse

        var errorDescription: String? {
            switch self {
            case .notConfigured: "No backend is configured."
            case .unreachable(let why): "Couldn't reach the backend: \(why)"
            case .noText: "That file has no readable text — it's probably a scan."
            case .server(let code, let message): message ?? "The backend returned \(code)."
            case .badResponse: "The backend sent something we couldn't read."
            }
        }

        /// True when retrying the same file can't help.
        var isPermanent: Bool {
            if case .noText = self { return true }
            return false
        }
    }

    private static let log = Logger(subsystem: "canopy.ai", category: "backend")

    // MARK: Requests

    /// CV / LinkedIn PDF → the structured profile. Decoded through the same
    /// `CVParseResult` the mock used, so everything downstream is unchanged.
    static func parseCV(_ source: CVSource) async throws -> CVParseResult {
        let body: [String: Any]
        switch source {
        case .file(let cv):
            body = ["kind": "file", "filename": cv.filename, "base64": cv.data.base64EncodedString()]
        case .linkedIn:
            // Nothing to send: LinkedIn has no API for experience, so this path
            // only exists for a PDF the user exported (handled as .file above).
            throw Failure.notConfigured
        }
        let data = try await post(Config.backend?.parseCV, body: body)
        do {
            return try CVParseResult.decode(data)
        } catch {
            log.error("parse-cv decode failed: \(error.localizedDescription, privacy: .public)")
            throw Failure.badResponse
        }
    }

    /// Public GitHub profile → the app's `GitHubData`, plus the languages they
    /// ship in as skills.
    static func importGitHub(username: String) async throws -> (GitHubData, [Skill]) {
        let data = try await post(Config.backend?.importGitHub, body: ["username": username])
        guard let dto = try? JSONDecoder().decode(GitHubImportDTO.self, from: data) else {
            throw Failure.badResponse
        }
        let github = GitHubData(
            username: dto.username,
            repoCount: dto.repoCount,
            contributionsLastYear: dto.contributionsLastYear,
            followers: dto.followers,
            projects: dto.projects.map {
                GitHubProject(name: $0.name, description: $0.description, language: $0.language,
                              stars: $0.stars, forks: $0.forks, pinned: $0.pinned)
            }
        )
        let skills = dto.skills.map { Skill(name: $0.name, source: .github, confidence: $0.confidence) }
        return (github, skills)
    }

    // MARK: Transport

    private static func post(_ url: URL?, body: [String: Any]) async throws -> Data {
        guard let url else { throw Failure.notConfigured }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        // Supabase gates functions on the anon key; a locally-served function ignores it.
        if let key = Config.backend?.anonKey {
            request.setValue(key, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(key)", forHTTPHeaderField: "authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let data: Data, response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw Failure.unreachable(error.localizedDescription)
        }

        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            let error = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            log.error("\(url.lastPathComponent, privacy: .public) → \(code): \(error ?? "-", privacy: .public)")
            if error == "no_text" { throw Failure.noText }
            throw Failure.server(code, error)
        }
        return data
    }
}

/// The `import-github` response. Its keys are camelCase on the wire (unlike
/// `parse-cv`, which is snake_case), so no key strategy is applied.
private struct GitHubImportDTO: Decodable {
    let username: String
    let repoCount: Int
    let followers: Int
    let contributionsLastYear: Int
    let projects: [Project]
    let skills: [LanguageSkill]

    struct Project: Decodable {
        let name: String
        let description: String?
        let language: String?
        let stars: Int
        let forks: Int
        let pinned: Bool
    }

    struct LanguageSkill: Decodable {
        let name: String
        let confidence: Double
    }
}
