import Foundation

/// A role Atlas matched to the person, with the company detail shown on the back
/// of the card. Prototype data; the real matching engine produces these later.
struct JobMatch: Identifiable, Equatable {
    let id = UUID()
    var role: String
    var company: String
    var location: String
    var match: Int          // 0–100, how well it fits
    var salary: String?
    var tags: [String]

    // Company detail (card back)
    var about: String
    var industry: String
    var size: String
    var stage: String
    var reasons: [String]   // why Atlas thinks it fits

    /// What this company tends to ask — so you know what to study. Shown on the
    /// Journey tab once you're in their pipeline.
    var prepTopics: [String] = []
}

extension JobMatch {
    static let samples: [JobMatch] = [
        JobMatch(
            role: "Senior iOS Engineer", company: "Lumen", location: "Remote · EU",
            match: 94, salary: "€95k–120k", tags: ["Swift", "SwiftUI", "Observation"],
            about: "Lumen builds calm, focused productivity tools for deep work. Small, design-led engineering team that ships weekly.",
            industry: "Productivity", size: "50–200", stage: "Series B",
            reasons: ["Deep SwiftUI + Observation work, like yours",
                      "Remote-first, matching your last role",
                      "Design-led culture fits your background"],
            prepTopics: ["Swift concurrency", "SwiftUI & Observation", "App architecture (MV)", "System design", "Live coding: a small feature"]),
        JobMatch(
            role: "Mobile Engineer, iOS", company: "Cadence", location: "Berlin · Hybrid",
            match: 91, salary: "€85k–105k", tags: ["Swift", "Core Data"],
            about: "Cadence is a health-tech company helping clinics run smoothly. Their iOS app is used daily by thousands of practitioners.",
            industry: "Health tech", size: "200–500", stage: "Series C",
            reasons: ["Core Data experience is a direct match",
                      "Berlin-based, where you are",
                      "Mature product with real users"],
            prepTopics: ["Core Data & persistence", "REST + offline sync", "Swift concurrency", "Debugging a crash", "Behavioral: teamwork"]),
        JobMatch(
            role: "Lead Product Engineer", company: "Fieldnotes", location: "Remote",
            match: 88, salary: "€110k–140k", tags: ["Swift", "Leadership", "Design"],
            about: "Fieldnotes makes a beloved note-taking app. They're hiring a lead to shape both the product and a small iOS team.",
            industry: "Consumer", size: "10–50", stage: "Seed",
            reasons: ["Step up into leadership",
                      "Design sensibility valued here",
                      "Fully remote"],
            prepTopics: ["Team leadership", "System & product design", "SwiftUI at scale", "Roadmap & prioritization", "Past project deep-dive"]),
        JobMatch(
            role: "iOS & Design Systems", company: "Arc Labs", location: "Amsterdam",
            match: 85, salary: "€90k–115k", tags: ["SwiftUI", "Figma"],
            about: "Arc Labs builds a cross-platform design-systems toolkit. You'd bridge Figma and SwiftUI to keep design and code in sync.",
            industry: "Developer tools", size: "50–200", stage: "Series A",
            reasons: ["Your Figma + SwiftUI combo is rare and wanted",
                      "Design-systems focus",
                      "Amsterdam, a short hop from Berlin"],
            prepTopics: ["SwiftUI layout system", "Figma → SwiftUI tokens", "Design-systems architecture", "Accessibility", "Portfolio walkthrough"]),
    ]
}

// MARK: - Application pipeline (Journey tab)

/// Where an application stands. Ordered; the current stage and everything before
/// it read as done.
enum PipelineStage: Int, CaseIterable, Identifiable {
    case applied, screening, interviewing, roundTwo, offer
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .applied: "Applied"
        case .screening: "Selected for interview"
        case .interviewing: "Interviewing"
        case .roundTwo: "Interview round 2"
        case .offer: "Final decision"
        }
    }

    /// Compact label for the horizontal tracker.
    var short: String {
        switch self {
        case .applied: "Applied"
        case .screening: "Screening"
        case .interviewing: "Interview"
        case .roundTwo: "Round 2"
        case .offer: "Decision"
        }
    }
}

/// A company you're in the pipeline with — the match plus its current stage.
struct Application: Identifiable {
    var match: JobMatch
    var stage: PipelineStage
    var id: UUID { match.id }
}

extension Application {
    /// Seeded so the Journey tab has content in the prototype; accepting a role
    /// in Jobs appends a new one at `.applied`.
    static let samples: [Application] = [
        Application(match: JobMatch(
            role: "Senior iOS Engineer", company: "Northwind", location: "Remote · EU",
            match: 92, salary: "€100k–125k", tags: ["Swift", "SwiftUI"],
            about: "Northwind builds logistics software used across Europe.",
            industry: "Logistics", size: "200–500", stage: "Series C",
            reasons: ["Strong SwiftUI match", "Remote-first"],
            prepTopics: ["Swift concurrency", "SwiftUI performance", "System design", "Behavioral: ownership"]),
            stage: .interviewing),
        Application(match: JobMatch(
            role: "Mobile Engineer", company: "Halcyon", location: "Berlin · Hybrid",
            match: 89, salary: "€90k–110k", tags: ["Swift", "Core Data"],
            about: "Halcyon is a fintech making saving effortless.",
            industry: "Fintech", size: "50–200", stage: "Series B",
            reasons: ["Core Data match", "Berlin-based"],
            prepTopics: ["Core Data", "Security & auth", "Unit testing", "Take-home review"]),
            stage: .screening),
        Application(match: JobMatch(
            role: "Product Engineer", company: "Verdant", location: "Amsterdam",
            match: 87, salary: "€95k–120k", tags: ["SwiftUI", "Product"],
            about: "Verdant builds climate tooling for enterprises.",
            industry: "Climate", size: "10–50", stage: "Seed",
            reasons: ["Product sensibility", "Mission fit"],
            prepTopics: ["Product thinking", "SwiftUI", "APIs & data modeling", "Founder interview"]),
            stage: .roundTwo),
    ]
}
