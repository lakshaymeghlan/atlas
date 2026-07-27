import XCTest
@testable import Atlas

final class CVValidationTests: XCTestCase {
    func testAcceptsPDFAndDOCX() {
        XCTAssertNil(CVValidation.validate(filename: "cv.pdf", byteSize: 1_000))
        XCTAssertNil(CVValidation.validate(filename: "Resume.DOCX", byteSize: 1_000))
    }

    func testRejectsWrongType() {
        XCTAssertEqual(CVValidation.validate(filename: "cv.pages", byteSize: 1_000), .wrongType)
        XCTAssertEqual(CVValidation.validate(filename: "noextension", byteSize: 1_000), .wrongType)
    }

    func testRejectsEmpty() {
        XCTAssertEqual(CVValidation.validate(filename: "cv.pdf", byteSize: 0), .empty)
    }

    func testRejectsTooLarge() {
        XCTAssertEqual(CVValidation.validate(filename: "cv.pdf", byteSize: CVValidation.maxBytes + 1), .tooLarge)
    }

    func testAcceptsExactlyMaxSize() {
        XCTAssertNil(CVValidation.validate(filename: "cv.pdf", byteSize: CVValidation.maxBytes))
    }
}
