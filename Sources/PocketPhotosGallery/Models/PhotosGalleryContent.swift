/// A media item loaded from the Photos library.
public struct PhotosGalleryContent: Identifiable, Sendable, Equatable {
    public let id: String
    public let mediaType: PhotosGalleryMediaType

    public init(id: String, mediaType: PhotosGalleryMediaType) {
        self.id = id
        self.mediaType = mediaType
    }
}
