import Foundation

/// What the candidate wants from their next move — gathered in the onboarding
/// wizard, used to shape matches. Stored on the profile so it persists and
/// carries to the real backend unchanged.
struct JobPreferences: Codable, Equatable {
    /// The things you'd protect time for — up to five. Shapes culture/fit, not
    /// just the role.
    var hobbies: Set<String> = []
    var arrangements: Set<WorkArrangement> = []
    var workTypes: Set<WorkType> = []
    var openToAnywhere: Bool = false
    var relocationCountries: Set<String> = []
    /// Ranked; the top three shape matches most. Defaults to the natural order.
    var priorities: [WorkPriority] = WorkPriority.allCases
    var salaryOpen: Bool = false
    var minSalary: Int = 65_000
    var startAvailability: StartAvailability? = nil

    /// Every required answer is in. The wizard's own step gates are the same
    /// conditions; this is what restoration reads so a force-quit on the profile
    /// review doesn't drop you back at step one of the wizard.
    var isComplete: Bool {
        !hobbies.isEmpty && !arrangements.isEmpty && !workTypes.isEmpty
            && (openToAnywhere || !relocationCountries.isEmpty)
            && startAvailability != nil
    }
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

/// Hobbies offered on the "what makes life feel like yours" step (pick up to 5).
enum Hobbies {
    static let maxSelectable = 5
    static let options = [
        "Coding", "Reading", "Gaming", "Music", "Cooking", "Fitness",
        "Travel", "Photography", "Art & design", "Team sports", "Writing",
        "Gardening", "Film & TV", "Volunteering", "Hiking", "Dancing",
        "Podcasts", "Board games",
    ]
}

/// Common visa-sponsorship destinations offered as quick-pick chips, plus the
/// full searchable country list (sourced from the system, not hardcoded).
enum Relocation {
    static let destinations = [
        "United States", "United Kingdom", "Germany", "Netherlands", "Canada",
        "Ireland", "Australia", "Singapore", "Switzerland", "France",
        "Spain", "Sweden", "UAE", "Japan",
    ]

    /// Every ISO country, localized — for the debounced search.
    static let allCountries: [String] = {
        Locale.Region.isoRegions
            .filter { $0.identifier.count == 2 }
            .compactMap { Locale.current.localizedString(forRegionCode: $0.identifier) }
            .sorted()
    }()
}
