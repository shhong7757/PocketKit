import CoreGraphics

/// 고정된 그리드 셀 안에서 미디어 갤러리 콘텐츠를 표시하는 방식을 설명합니다.
public enum MediaGalleryContentDisplayMode: Hashable, Sendable {
    /// 콘텐츠가 전체 그리드 셀을 채우도록 크기를 조정합니다.
    case fill

    /// 콘텐츠의 가로세로 비율을 사용해 그리드 셀 안에 맞도록 크기를 조정합니다.
    case fit

    func contentSize(
        aspectRatio: CGFloat?,
        in containerSize: CGSize
    ) -> CGSize {
        guard containerSize.width > 0,
            containerSize.height > 0
        else {
            return .zero
        }

        switch self {
        case .fill:
            return containerSize
        case .fit:
            return fittedContentSize(
                aspectRatio: aspectRatio,
                in: containerSize
            )
        }
    }

    private func fittedContentSize(
        aspectRatio: CGFloat?,
        in containerSize: CGSize
    ) -> CGSize {
        guard let aspectRatio,
            aspectRatio > 0
        else {
            return containerSize
        }

        let containerAspectRatio = containerSize.width / containerSize.height

        if containerAspectRatio > aspectRatio {
            let height = containerSize.height
            return CGSize(width: height * aspectRatio, height: height)
        }

        let width = containerSize.width
        return CGSize(width: width, height: width / aspectRatio)
    }
}
