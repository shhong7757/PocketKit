import XCTest

@testable import PocketUI

final class GalleryLayoutContentDisplayModeTests: XCTestCase {
    func testFitPreservesWideContentAspectRatioInsideSquareContainer() {
        XCTAssertEqual(
            GalleryLayout.ContentDisplayMode.fit.resolvedContentSize(
                contentAspectRatio: 16.0 / 9.0,
                in: CGSize(width: 120, height: 120)
            ),
            CGSize(width: 120, height: 67.5)
        )
    }

    func testFitPreservesPortraitContentAspectRatioInsideWideContainer() {
        XCTAssertEqual(
            GalleryLayout.ContentDisplayMode.fit.resolvedContentSize(
                contentAspectRatio: 3.0 / 4.0,
                in: CGSize(width: 200, height: 100)
            ),
            CGSize(width: 75, height: 100)
        )
    }

    func testFitFallsBackToContainerSizeWhenContentAspectRatioIsUnavailable() {
        let containerSize = CGSize(width: 120, height: 120)

        XCTAssertEqual(
            GalleryLayout.ContentDisplayMode.fit.resolvedContentSize(
                contentAspectRatio: nil,
                in: containerSize
            ),
            containerSize
        )
        XCTAssertEqual(
            GalleryLayout.ContentDisplayMode.fit.resolvedContentSize(
                contentAspectRatio: 0,
                in: containerSize
            ),
            containerSize
        )
        XCTAssertEqual(
            GalleryLayout.ContentDisplayMode.fit.resolvedContentSize(
                contentAspectRatio: .infinity,
                in: containerSize
            ),
            containerSize
        )
    }

    func testContentModesReturnZeroForInvalidContainers() {
        XCTAssertEqual(
            GalleryLayout.ContentDisplayMode.fill.resolvedContentSize(
                contentAspectRatio: 1,
                in: CGSize(width: 0, height: 120)
            ),
            .zero
        )
        XCTAssertEqual(
            GalleryLayout.ContentDisplayMode.fit.resolvedContentSize(
                contentAspectRatio: 1,
                in: CGSize(width: 120, height: CGFloat.nan)
            ),
            .zero
        )
    }
}
