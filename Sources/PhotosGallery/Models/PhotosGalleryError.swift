import Foundation

public enum PhotosGalleryError: Error, Equatable, Sendable {
    case photoLibraryAccessDenied
    case photoLibraryAccessRestricted
    case pageFetchFailed
}
