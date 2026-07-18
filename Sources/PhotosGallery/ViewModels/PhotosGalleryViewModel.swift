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

    convenience init(filter: PhotosGalleryFilter = .all) {
        let authorizationService = PhotosGalleryAuthorizationService.live()
        let paginationService = PhotosGalleryPaginationService.live()
        self.init(
            filter: filter,
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
        authorizationUseCase: PhotosGalleryAuthorizationUseCase,
        pagingUseCase: PhotosGalleryPagingUseCase
    ) {
        self.filter = filter
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

    func requestAccess() async {
        guard !isRequestingAccess else { return }

        isRequestingAccess = true
        defer {
            isRequestingAccess = false
        }

        updateAccessStatus(await authorizationUseCase.requestAccessIfNeeded())
        await fetchPageIfAccessible()
    }

    func reload() async {
        updateAccessStatus(authorizationUseCase.status())
        await fetchPageIfAccessible()
    }

    func changeFilter(to newFilter: PhotosGalleryFilter) async {
        guard filter != newFilter else { return }

        filter = newFilter
        invalidatePagination()
        await fetchPageIfAccessible()
    }

    func loadMoreIfNeeded() async {
        guard state.accessStatus.isAccessible,
              state.hasNextPage,
              !state.isFetching,
              !state.isFetchingNextPage else {
            return
        }

        await fetchNextPage()
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

    private func fetchPageIfAccessible() async {
        guard state.accessStatus.isAccessible else {
            invalidatePaginationIfMediaLibraryInaccessible()
            return
        }

        guard !state.isFetching else { return }

        paginationGeneration += 1
        let generation = paginationGeneration
        state.isFetching = true
        defer {
            if generation == paginationGeneration {
                state.isFetching = false
            }
        }

        let page = await fetchPage(offset: 0)
        guard !Task.isCancelled, generation == paginationGeneration else { return }

        paginationOffset = page.offset
        state.replaceItems(with: page)
    }

    private func fetchNextPage() async {
        let generation = paginationGeneration
        state.isFetchingNextPage = true
        defer {
            if generation == paginationGeneration {
                state.isFetchingNextPage = false
            }
        }

        let page = await fetchPage(offset: paginationOffset)
        guard !Task.isCancelled, generation == paginationGeneration else { return }

        paginationOffset = page.offset
        state.appendItems(from: page)
    }

    private func fetchPage(offset: Int) async -> PhotosGalleryPage {
        await pagingUseCase.fetch(
            offset: offset,
            filter: filter
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

    private func invalidatePaginationIfMediaLibraryInaccessible() {
        guard state.accessStatus != .notDetermined,
              !state.accessStatus.isAccessible else {
            return
        }

        invalidatePagination()
    }
}
