import XCTest

@testable import PocketPhotosGallery

@MainActor
final class PhotosGalleryViewModelTests: XCTestCase {
    func testRequestAccessLoadsFirstPageAndNextPage() async {
        let firstPage = page(
            items: [content(id: "one"), content(id: "two")],
            offset: 2,
            hasNextPage: true
        )
        let nextPage = page(
            items: [content(id: "three")],
            offset: 3,
            hasNextPage: false
        )
        let viewModel = makeViewModel(
            accessStatus: .authorized,
            pages: [0: firstPage, 2: nextPage]
        )

        await viewModel.requestAccess()

        XCTAssertEqual(viewModel.presentationState, .available)
        XCTAssertEqual(viewModel.items.map(\.id), ["one", "two"])
        XCTAssertTrue(viewModel.hasNextPage)

        await viewModel.loadMoreIfNeeded()

        XCTAssertEqual(viewModel.items.map(\.id), ["one", "two", "three"])
        XCTAssertFalse(viewModel.hasNextPage)
    }

    func testDeniedAccessShowsUnavailableAndDoesNotLoadItems() async {
        let viewModel = makeViewModel(accessStatus: .denied)

        await viewModel.requestAccess()

        XCTAssertEqual(viewModel.presentationState, .unavailable)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertFalse(viewModel.hasNextPage)
    }

    func testRequestAccessRequestsAuthorizationWhenStatusIsNotDetermined() async {
        let authorizationService = TestAuthorizationService(
            status: .notDetermined,
            requestedStatus: .authorized
        )
        let viewModel = makeViewModel(
            authorizationService: authorizationService,
            pages: [0: page(items: [content(id: "authorized")], offset: 1)]
        )

        await viewModel.requestAccess()

        XCTAssertEqual(viewModel.presentationState, .available)
        XCTAssertEqual(viewModel.items.map(\.id), ["authorized"])
    }

    func testLimitedAccessIsAvailable() async {
        let viewModel = makeViewModel(
            accessStatus: .limited,
            pages: [0: page(items: [content(id: "limited")], offset: 1)]
        )

        await viewModel.requestAccess()

        XCTAssertEqual(viewModel.presentationState, .available)
        XCTAssertEqual(viewModel.items.map(\.id), ["limited"])
    }

    func testReloadClearsItemsWhenAccessBecomesUnavailable() async {
        let authorizationService = TestAuthorizationService(status: .authorized)
        let viewModel = makeViewModel(
            authorizationService: authorizationService,
            pages: [0: page(items: [content(id: "one")], offset: 1)]
        )

        await viewModel.requestAccess()
        XCTAssertEqual(viewModel.items.map(\.id), ["one"])

        authorizationService.status = .denied
        await viewModel.reload()

        XCTAssertEqual(viewModel.presentationState, .unavailable)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertFalse(viewModel.hasNextPage)
    }

    func testChangingFilterReplacesItemsFromTheFirstPage() async {
        let allPage = page(items: [content(id: "all")], offset: 1)
        let imagesPage = page(items: [content(id: "image")], offset: 1)
        let viewModel = makeViewModel(
            pagesByFilter: [
                .all: [0: allPage],
                .images: [0: imagesPage],
            ]
        )

        await viewModel.requestAccess()
        await viewModel.changeFilter(to: .images)

        XCTAssertEqual(viewModel.items.map(\.id), ["image"])
        XCTAssertFalse(viewModel.hasNextPage)
    }

    func testAppendingPageRemovesDuplicateIDs() async {
        let firstPage = page(
            items: [content(id: "one"), content(id: "two")],
            offset: 2,
            hasNextPage: true
        )
        let nextPage = page(
            items: [content(id: "two"), content(id: "three")],
            offset: 4,
            hasNextPage: false
        )
        let viewModel = makeViewModel(
            pages: [0: firstPage, 2: nextPage]
        )

        await viewModel.requestAccess()
        await viewModel.loadMoreIfNeeded()

        XCTAssertEqual(viewModel.items.map(\.id), ["one", "two", "three"])
    }

    func testStalePageDoesNotReplaceItemsAfterFilterChanges() async {
        let gate = TestFetchGate()
        let paginationService = TestPaginationService(
            pagesByFilter: [
                .all: [0: page(items: [content(id: "all")], offset: 1)],
                .images: [0: page(items: [content(id: "image")], offset: 1)],
            ],
            blockedFilter: .all,
            gate: gate
        )
        let viewModel = makeViewModel(
            authorizationService: TestAuthorizationService(status: .authorized),
            paginationService: paginationService
        )

        let initialTask = Task { @MainActor in
            await viewModel.requestAccess()
        }
        await gate.waitUntilBlocked()

        await viewModel.changeFilter(to: .images)
        await gate.open()
        await initialTask.value

        XCTAssertEqual(viewModel.items.map(\.id), ["image"])
    }

    private func makeViewModel(
        accessStatus: PhotosGalleryAccessStatus = .authorized,
        pages: [Int: PhotosGalleryPage] = [:],
        pagesByFilter: [PhotosGalleryFilter: [Int: PhotosGalleryPage]] = [:],
        paginationService: TestPaginationService? = nil
    ) -> PhotosGalleryViewModel {
        makeViewModel(
            authorizationService: TestAuthorizationService(status: accessStatus),
            pages: pages,
            pagesByFilter: pagesByFilter,
            paginationService: paginationService
        )
    }

    private func makeViewModel(
        authorizationService: TestAuthorizationService,
        pages: [Int: PhotosGalleryPage] = [:],
        pagesByFilter: [PhotosGalleryFilter: [Int: PhotosGalleryPage]] = [:],
        paginationService: TestPaginationService? = nil
    ) -> PhotosGalleryViewModel {
        PhotosGalleryViewModel(
            filter: .all,
            authorizationUseCase: PhotosGalleryAuthorizationUseCase(
                service: authorizationService
            ),
            pagingUseCase: PhotosGalleryPagingUseCase(
                service: paginationService ?? TestPaginationService(
                    pages: pages,
                    pagesByFilter: pagesByFilter
                )
            )
        )
    }

    private func content(id: String) -> PhotosGalleryContent {
        PhotosGalleryContent(id: id, mediaType: .image)
    }

    private func page(
        items: [PhotosGalleryContent],
        offset: Int = 0,
        hasNextPage: Bool = false
    ) -> PhotosGalleryPage {
        PhotosGalleryPage(
            items: items,
            offset: offset,
            hasNextPage: hasNextPage
        )
    }
}

@MainActor
private final class TestAuthorizationService: PhotosGalleryAuthorizationServiceProtocol {
    var status: PhotosGalleryAccessStatus
    let requestedStatus: PhotosGalleryAccessStatus

    init(
        status: PhotosGalleryAccessStatus,
        requestedStatus: PhotosGalleryAccessStatus? = nil
    ) {
        self.status = status
        self.requestedStatus = requestedStatus ?? status
    }

    func currentAuthorizationStatus() -> PhotosGalleryAccessStatus {
        status
    }

    func requestAuthorization() async -> PhotosGalleryAccessStatus {
        requestedStatus
    }
}

private struct TestPaginationService: PhotosGalleryPaginationServiceProtocol {
    let pages: [Int: PhotosGalleryPage]
    let pagesByFilter: [PhotosGalleryFilter: [Int: PhotosGalleryPage]]
    let blockedFilter: PhotosGalleryFilter?
    let gate: TestFetchGate?

    init(
        pages: [Int: PhotosGalleryPage] = [:],
        pagesByFilter: [PhotosGalleryFilter: [Int: PhotosGalleryPage]] = [:],
        blockedFilter: PhotosGalleryFilter? = nil,
        gate: TestFetchGate? = nil
    ) {
        self.pages = pages
        self.pagesByFilter = pagesByFilter
        self.blockedFilter = blockedFilter
        self.gate = gate
    }

    func fetch(
        offset: Int,
        limit: Int,
        filter: PhotosGalleryFilter
    ) async -> PhotosGalleryPage {
        if filter == blockedFilter {
            await gate?.wait()
        }
        await Task.yield()

        let pages = pagesByFilter[filter] ?? self.pages
        return pages[offset] ?? PhotosGalleryPage(
            items: [],
            offset: offset,
            hasNextPage: false
        )
    }
}

private actor TestFetchGate {
    private var isOpen = false
    private var waiterCount = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }

        await withCheckedContinuation { continuation in
            waiterCount += 1
            waiters.append(continuation)
        }
    }

    func waitUntilBlocked() async {
        while waiterCount == 0 {
            await Task.yield()
        }
    }

    func open() {
        isOpen = true
        let waiters = waiters
        self.waiters.removeAll()
        waiters.forEach { $0.resume() }
    }
}
