/// ``PhotosGallery``에 표시할 미디어 집합입니다.
public enum PhotosGalleryFilter: Sendable, Hashable {
    /// 이미지만 표시합니다.
    case images

    /// 동영상만 표시합니다.
    case videos

    /// 이미지와 동영상을 모두 표시합니다.
    case all
}
