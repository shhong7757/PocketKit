import CoreGraphics
import SwiftUI

/// 갤러리의 그리드 레이아웃과 표시 옵션입니다.
public struct GalleryLayout: Hashable, Sendable {
    /// 고정된 갤러리 셀 안에서 항목 콘텐츠를 표시하는 방식입니다.
    public enum ContentDisplayMode: Hashable, Sendable {
        /// 콘텐츠가 전체 그리드 셀을 채우도록 크기를 조정합니다.
        case fill

        /// 콘텐츠의 가로세로 비율을 사용해 그리드 셀 안에 맞도록 크기를 조정합니다.
        case fit

        func resolvedContentSize(
            contentAspectRatio: CGFloat?,
            in containerSize: CGSize
        ) -> CGSize {
            guard containerSize.width.isFinite,
                containerSize.height.isFinite,
                containerSize.width > 0,
                containerSize.height > 0
            else {
                return .zero
            }

            switch self {
            case .fill:
                return containerSize
            case .fit:
                return Self.aspectFitContentSize(
                    contentAspectRatio: contentAspectRatio,
                    in: containerSize
                )
            }
        }

        private static func aspectFitContentSize(
            contentAspectRatio: CGFloat?,
            in containerSize: CGSize
        ) -> CGSize {
            guard let contentAspectRatio,
                contentAspectRatio.isFinite,
                contentAspectRatio > 0
            else {
                // 콘텐츠 비율을 알 수 없으면 컨테이너 크기를 대신 사용합니다.
                return containerSize
            }

            let containerAspectRatio = containerSize.width / containerSize.height

            if containerAspectRatio > contentAspectRatio {
                let height = containerSize.height
                return CGSize(width: height * contentAspectRatio, height: height)
            }

            let width = containerSize.width
            return CGSize(width: width, height: width / contentAspectRatio)
        }
    }

    /// 갤러리 컨테이너 안쪽 콘텐츠 둘레에 적용할 여백입니다.
    public struct Insets: Hashable, Sendable {
        /// 위쪽 여백입니다.
        public let top: CGFloat

        /// leading 가장자리 여백입니다.
        public let leading: CGFloat

        /// 아래쪽 여백입니다.
        public let bottom: CGFloat

        /// trailing 가장자리 여백입니다.
        public let trailing: CGFloat

        /// 모든 가장자리에 0pt 여백을 적용합니다.
        public static let zero = Insets()

        /// 모든 가장자리에 같은 여백을 적용합니다.
        public static func all(_ value: CGFloat) -> Insets {
            Insets(
                top: value,
                leading: value,
                bottom: value,
                trailing: value
            )
        }

        /// leading과 trailing 가장자리에 같은 여백을 적용합니다.
        public static func horizontal(_ value: CGFloat) -> Insets {
            Insets(
                leading: value,
                trailing: value
            )
        }

        /// 위쪽과 아래쪽 가장자리에 같은 여백을 적용합니다.
        public static func vertical(_ value: CGFloat) -> Insets {
            Insets(
                top: value,
                bottom: value
            )
        }

        /// 갤러리 콘텐츠 여백을 만듭니다.
        public init(
            top: CGFloat = 0,
            leading: CGFloat = 0,
            bottom: CGFloat = 0,
            trailing: CGFloat = 0
        ) {
            self.top = top
            self.leading = leading
            self.bottom = bottom
            self.trailing = trailing
        }

        var resolved: Insets {
            Insets(
                top: nonNegativeFiniteValue(top),
                leading: nonNegativeFiniteValue(leading),
                bottom: nonNegativeFiniteValue(bottom),
                trailing: nonNegativeFiniteValue(trailing)
            )
        }

        var edgeInsets: EdgeInsets {
            let resolvedInsets = resolved

            return EdgeInsets(
                top: resolvedInsets.top,
                leading: resolvedInsets.leading,
                bottom: resolvedInsets.bottom,
                trailing: resolvedInsets.trailing
            )
        }
    }

    /// 그리드 항목 사이의 간격입니다.
    public let spacing: CGFloat

    /// 적응형 열의 최소 너비입니다.
    public let minimumColumnWidth: CGFloat

    /// 적응형 열의 최대 너비입니다.
    public let maximumColumnWidth: CGFloat

    /// 각 그리드 셀의 가로세로 비율입니다.
    public let cellAspectRatio: CGFloat

    /// 셀 안에서 항목 콘텐츠를 표시하는 방식입니다.
    public let contentMode: ContentDisplayMode

    /// 갤러리 콘텐츠 둘레에 적용할 여백입니다.
    public let contentInsets: Insets

    /// 포함된 스크롤 뷰가 플랫폼 스크롤 인디케이터를 표시할지 여부입니다.
    public let showsScrollIndicators: Bool

    /// PocketUI의 기본 갤러리 레이아웃입니다.
    public static let standard = GalleryLayout()

    /// 갤러리 레이아웃을 만듭니다.
    ///
    /// 값은 사용 전에 보정됩니다. 간격과 콘텐츠 여백은 0 이상으로, 열 너비는 양수로
    /// 보정되며 올바르지 않은 비율은 정사각형 셀로 대체됩니다.
    public init(
        spacing: CGFloat = .space1,
        minimumColumnWidth: CGFloat = 110,
        maximumColumnWidth: CGFloat = 170,
        cellAspectRatio: CGFloat = 1,
        contentMode: ContentDisplayMode = .fill,
        contentInsets: Insets? = nil,
        showsScrollIndicators: Bool = false
    ) {
        self.spacing = spacing
        self.minimumColumnWidth = minimumColumnWidth
        self.maximumColumnWidth = maximumColumnWidth
        self.cellAspectRatio = cellAspectRatio
        self.contentMode = contentMode
        self.contentInsets = contentInsets ?? .all(spacing)
        self.showsScrollIndicators = showsScrollIndicators
    }

    var resolvedSpacing: CGFloat {
        nonNegativeFiniteValue(spacing)
    }

    var resolvedMinimumColumnWidth: CGFloat {
        positiveFiniteValue(minimumColumnWidth) ?? 1
    }

    var resolvedMaximumColumnWidth: CGFloat {
        guard let maximumColumnWidth = positiveFiniteValue(maximumColumnWidth)
        else {
            return resolvedMinimumColumnWidth
        }

        return max(resolvedMinimumColumnWidth, maximumColumnWidth)
    }

    var resolvedCellAspectRatio: CGFloat {
        positiveFiniteValue(cellAspectRatio) ?? 1
    }

    var resolvedContentInsets: Insets {
        contentInsets.resolved
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

private func nonNegativeFiniteValue(_ value: CGFloat) -> CGFloat {
    guard value.isFinite else { return 0 }

    return max(0, value)
}

private func positiveFiniteValue(_ value: CGFloat) -> CGFloat? {
    guard value.isFinite, value > 0 else { return nil }

    return value
}
