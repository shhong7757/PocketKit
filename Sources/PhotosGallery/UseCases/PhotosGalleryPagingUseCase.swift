@MainActor
struct PhotosGalleryPagingUseCase {
    private static let pageSize = 60

    private let service: any PhotosGalleryPaginationServiceProtocol

    init(service: any PhotosGalleryPaginationServiceProtocol) {
        self.service = service
    }

    func fetch(
        offset: Int,
        filter: PhotosGalleryFilter
    ) async throws -> PhotosGalleryPage {
        try await service.fetch(
            offset: offset,
            limit: Self.pageSize,
            filter: filter
        )
    }
}
