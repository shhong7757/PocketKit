import CoreGraphics
import SwiftUI

/// ``MediaGalleryView``의 레이아웃 설정입니다.
public struct MediaGalleryLayout: Hashable, Sendable {
    /// 그리드 항목 사이와 그리드 콘텐츠 주변의 간격입니다.
    public var spacing: CGFloat

    /// 적응형 열의 최소 너비입니다.
    public var minimumColumnWidth: CGFloat

    /// 적응형 열의 최대 너비입니다.
    public var maximumColumnWidth: CGFloat

    /// 각 그리드 셀의 가로세로 비율입니다.
    public var cellAspectRatio: CGFloat

    /// 포함된 스크롤 뷰가 플랫폼 스크롤 인디케이터를 표시할지 여부입니다.
    public var showsScrollIndicators: Bool

    /// PocketUI의 기본 미디어 그리드 레이아웃입니다.
    public static let standard = MediaGalleryLayout()

    /// 미디어 그리드 레이아웃 설정을 만듭니다.
    ///
    /// 값은 사용 전에 보정됩니다. 간격은 0 이상으로, 열 너비는 양수로 보정되며
    /// 올바르지 않은 비율은 정사각형 셀로 대체됩니다.
    ///
    /// - Parameters:
    ///   - spacing: 그리드 항목 사이와 그리드 콘텐츠 주변의 간격입니다.
    ///   - minimumColumnWidth: 적응형 그리드 열의 최소 너비입니다.
    ///   - maximumColumnWidth: 적응형 그리드 열의 최대 너비입니다.
    ///   - cellAspectRatio: 각 그리드 셀의 가로세로 비율입니다.
    ///   - showsScrollIndicators: 그리드 스크롤 뷰가 인디케이터를 표시할지 여부입니다.
    public init(
        spacing: CGFloat = 4,
        minimumColumnWidth: CGFloat = 110,
        maximumColumnWidth: CGFloat = 170,
        cellAspectRatio: CGFloat = 1,
        showsScrollIndicators: Bool = false
    ) {
        self.spacing = spacing
        self.minimumColumnWidth = minimumColumnWidth
        self.maximumColumnWidth = maximumColumnWidth
        self.cellAspectRatio = cellAspectRatio
        self.showsScrollIndicators = showsScrollIndicators
    }

    var resolvedSpacing: CGFloat {
        max(0, spacing)
    }

    var resolvedMinimumColumnWidth: CGFloat {
        max(1, minimumColumnWidth)
    }

    var resolvedMaximumColumnWidth: CGFloat {
        max(resolvedMinimumColumnWidth, maximumColumnWidth)
    }

    var resolvedCellAspectRatio: CGFloat {
        guard cellAspectRatio > 0 else { return 1 }
        return cellAspectRatio
    }

    var columns: [GridItem] {
        [
            GridItem(
                .adaptive(
                    minimum: resolvedMinimumColumnWidth,
                    maximum: resolvedMaximumColumnWidth
                ),
                spacing: resolvedSpacing
            )
        ]
    }
}
