/// Current presentation state provided to PhotosGallery header and footer content.
public struct PhotosGalleryContext: Sendable, Equatable {
    /// The current Photos library authorization status.
    public let accessStatus: PhotosGalleryAccessStatus

    /// The number of items currently displayed by the gallery.
    public let contentCount: Int

    /// Whether the gallery is currently loading the next page.
    public let isFetchingNextPage: Bool

    /// Whether another page is available.
    public let hasNextPage: Bool

    public init(
        accessStatus: PhotosGalleryAccessStatus,
        contentCount: Int,
        isFetchingNextPage: Bool,
        hasNextPage: Bool
    ) {
        self.accessStatus = accessStatus
        self.contentCount = contentCount
        self.isFetchingNextPage = isFetchingNextPage
        self.hasNextPage = hasNextPage
    }
}
