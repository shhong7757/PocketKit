import Foundation

/// `PhotosGallery`가 사진 보관함을 표시하는 동안 발생할 수 있는 오류입니다.
public enum PhotosGalleryError: Error, Equatable, Sendable {
    /// 사용자가 사진 보관함 접근을 거부했습니다.
    case photoLibraryAccessDenied

    /// 시스템 정책으로 사진 보관함 접근이 제한되었습니다.
    case photoLibraryAccessRestricted

    /// 사진 보관함의 페이지를 가져오지 못했습니다.
    case pageFetchFailed
}
