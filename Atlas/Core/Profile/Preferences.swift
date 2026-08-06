import Foundation

/// What the candidate wants from their next move — gathered in the onboarding
/// wizard, used to shape matches. Stored on the profile so it persists and
/// carries to the real backend unchanged.
struct JobPreferences: Codable, Equatable {
    var arrangements: Set<WorkArrangement> = []
    var workTypes: Set<WorkType> = []
    var openToAnywhere: Bool = false
    var relocationCountries: Set<String> = []
    /// Ranked; the top three shape matches most. Defaults to the natural order.
    var priorities: [WorkPriority] = WorkPriority.allCases
    var salaryOpen: Bool = false
    var minSalary: Int = 65_000
    var startAvailability: StartAvailability? = nil
}

enum WorkArrangement: String, Codable, CaseIterable, Identifiable {
    case remote, hybrid, onsite
    var id: String { rawValue }
    var label: String {
        switch self { case .remote: "Remote"; case .hybrid: "Hybrid"; case .onsite: "In office" }
    }
}

enum WorkType: String, Codable, CaseIterable, Identifiable {
    case fullTime, partTime, contract, internship
    var id: String { rawValue }
    var label: String {
        switch self {
        case .fullTime: "Full-time"; case .partTime: "Part-time"
        case .contract: "Contract"; case .internship: "Internship"
        }
    }
}

enum StartAvailability: String, Codable, CaseIterable, Identifiable {
    case immediately, oneToThree, threeToSix, notSure
    var id: String { rawValue }
    var label: String {
        switch self {
        case .immediately: "Immediately"; case .oneToThree: "1–3 months"
        case .threeToSix: "3–6 months"; case .notSure: "Not sure yet"
        }
    }
}

enum WorkPriority: String, Codable, CaseIterable, Identifiable {
    case meaningfulWork, growth, compensation, flexibility, teamCulture, stability, location, impact
    var id: String { rawValue }
    var label: String {
        switch self {
        case .meaningfulWork: "Meaningful work"
        case .growth: "Learning & growth"
        case .compensation: "Pay & benefits"
        case .flexibility: "Flexibility"
        case .teamCulture: "Team & culture"
        case .stability: "Stability & security"
        case .location: "Location"
        case .impact: "Impact & mission"
        }
    }
}

/// Common visa-sponsorship destinations offered on the relocation step.
enum Relocation {
    static let destinations = [
        "United States", "United Kingdom", "Germany", "Netherlands", "Canada",
        "Ireland", "Australia", "Singapore", "Switzerland", "France",
        "Spain", "Sweden", "UAE", "Japan",
    ]
}
