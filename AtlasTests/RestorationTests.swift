import XCTest
@testable import Atlas

final class RestorationTests: XCTestCase {
    /// A profile that has been through the CV step.
    private func parsed() -> UserProfile {
        var p = UserProfile()
        p.skills = [Skill(name: "Swift")]
        return p
    }

    /// Every required wizard answer filled in.
    private func completedPreferences() -> JobPreferences {
        var prefs = JobPreferences()
        prefs.hobbies = ["Coding"]
        prefs.arrangements = [.remote]
        prefs.workTypes = [.fullTime]
        prefs.openToAnywhere = true
        prefs.startAvailability = .immediately
        return prefs
    }

    func testNoSessionGoesToWelcome() {
        XCTAssertEqual(AppRouter.initialState(isSignedIn: false, profile: UserProfile()), .welcome)
    }

    func testSignedInWithNothingStartsAtUpload() {
        XCTAssertEqual(AppRouter.initialState(isSignedIn: true, profile: UserProfile()), .uploadCV)
    }

    func testParsedContentResumesInThePreferencesWizard() {
        XCTAssertEqual(AppRouter.initialState(isSignedIn: true, profile: parsed()), .preferences)
    }

    func testPartlyAnsweredPreferencesStayInTheWizard() {
        var p = parsed()
        p.preferences = completedPreferences()
        p.preferences.startAvailability = nil          // last step unanswered
        XCTAssertEqual(AppRouter.initialState(isSignedIn: true, profile: p), .preferences)
    }

    func testCompletedPreferencesResumeAtTheProfileReview() {
        var p = parsed()
        p.preferences = completedPreferences()
        XCTAssertEqual(AppRouter.initialState(isSignedIn: true, profile: p), .confirmProfile)
    }

    func testOnboardedGoesHome() {
        var p = parsed()
        p.preferences = completedPreferences()
        p.onboardedAt = Date()
        XCTAssertEqual(AppRouter.initialState(isSignedIn: true, profile: p), .home)
    }
}
