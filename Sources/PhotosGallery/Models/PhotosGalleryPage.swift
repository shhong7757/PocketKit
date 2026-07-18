struct PhotosGalleryPage: Sendable {
    let items: [PhotosGalleryContent]
    let offset: Int
    let hasNextPage: Bool
}
