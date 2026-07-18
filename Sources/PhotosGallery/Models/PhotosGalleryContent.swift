import Foundation

/// A media item loaded from the Photos library.
public struct PhotosGalleryContent: Identifiable, Sendable, Equatable {
    public let id: String
    public let mediaType: PhotosGalleryMediaType
    public let duration: TimeInterval?
    public let isLivePhoto: Bool

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
