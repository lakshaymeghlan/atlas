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
                      "Design-led culture fits your background"]),
        JobMatch(
            role: "Mobile Engineer, iOS", company: "Cadence", location: "Berlin · Hybrid",
            match: 91, salary: "€85k–105k", tags: ["Swift", "Core Data"],
            about: "Cadence is a health-tech company helping clinics run smoothly. Their iOS app is used daily by thousands of practitioners.",
            industry: "Health tech", size: "200–500", stage: "Series C",
            reasons: ["Core Data experience is a direct match",
                      "Berlin-based, where you are",
                      "Mature product with real users"]),
        JobMatch(
            role: "Lead Product Engineer", company: "Fieldnotes", location: "Remote",
            match: 88, salary: "€110k–140k", tags: ["Swift", "Leadership", "Design"],
            about: "Fieldnotes makes a beloved note-taking app. They're hiring a lead to shape both the product and a small iOS team.",
            industry: "Consumer", size: "10–50", stage: "Seed",
            reasons: ["Step up into leadership",
                      "Design sensibility valued here",
                      "Fully remote"]),
        JobMatch(
            role: "iOS & Design Systems", company: "Arc Labs", location: "Amsterdam",
            match: 85, salary: "€90k–115k", tags: ["SwiftUI", "Figma"],
            about: "Arc Labs builds a cross-platform design-systems toolkit. You'd bridge Figma and SwiftUI to keep design and code in sync.",
            industry: "Developer tools", size: "50–200", stage: "Series A",
            reasons: ["Your Figma + SwiftUI combo is rare and wanted",
                      "Design-systems focus",
                      "Amsterdam, a short hop from Berlin"]),
    ]
}
