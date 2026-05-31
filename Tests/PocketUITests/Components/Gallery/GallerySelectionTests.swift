import SwiftUI
import XCTest

@testable import PocketUI

final class GallerySelectionTests: XCTestCase {
    @MainActor
    func testMultipleSelectionTogglesSelectedIDs() {
        var selectedIDs: Set<String> = []
        let selection = GallerySelection.multiple(
            Binding {
                selectedIDs
            } set: { ids in
                selectedIDs = ids
            }
        )

        XCTAssertTrue(selection.toggleSelection(for: "first"))
        XCTAssertTrue(selection.toggleSelection(for: "second"))
        XCTAssertTrue(selection.toggleSelection(for: "first"))

        XCTAssertEqual(selectedIDs, ["second"])
        XCTAssertTrue(selection.contains("second"))
        XCTAssertFalse(selection.contains("first"))
    }

    @MainActor
    func testNoneSelectionIgnoresSelectionUpdates() {
        let selection = GallerySelection<String>.none

        XCTAssertFalse(selection.toggleSelection(for: "first"))

        XCTAssertFalse(selection.contains("first"))
    }
}
