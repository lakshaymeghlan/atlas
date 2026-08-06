import Foundation

// MARK: - CV parse result (the edge-function contract)

/// The JSON shape returned by the (future) `parse-cv` edge function. The mock
/// parser produces the same shape, so this decoder — and its tests — carry
/// straight over to the real backend. Keys are snake_case on the wire;
/// `decode` uses `.convertFromSnakeCase`.
struct CVParseResult: Codable, Equatable {
    var fullName: String?
    var headline: String?
    var location: String?
    var experiences: [ParsedExperience]
    var education: [ParsedEducation]
    var skills: [ParsedSkill]
    var languages: [ParsedLanguage]

    struct ParsedExperience: Codable, Equatable {
        var role: String
        var company: String
        var startDate: String?
        var endDate: String?
        var description: String?
        var confidence: Double
    }

    struct ParsedEducation: Codable, Equatable {
        var institution: String
        var degree: String?
        var field: String?
        var startYear: String?
        var endYear: String?
        var confidence: Double
    }

    struct ParsedSkill: Codable, Equatable {
        var name: String
        var confidence: Double
    }

    struct ParsedLanguage: Codable, Equatable {
        var name: String
        var level: String?
    }

    /// Strict decode. Throws on malformed JSON or a missing required field.
    static func decode(_ data: Data) throws -> CVParseResult {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CVParseResult.self, from: data)
    }

    static func decode(_ json: String) throws -> CVParseResult {
        guard let data = json.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "not UTF-8"))
        }
        return try decode(data)
    }
}

// MARK: - Domain models (editable, persisted)

enum CareerPath: String, Codable { case seeking, employed }

enum SkillSource: String, Codable { case cv, github, manual }

/// Confidence below this gets a blue dot and sorts to the top of its section.
let lowConfidenceThreshold = 0.6

struct Experience: Identifiable, Codable, Equatable {
    var id = UUID()
    var role: String
    var company: String
    var startDate: String?
    var endDate: String?          // nil == current
    var description: String?
    var confidence: Double = 1.0
    var isLowConfidence: Bool { confidence < lowConfidenceThreshold }
}

struct Education: Identifiable, Codable, Equatable {
    var id = UUID()
    var institution: String
    var degree: String?
    var field: String?
    var startYear: String?
    var endYear: String?
    var confidence: Double = 1.0
    var isLowConfidence: Bool { confidence < lowConfidenceThreshold }
}

struct Skill: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var source: SkillSource = .cv
    var confidence: Double = 1.0
    var isLowConfidence: Bool { confidence < lowConfidenceThreshold }
}

struct Language: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var level: String?
}

// MARK: - Integrations (GitHub / LinkedIn)

struct GitHubProject: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var description: String?
    var language: String?
    var stars: Int
    var forks: Int
    var pinned: Bool = false
}

struct GitHubData: Codable, Equatable {
    var username: String
    var repoCount: Int
    var contributionsLastYear: Int
    var followers: Int
    var projects: [GitHubProject] = []

    var pinnedProjects: [GitHubProject] { projects.filter { $0.pinned } }
    var totalStars: Int { projects.reduce(0) { $0 + $1.stars } }
}

struct LinkedInData: Codable, Equatable {
    var connections: Int
    var followers: Int
    var posts: Int
}

/// Everything the app knows about a person. Persisted as JSON in UserDefaults
/// (prototype) — the same shape the Supabase tables will hold.
struct UserProfile: Codable, Equatable {
    var fullName: String?
    var email: String?
    var headline: String?
    var location: String?
    var careerPath: CareerPath?
    var experiences: [Experience] = []
    var education: [Education] = []
    var skills: [Skill] = []
    var languages: [Language] = []
    /// Roles the person is looking for (typed + picked on the roles step).
    var desiredRoles: [String] = []
    /// What they want from their next move — set in the preferences wizard.
    var preferences = JobPreferences()
    /// A portfolio / profile link they gave instead of (or with) a CV.
    var portfolioURL: String?
    /// Optional, reversible connectors — nil until the person connects them.
    var github: GitHubData?
    var linkedIn: LinkedInData?
    var onboardedAt: Date?

    var isOnboarded: Bool { onboardedAt != nil }

    /// True once a CV has been parsed (or details entered) — used to resume at
    /// the confirm step after a force-quit rather than restarting the upload.
    var hasParsedContent: Bool {
        !experiences.isEmpty || !education.isEmpty || !skills.isEmpty
            || !languages.isEmpty || headline != nil || location != nil
    }

    /// Merge a parse result into the profile, preserving identity-derived
    /// fields (email/careerPath) that don't come from the CV.
    mutating func apply(_ r: CVParseResult) {
        fullName = r.fullName ?? fullName
        headline = r.headline
        location = r.location
        experiences = r.experiences.map {
            Experience(role: $0.role, company: $0.company, startDate: $0.startDate,
                       endDate: $0.endDate, description: $0.description, confidence: $0.confidence)
        }
        education = r.education.map {
            Education(institution: $0.institution, degree: $0.degree, field: $0.field,
                      startYear: $0.startYear, endYear: $0.endYear, confidence: $0.confidence)
        }
        skills = r.skills.map { Skill(name: $0.name, source: .cv, confidence: $0.confidence) }
        languages = r.languages.map { Language(name: $0.name, level: $0.level) }
    }
}

// MARK: - Auth

enum AuthProvider: String, Codable {
    case linkedIn, github, direct
    var displayName: String {
        switch self { case .linkedIn: "LinkedIn"; case .github: "GitHub"; case .direct: "Canopy" }
    }
}

struct AuthUser: Codable, Equatable {
    var id = UUID()
    var fullName: String?
    var email: String?
    var provider: AuthProvider
}
