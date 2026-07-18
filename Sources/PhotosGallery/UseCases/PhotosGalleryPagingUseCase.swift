@MainActor
struct PhotosGalleryPagingUseCase {
    private let service: any PhotosGalleryPaginationServiceProtocol

    init(service: any PhotosGalleryPaginationServiceProtocol) {
        self.service = service
    }

    func fetch(
        offset: Int,
        filter: PhotosGalleryFilter,
        includeLivePhotos: Bool
    ) async throws -> PhotosGalleryPage {
        try await service.fetch(
            offset: offset,
            limit: PhotosGalleryPagingPolicy.pageSize,
            filter: filter,
            includeLivePhotos: includeLivePhotos
        )
    }
}
