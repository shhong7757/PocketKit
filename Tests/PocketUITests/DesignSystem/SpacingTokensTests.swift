import XCTest

@testable import PocketUI

final class SpacingTokensTests: XCTestCase {
    func testSpacingTokensUseExpectedScale() {
        XCTAssertEqual(CGFloat.space0, 0)
        XCTAssertEqual(CGFloat.space0_5, 2)
        XCTAssertEqual(CGFloat.space1, 4)
        XCTAssertEqual(CGFloat.space2, 8)
        XCTAssertEqual(CGFloat.space3, 12)
        XCTAssertEqual(CGFloat.space4, 16)
        XCTAssertEqual(CGFloat.space5, 20)
        XCTAssertEqual(CGFloat.space6, 24)
        XCTAssertEqual(CGFloat.space8, 32)
        XCTAssertEqual(CGFloat.space10, 40)
    }
}
