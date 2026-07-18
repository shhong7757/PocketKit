import PocketUI
import SwiftUI

/// 사진 보관함의 이미지와 동영상을 표시하는 SwiftUI 갤러리입니다.
@MainActor
public struct PhotosGallery: View {
    /// 로딩, 빈 상태, 권한 없음 화면에 표시할 SwiftUI 콘텐츠를 감쌉니다.
    public struct Slot {
        private let makeContent: (PhotosGalleryContext) -> AnyView

        /// 슬롯 콘텐츠를 만듭니다.
        ///
        /// - Parameter content: 슬롯에 표시할 SwiftUI 콘텐츠입니다.
        public init<Content: View>(
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.makeContent = { _ in
                AnyView(content())
            }
        }

        /// context를 사용해 슬롯 콘텐츠를 만듭니다.
        public init<Content: View>(
            @ViewBuilder content: @escaping (PhotosGalleryContext) -> Content
        ) {
            self.makeContent = { context in
                AnyView(content(context))
            }
        }

        fileprivate func makeView(context: PhotosGalleryContext) -> AnyView {
            makeContent(context)
        }
    }

    struct Configuration {
        let filter: PhotosGalleryFilter
        let includeLivePhotos: Bool
        let selection: GallerySelection<String>
        let layout: GalleryLayout
        let zoomTransition: GalleryZoomTransition<String>?
        let scrollPosition: Binding<ScrollPosition>?
        let contentAspectRatio: (PhotosGalleryContent) -> CGFloat?
        let accessibility: (PhotosGalleryContent) -> PhotosGalleryAccessibility
        let onTap: ((PhotosGalleryContent) -> Void)?
        let onError: (@Sendable @MainActor (PhotosGalleryError) -> Void)?
        let loadingContent: Slot?
        let unavailableContent: ((PhotosGalleryAccessStatus) -> Slot?)?
        let emptyContent: Slot?
        let headerContent: Slot?
        let footerContent: Slot?
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var vm: PhotosGalleryViewModel
    private let configuration: Configuration
    private let thumbnailService: any PhotosGalleryThumbnailServiceProtocol

    /// 사진 보관함 갤러리를 만듭니다.
    ///
    /// 권한 요청, 페이지네이션, 썸네일 로딩은 갤러리가 관리합니다. 앱은 접근성
    /// 정보와 필요한 상태별 콘텐츠를 전달하고, `onError`에서 오류를 처리합니다.
    ///
    /// - Parameters:
    ///   - filter: 표시할 미디어 종류입니다.
    ///   - includeLivePhotos: Live Photo 포함 여부입니다.
    ///   - selection: 항목 선택 상태입니다.
    ///   - layout: 갤러리 그리드 레이아웃입니다.
    ///   - zoomTransition: 그리드와 상세 화면 사이의 줌 전환 설정입니다.
    ///   - scrollPosition: 갤러리 스크롤 위치를 연결할 선택적 바인딩입니다.
    ///   - contentAspectRatio: 콘텐츠의 표시 가로세로 비율입니다.
    ///   - accessibility: 콘텐츠의 접근성 정보를 반환합니다.
    ///   - onTap: 선택 모드가 아닐 때 항목을 탭하면 호출됩니다.
    ///   - onError: 권한 또는 페이지 조회 오류가 발생하면 호출됩니다.
    ///   - loadingContent: 초기 로딩 중 표시할 콘텐츠입니다.
    ///   - unavailableContent: 접근할 수 없을 때 상태별로 표시할 콘텐츠입니다.
    ///   - emptyContent: 표시할 미디어가 없을 때 표시할 콘텐츠입니다.
    ///   - headerContent: 갤러리 위에 표시할 콘텐츠입니다.
    ///   - footerContent: 갤러리 아래에 표시할 콘텐츠입니다.
    public init(
        filter: PhotosGalleryFilter = .all,
        includeLivePhotos: Bool = false,
        selection: GallerySelection<String> = .none,
        layout: GalleryLayout = .compact,
        zoomTransition: GalleryZoomTransition<String>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (PhotosGalleryContent) -> CGFloat? = { _ in nil },
        accessibility: @escaping (PhotosGalleryContent) -> PhotosGalleryAccessibility,
        onTap: ((PhotosGalleryContent) -> Void)? = nil,
        onError: (@Sendable @MainActor (PhotosGalleryError) -> Void)? = nil,
        loadingContent: PhotosGallery.Slot? = nil,
        unavailableContent: ((PhotosGalleryAccessStatus) -> PhotosGallery.Slot?)? = nil,
        emptyContent: PhotosGallery.Slot? = nil,
        headerContent: PhotosGallery.Slot? = nil,
        footerContent: PhotosGallery.Slot? = nil
    ) {
        self.init(
            vm: PhotosGalleryViewModel(
                filter: filter,
                includeLivePhotos: includeLivePhotos
            ),
            configuration: Configuration(
                filter: filter,
                includeLivePhotos: includeLivePhotos,
                selection: selection,
                layout: layout,
                zoomTransition: zoomTransition,
                scrollPosition: scrollPosition,
                contentAspectRatio: contentAspectRatio,
                accessibility: accessibility,
                onTap: onTap,
                onError: onError,
                loadingContent: loadingContent,
                unavailableContent: unavailableContent,
                emptyContent: emptyContent,
                headerContent: headerContent,
                footerContent: footerContent
            )
        )
    }

    init(
        vm: PhotosGalleryViewModel,
        configuration: Configuration,
        thumbnailService: any PhotosGalleryThumbnailServiceProtocol = PhotosGalleryThumbnailService.live()
    ) {
        _vm = State(initialValue: vm)
        self.configuration = configuration
        self.thumbnailService = thumbnailService
    }

    public var body: some View {
        // Keep one observable reference for this render pass and all async callbacks.
        let vm = vm
        let onError = configuration.onError
        let context = PhotosGalleryContext(
            accessStatus: vm.accessStatus,
            contentCount: vm.items.count,
            isFetchingNextPage: vm.isFetchingNextPage,
            hasNextPage: vm.hasNextPage
        )

        Group {
            switch vm.presentationState {
            case .loading:
                configuration.loadingContent?.makeView(context: context)
                    ?? AnyView(
                        ProgressView()
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                    )

            case .unavailable:
                configuration.unavailableContent?(vm.accessStatus)?.makeView(
                    context: context
                )
                    ?? AnyView(EmptyView())

            case .available:
                PocketUI.GalleryView(
                    items: vm.items,
                    selection: configuration.selection,
                    layout: configuration.layout,
                    zoomTransition: configuration.zoomTransition,
                    scrollPosition: configuration.scrollPosition,
                    contentAspectRatio: configuration.contentAspectRatio,
                    accessibilityLabel: { content in
                        configuration.accessibility(content).label
                    },
                    accessibilityValue: { content in
                        configuration.accessibility(content).value
                    },
                    pagination: GalleryPagination(
                        hasNextPage: vm.hasNextPage,
                        isFetchingNextPage: vm.isFetchingNextPage,
                        visibilityThreshold: PhotosGalleryPagingPolicy.visibilityThreshold,
                        fetchNextPage: {
                            Task { @MainActor in
                                if let error = await vm.loadMoreIfNeeded() {
                                    onError?(error)
                                }
                            }
                        }
                    ),
                    onRefresh: {
                        if let error = await vm.reload() {
                            await onError?(error)
                        }
                    },
                    onTap: configuration.onTap,
                    headerContent: {
                        configuration.headerContent?.makeView(context: context)
                            ?? AnyView(EmptyView())
                    },
                    content: { content in
                        PhotosGalleryContentView(
                            content: content,
                            service: thumbnailService
                        )
                    },
                    // Media-specific overlays are rendered by PhotosGalleryContentView.
                    overlayContent: { _ in
                        EmptyView()
                    },
                    emptyContent: {
                        configuration.emptyContent?.makeView(context: context)
                            ?? AnyView(EmptyView())
                    },
                    footerContent: {
                        configuration.footerContent?.makeView(context: context)
                            ?? AnyView(EmptyView())
                    }
                )
            }
        }
        .task {
            if let error = await vm.requestAccess() {
                onError?(error)
            }
        }
        .onChange(of: configuration.filter) { _, newFilter in
            Task { @MainActor in
                if let error = await vm.changeFilter(to: newFilter) {
                    onError?(error)
                }
            }
        }
        .onChange(of: configuration.includeLivePhotos) { _, newValue in
            Task { @MainActor in
                if let error = await vm.changeIncludeLivePhotos(to: newValue) {
                    onError?(error)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            Task { @MainActor in
                if let error = await vm.requestAccess() {
                    onError?(error)
                }
            }
        }
    }
}
