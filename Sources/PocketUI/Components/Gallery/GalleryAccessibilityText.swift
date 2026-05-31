import Foundation

enum GalleryAccessibilityText {
    static var fetchingNextPage: String {
        String(
            localized: "Fetching next page",
            bundle: .module,
            comment: "갤러리 다음 페이지 로딩 표시기의 접근성 라벨"
        )
    }

    static var selected: String {
        String(
            localized: "Selected",
            bundle: .module,
            comment: "선택된 갤러리 항목의 접근성 값"
        )
    }

    static var notSelected: String {
        String(
            localized: "Not selected",
            bundle: .module,
            comment: "선택되지 않은 갤러리 항목의 접근성 값"
        )
    }

    static var opensItem: String {
        String(
            localized: "Opens this item",
            bundle: .module,
            comment: "갤러리 항목을 여는 동작의 접근성 힌트"
        )
    }

    static var selectsItem: String {
        String(
            localized: "Selects this item",
            bundle: .module,
            comment: "갤러리 항목을 선택하는 동작의 접근성 힌트"
        )
    }

    static var deselectsItem: String {
        String(
            localized: "Deselects this item",
            bundle: .module,
            comment: "갤러리 항목 선택을 해제하는 동작의 접근성 힌트"
        )
    }
}
