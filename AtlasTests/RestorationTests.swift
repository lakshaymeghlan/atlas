import XCTest
@testable import Atlas

final class RestorationTests: XCTestCase {
    func testNoSessionGoesToWelcome() {
        XCTAssertEqual(AppRouter.initialState(isSignedIn: false, profile: UserProfile()), .welcome)
    }

    func testSignedInButNothingDoneGoesToCareerPath() {
        XCTAssertEqual(AppRouter.initialState(isSignedIn: true, profile: UserProfile()), .careerPath)
    }

    func testCareerChosenResumesAtUpload() {
        var p = UserProfile()
        p.careerPath = .seeking
        XCTAssertEqual(AppRouter.initialState(isSignedIn: true, profile: p), .uploadCV)
    }

    func testParsedContentResumesAtConfirm() {
        var p = UserProfile()
        p.careerPath = .seeking
        p.skills = [Skill(name: "Swift")]
        XCTAssertEqual(AppRouter.initialState(isSignedIn: true, profile: p), .confirmProfile)
    }

    func testOnboardedGoesHome() {
        var p = UserProfile()
        p.careerPath = .seeking
        p.onboardedAt = Date()
        XCTAssertEqual(AppRouter.initialState(isSignedIn: true, profile: p), .home)
    }
}
