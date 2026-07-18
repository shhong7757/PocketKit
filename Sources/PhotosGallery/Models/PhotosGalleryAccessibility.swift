/// Accessibility information for a PhotosGallery content item.
public struct PhotosGalleryAccessibility: Sendable, Equatable {
    /// Identifies the content item.
    public let label: String

    /// Describes additional metadata or state for the content item.
    public let value: String?

    /// 접근성 정보를 만듭니다.
    ///
    /// - Parameters:
    ///   - label: 콘텐츠를 식별하는 접근성 레이블입니다.
    ///   - value: 콘텐츠의 추가 메타데이터 또는 상태입니다.
    public init(
        label: String,
        value: String? = nil
    ) {
        self.label = label
        self.value = value
    }
}
