import Foundation

/// The onboarding journey. The stage titles feed the `Current` river on every
/// onboarding screen and are shared so the labels never drift.
enum Journey {
    /// The three visible stages, in order. Welcome sits before stage 0.
    static let stageTitles = ["career path", "upload CV", "confirm profile"]
}

/// A CV the user picked from Files. In the prototype the bytes ride along in
/// memory; with the real backend this is uploaded to Storage and only its id
/// travels in `JourneyState`.
struct PickedCV: Equatable {
    var filename: String
    var byteSize: Int
    var data: Data
}

/// The journey state machine — a small enum, not a pile of booleans.
enum JourneyState: Equatable {
    case launching
    case welcome
    case careerPath
    case uploadCV
    case analysing(cv: PickedCV)
    case confirmProfile
    case home
}
