import Foundation

/// The onboarding journey. `JourneyState` (the router's state machine) is added
/// in Step 6; the stage titles feed the `Current` river on every onboarding
/// screen and are shared so the labels never drift.
enum Journey {
    /// The three visible stages, in order. Welcome sits before stage 0.
    static let stageTitles = ["career path", "upload CV", "confirm profile"]
}
