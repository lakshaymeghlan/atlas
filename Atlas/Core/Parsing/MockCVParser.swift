import Foundation

enum CVParseError: LocalizedError, Equatable {
    case imageOnly   // scanned-image PDF, no extractable text
    case decoding

    var errorDescription: String? {
        switch self {
        case .imageOnly: return "Some PDFs are images rather than text."
        case .decoding: return "That response couldn't be read."
        }
    }
}

/// Stand-in for the `parse-cv` edge function. Waits, then returns a canned
/// result decoded through the *real* `CVParseResult.decode`, so the decoder and
/// everything downstream are production-shaped. Filename hooks let you demo the
/// other paths: include "scan"/"image"/"photo" to see the failure state, or
/// "slow" to see the >12s long-running copy.
enum MockCVParser {
    static func parse(_ cv: PickedCV) async throws -> CVParseResult {
        let name = cv.filename.lowercased()

        if name.contains("scan") || name.contains("image") || name.contains("photo") {
            try? await Task.sleep(for: .seconds(1.2))
            throw CVParseError.imageOnly
        }

        try? await Task.sleep(for: .seconds(name.contains("slow") ? 14 : 1.8))

        do {
            return try CVParseResult.decode(sampleJSON)
        } catch {
            throw CVParseError.decoding
        }
    }

    /// Canned CV. Most-recent-first, a low-confidence role and skill (to exercise
    /// the blue-dot sort), and null fields (to exercise the "Add …" affordance).
    static let sampleJSON = """
    {
      "full_name": "Jordan Rivera",
      "headline": "Product designer focused on tools for people in transition",
      "location": "Berlin, Germany",
      "experiences": [
        {
          "role": "Senior Product Designer",
          "company": "Riverbank",
          "start_date": "2022",
          "end_date": null,
          "description": "Led design for the onboarding and activation surfaces.",
          "confidence": 0.95
        },
        {
          "role": "Product Designer",
          "company": "Northwind Labs",
          "start_date": "2019",
          "end_date": "2022",
          "description": "Shipped the mobile redesign and the design system.",
          "confidence": 0.9
        },
        {
          "role": "Freelance Designer",
          "company": "Self-employed",
          "start_date": "2018",
          "end_date": "2019",
          "description": null,
          "confidence": 0.5
        }
      ],
      "education": [
        {
          "institution": "University of the Arts",
          "degree": "BA",
          "field": "Communication Design",
          "start_year": "2014",
          "end_year": "2018",
          "confidence": 0.92
        },
        {
          "institution": "Lincoln High School",
          "degree": null,
          "field": null,
          "start_year": null,
          "end_year": "2014",
          "confidence": 0.6
        }
      ],
      "skills": [
        { "name": "Product design", "confidence": 0.97 },
        { "name": "Figma", "confidence": 0.96 },
        { "name": "Design systems", "confidence": 0.94 },
        { "name": "Prototyping", "confidence": 0.9 },
        { "name": "User research", "confidence": 0.88 },
        { "name": "SwiftUI", "confidence": 0.7 },
        { "name": "Accessibility", "confidence": 0.82 },
        { "name": "Motion design", "confidence": 0.45 }
      ],
      "languages": [
        { "name": "English", "level": "Native" },
        { "name": "German", "level": "Professional" },
        { "name": "Spanish", "level": null }
      ]
    }
    """
}
