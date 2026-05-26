import XCTest

@testable import PocketUI

final class PocketUISpacingTests: XCTestCase {
    func testSpacingTokensUseExpectedScale() {
        XCTAssertEqual(PocketUISpacing.space0, 0)
        XCTAssertEqual(PocketUISpacing.spaceHalf, 2)
        XCTAssertEqual(PocketUISpacing.space1, 4)
        XCTAssertEqual(PocketUISpacing.space2, 8)
        XCTAssertEqual(PocketUISpacing.space3, 12)
        XCTAssertEqual(PocketUISpacing.space4, 16)
        XCTAssertEqual(PocketUISpacing.space5, 20)
        XCTAssertEqual(PocketUISpacing.space6, 24)
        XCTAssertEqual(PocketUISpacing.space8, 32)
        XCTAssertEqual(PocketUISpacing.space10, 40)
    }
}
