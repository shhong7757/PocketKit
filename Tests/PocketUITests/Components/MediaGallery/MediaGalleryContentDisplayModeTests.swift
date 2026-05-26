import XCTest

@testable import PocketUI

final class MediaGalleryContentDisplayModeTests: XCTestCase {
    func testFillUsesContainerSize() {
        let containerSize = CGSize(width: 90, height: 120)

        XCTAssertEqual(
            MediaGalleryContentDisplayMode.fill.contentSize(
                aspectRatio: 16.0 / 9.0,
                in: containerSize
            ),
            containerSize
        )
    }

    func testFitUsesItemAspectRatioInsideContainer() {
        XCTAssertEqual(
            MediaGalleryContentDisplayMode.fit.contentSize(
                aspectRatio: 16.0 / 9.0,
                in: CGSize(width: 120, height: 120)
            ),
            CGSize(width: 120, height: 67.5)
        )
    }

    func testFitConstrainsPortraitContentInsideWideContainer() {
        XCTAssertEqual(
            MediaGalleryContentDisplayMode.fit.contentSize(
                aspectRatio: 3.0 / 4.0,
                in: CGSize(width: 200, height: 100)
            ),
            CGSize(width: 75, height: 100)
        )
    }

    func testFitUsesContainerSizeWhenItemHasNoAspectRatio() {
        let containerSize = CGSize(width: 120, height: 120)

        XCTAssertEqual(
            MediaGalleryContentDisplayMode.fit.contentSize(
                aspectRatio: nil,
                in: containerSize
            ),
            containerSize
        )
    }

    func testFitIgnoresInvalidAspectRatio() {
        let containerSize = CGSize(width: 120, height: 120)

        XCTAssertEqual(
            MediaGalleryContentDisplayMode.fit.contentSize(
                aspectRatio: 0,
                in: containerSize
            ),
            containerSize
        )
    }

    func testDisplayModesReturnZeroForEmptyContainers() {
        XCTAssertEqual(
            MediaGalleryContentDisplayMode.fill.contentSize(
                aspectRatio: 1,
                in: CGSize(width: 0, height: 120)
            ),
            .zero
        )
        XCTAssertEqual(
            MediaGalleryContentDisplayMode.fit.contentSize(
                aspectRatio: 1,
                in: CGSize(width: 120, height: 0)
            ),
            .zero
        )
    }
}
