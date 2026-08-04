import Foundation

/// The onboarding journey. The stage titles feed the progress indicator on every
/// onboarding screen and are shared so the labels never drift.
enum Journey {
    /// The three visible stages, in order. Welcome sits before stage 0.
    static let stageTitles = ["upload", "roles", "confirm"]
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
    case link(String)

    var displayName: String {
        switch self {
        case .file(let cv): return cv.filename
        case .link(let url): return url
        }
    }
}

/// The journey state machine — a small enum, not a pile of booleans.
enum JourneyState: Equatable {
    case launching
    case welcome
    case uploadCV
    case analysing(source: CVSource)
    case rolePreferences
    case confirmProfile
    case home
}
