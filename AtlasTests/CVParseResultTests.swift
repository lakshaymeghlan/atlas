import XCTest
@testable import Atlas

final class CVParseResultTests: XCTestCase {
    func testDecodesSampleCV() throws {
        let result = try CVParseResult.decode(MockCVParser.sampleJSON)
        XCTAssertEqual(result.fullName, "Jordan Rivera")
        XCTAssertEqual(result.experiences.count, 3)
        XCTAssertEqual(result.experiences.first?.role, "Senior Product Designer")
        XCTAssertNil(result.experiences.first?.endDate) // current role
        XCTAssertEqual(result.education.count, 2)
        XCTAssertEqual(result.skills.count, 8)
        XCTAssertEqual(result.languages.last?.name, "Spanish")
        XCTAssertNil(result.languages.last?.level)
    }

    func testSnakeCaseKeysMapToCamelCase() throws {
        let json = """
        { "full_name": "A", "headline": null, "location": null,
          "experiences": [{ "role": "R", "company": "C", "start_date": "2021",
                            "end_date": null, "description": null, "confidence": 0.9 }],
          "education": [], "skills": [], "languages": [] }
        """
        let result = try CVParseResult.decode(json)
        XCTAssertEqual(result.experiences.first?.startDate, "2021")
    }

    func testMalformedJSONThrows() {
        XCTAssertThrowsError(try CVParseResult.decode("{ this is not json"))
    }

    func testMissingRequiredFieldThrows() {
        // An experience without the required `company` must not silently decode.
        let json = """
        { "full_name": "A", "headline": null, "location": null,
          "experiences": [{ "role": "R", "confidence": 0.9 }],
          "education": [], "skills": [], "languages": [] }
        """
        XCTAssertThrowsError(try CVParseResult.decode(json))
    }
}
