import Observation

enum PhotosGalleryPresentationState: Equatable {
    case loading
    case available
    case unavailable
}

@MainActor
@Observable
final class PhotosGalleryViewModel {
    private struct State {
        var accessStatus: PhotosGalleryAccessStatus
        var items: [PhotosGalleryContent]
        var isFetching: Bool
        var isFetchingNextPage: Bool
        var hasNextPage: Bool

        mutating func replaceItems(with page: PhotosGalleryPage) {
            items = page.items
            hasNextPage = page.hasNextPage
        }

        mutating func appendItems(from page: PhotosGalleryPage) {
            let existingIDs = Set(items.map(\.id))
            items.append(contentsOf: page.items.filter { !existingIDs.contains($0.id) })
            hasNextPage = page.hasNextPage
        }

        mutating func resetItems() {
            items = []
            hasNextPage = false
            isFetching = false
            isFetchingNextPage = false
        }
    }

    private var state: State

    @ObservationIgnored
    private let authorizationUseCase: PhotosGalleryAuthorizationUseCase
    @ObservationIgnored
    private let pagingUseCase: PhotosGalleryPagingUseCase
    @ObservationIgnored
    private var filter: PhotosGalleryFilter
    @ObservationIgnored
    private var includeLivePhotos: Bool
    @ObservationIgnored
    private var paginationOffset = 0
    @ObservationIgnored
    private var paginationGeneration = 0
    @ObservationIgnored
    private var isRequestingAccess = false

    var presentationState: PhotosGalleryPresentationState {
        switch state.accessStatus {
        case .notDetermined:
            return .loading

        case .authorized, .limited:
            if state.isFetching && state.items.isEmpty {
                return .loading
            }

            return .available

        case .denied, .restricted:
            return .unavailable
        }
    }

    convenience init(
        filter: PhotosGalleryFilter = .all,
        includeLivePhotos: Bool = false
    ) {
        let authorizationService = PhotosGalleryAuthorizationService.live()
        let paginationService = PhotosGalleryPaginationService.live()
        self.init(
            filter: filter,
            includeLivePhotos: includeLivePhotos,
            authorizationUseCase: PhotosGalleryAuthorizationUseCase(
                service: authorizationService
            ),
            pagingUseCase: PhotosGalleryPagingUseCase(
                service: paginationService
            )
        )
    }

    init(
        filter: PhotosGalleryFilter,
        includeLivePhotos: Bool = false,
        authorizationUseCase: PhotosGalleryAuthorizationUseCase,
        pagingUseCase: PhotosGalleryPagingUseCase
    ) {
        self.filter = filter
        self.includeLivePhotos = includeLivePhotos
        self.authorizationUseCase = authorizationUseCase
        self.pagingUseCase = pagingUseCase
        self.state = State(
            accessStatus: .notDetermined,
            items: [],
            isFetching: false,
            isFetchingNextPage: false,
            hasNextPage: false
        )
    }

    func requestAccess() async -> PhotosGalleryError? {
        guard !isRequestingAccess else { return nil }

        isRequestingAccess = true
        defer {
            isRequestingAccess = false
        }

        let status = await authorizationUseCase.requestAccessIfNeeded()
        updateAccessStatus(status)

        guard status.isAccessible else {
            return accessError(for: status)
        }

        return await fetchPageIfAccessible()
    }

    func reload() async -> PhotosGalleryError? {
        let status = authorizationUseCase.status()
        updateAccessStatus(status)

        guard status.isAccessible else {
            return accessError(for: status)
        }

        return await fetchPageIfAccessible()
    }

    func changeFilter(to newFilter: PhotosGalleryFilter) async -> PhotosGalleryError? {
        guard filter != newFilter else { return nil }

        filter = newFilter
        invalidatePagination()
        return await fetchPageIfAccessible()
    }

    func changeIncludeLivePhotos(to newValue: Bool) async -> PhotosGalleryError? {
        guard includeLivePhotos != newValue else { return nil }

        includeLivePhotos = newValue
        invalidatePagination()
        return await fetchPageIfAccessible()
    }

    func loadMoreIfNeeded() async -> PhotosGalleryError? {
        guard state.accessStatus.isAccessible,
              state.hasNextPage,
              !state.isFetching,
              !state.isFetchingNextPage else {
            return nil
        }

        return await fetchNextPage()
    }

    var items: [PhotosGalleryContent] {
        state.items
    }

    var accessStatus: PhotosGalleryAccessStatus {
        state.accessStatus
    }

    var isFetching: Bool {
        state.isFetching
    }

    var isFetchingNextPage: Bool {
        state.isFetchingNextPage
    }

    var hasNextPage: Bool {
        state.hasNextPage
    }

    private func fetchPageIfAccessible() async -> PhotosGalleryError? {
        guard state.accessStatus.isAccessible else {
            invalidatePaginationIfMediaLibraryInaccessible()
            return accessError(for: state.accessStatus)
        }

        guard !state.isFetching else { return nil }

        paginationGeneration += 1
        let generation = paginationGeneration
        state.isFetching = true
        defer {
            if generation == paginationGeneration {
                state.isFetching = false
            }
        }

        let page: PhotosGalleryPage
        do {
            page = try await fetchPage(offset: 0)
        } catch is CancellationError {
            return nil
        } catch {
            guard generation == paginationGeneration else { return nil }
            return .pageFetchFailed
        }

        guard !Task.isCancelled, generation == paginationGeneration else { return nil }

        paginationOffset = page.offset
        state.replaceItems(with: page)
        return nil
    }

    private func fetchNextPage() async -> PhotosGalleryError? {
        let generation = paginationGeneration
        state.isFetchingNextPage = true
        defer {
            if generation == paginationGeneration {
                state.isFetchingNextPage = false
            }
        }

        let page: PhotosGalleryPage
        do {
            page = try await fetchPage(offset: paginationOffset)
        } catch is CancellationError {
            return nil
        } catch {
            guard generation == paginationGeneration else { return nil }
            return .pageFetchFailed
        }

        guard !Task.isCancelled, generation == paginationGeneration else { return nil }

        paginationOffset = page.offset
        state.appendItems(from: page)
        return nil
    }

    private func fetchPage(offset: Int) async throws -> PhotosGalleryPage {
        try await pagingUseCase.fetch(
            offset: offset,
            filter: filter,
            includeLivePhotos: includeLivePhotos
        )
    }

    private func invalidatePagination() {
        paginationOffset = 0
        paginationGeneration += 1
        state.resetItems()
    }

    private func updateAccessStatus(_ status: PhotosGalleryAccessStatus) {
        state.accessStatus = status
        invalidatePaginationIfMediaLibraryInaccessible()
    }

    private func accessError(for status: PhotosGalleryAccessStatus) -> PhotosGalleryError? {
        switch status {
        case .denied:
            return .photoLibraryAccessDenied
        case .restricted:
            return .photoLibraryAccessRestricted
        case .notDetermined, .authorized, .limited:
            return nil
        }
    }

    private func invalidatePaginationIfMediaLibraryInaccessible() {
        guard state.accessStatus != .notDetermined,
              !state.accessStatus.isAccessible else {
            return
        }

        invalidatePagination()
    }
}
