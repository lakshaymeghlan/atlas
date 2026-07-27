import XCTest
import SwiftUI
@testable import Atlas

// Real tests land in Step 12: CV JSON decoder, JourneyState restoration, file
// validation.
final class AtlasSmokeTests: XCTestCase {
    func testPaletteHexParsing() {
        // Sanity check the hex initialiser the whole palette depends on.
        XCTAssertEqual(Color(hex: "#F5F4F0"), Color(hex: "F5F4F0"))
    }
}
