import Foundation

/// 사진 보관함에서 불러온 미디어 항목입니다.
public struct PhotosGalleryContent: Identifiable, Sendable, Equatable {
    /// PhotoKit에서 사용하는 자산 식별자입니다.
    public let id: String

    /// 미디어 종류입니다.
    public let mediaType: PhotosGalleryMediaType

    /// 동영상의 재생 시간입니다. 이미지에서는 `nil`입니다.
    public let duration: TimeInterval?

    /// Live Photo인지 여부입니다.
    public let isLivePhoto: Bool

    /// 사진 보관함 콘텐츠를 만듭니다.
    ///
    /// - Parameters:
    ///   - id: PhotoKit 자산 식별자입니다.
    ///   - mediaType: 미디어 종류입니다.
    ///   - duration: 동영상 재생 시간입니다.
    ///   - isLivePhoto: Live Photo인지 여부입니다.
    public init(
        id: String,
        mediaType: PhotosGalleryMediaType,
        duration: TimeInterval? = nil,
        isLivePhoto: Bool = false
    ) {
        self.id = id
        self.mediaType = mediaType
        self.duration = duration
        self.isLivePhoto = isLivePhoto
    }
}
