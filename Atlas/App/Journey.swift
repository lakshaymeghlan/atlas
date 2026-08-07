import Foundation

/// The onboarding journey. The stage titles feed the progress indicator on every
/// onboarding screen and are shared so the labels never drift.
enum Journey {
    /// Total onboarding steps, for the progress bar: upload (0) · seven preference
    /// steps (1–7) · profile review (8).
    static let onboardingSteps = 9
}

/// A CV the user picked from Files. In the prototype the bytes ride along in
/// memory; with the real backend this is uploaded to Storage.
struct PickedCV: Equatable {
    var filename: String
    var byteSize: Int
    var data: Data
}

/// What the user gave Atlas to build a profile from — a file or a link. Both feed
/// the same extraction step (the real backend reads either; the mock ignores it).
enum CVSource: Equatable {
    case file(PickedCV)
    case linkedIn

    var displayName: String {
        switch self {
        case .file(let cv): return cv.filename
        case .linkedIn: return "LinkedIn"
        }
    }
}

/// The journey state machine — a small enum, not a pile of booleans.
enum JourneyState: Equatable {
    case launching
    case welcome
    case chooseIntent
    case uploadCV
    case analysing(source: CVSource)
    case preferences
    case rolePreferences
    case confirmProfile
    case home
}
