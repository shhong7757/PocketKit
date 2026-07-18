import PocketUI
import SwiftUI

@MainActor
public struct PhotosGallery: View {
    public struct Slot {
        private let makeContent: () -> AnyView

        public init<Content: View>(
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.makeContent = {
                AnyView(content())
            }
        }

        fileprivate func makeView() -> AnyView {
            makeContent()
        }
    }

    struct Configuration {
        let filter: PhotosGalleryFilter
        let selection: GallerySelection<String>
        let layout: GalleryLayout
        let paginationThreshold: Int
        let zoomTransition: GalleryZoomTransition<String>?
        let scrollPosition: Binding<ScrollPosition>?
        let contentAspectRatio: (PhotosGalleryContent) -> CGFloat?
        let accessibilityLabel: ((PhotosGalleryContent) -> String)?
        let onTap: ((PhotosGalleryContent) -> Void)?
        let loadingContent: Slot
        let unavailableContent: (PhotosGalleryAccessStatus) -> Slot
        let emptyContent: Slot
        let headerContent: Slot?
        let footerContent: Slot?
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var vm: PhotosGalleryViewModel
    private let configuration: Configuration
    private let thumbnailService: any PhotosGalleryThumbnailServiceProtocol

    public init(
        filter: PhotosGalleryFilter = .all,
        selection: GallerySelection<String> = .none,
        layout: GalleryLayout = .compact,
        paginationThreshold: Int = 12,
        zoomTransition: GalleryZoomTransition<String>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (PhotosGalleryContent) -> CGFloat? = { _ in nil },
        accessibilityLabel: ((PhotosGalleryContent) -> String)? = nil,
        onTap: ((PhotosGalleryContent) -> Void)? = nil,
        loadingContent: PhotosGallery.Slot = PhotosGallery.Slot {
            PhotosGalleryDefaultLoadingView()
        },
        unavailableContent: @escaping (PhotosGalleryAccessStatus) -> PhotosGallery.Slot = { _ in
            PhotosGallery.Slot {
                PhotosGalleryDefaultUnavailableView()
            }
        },
        emptyContent: PhotosGallery.Slot = PhotosGallery.Slot {
            PhotosGalleryDefaultEmptyView()
        },
        headerContent: PhotosGallery.Slot? = nil,
        footerContent: PhotosGallery.Slot? = nil
    ) {
        self.init(
            vm: PhotosGalleryViewModel(filter: filter),
            configuration: Configuration(
                filter: filter,
                selection: selection,
                layout: layout,
                paginationThreshold: paginationThreshold,
                zoomTransition: zoomTransition,
                scrollPosition: scrollPosition,
                contentAspectRatio: contentAspectRatio,
                accessibilityLabel: accessibilityLabel,
                onTap: onTap,
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

        Group {
            switch vm.presentationState {
            case .loading:
                configuration.loadingContent.makeView()

            case .unavailable:
                configuration.unavailableContent(vm.accessStatus).makeView()

            case .available:
                PocketUI.GalleryView(
                    items: vm.items,
                    selection: configuration.selection,
                    layout: configuration.layout,
                    zoomTransition: configuration.zoomTransition,
                    scrollPosition: configuration.scrollPosition,
                    contentAspectRatio: configuration.contentAspectRatio,
                    accessibilityLabel: configuration.accessibilityLabel ?? { _ in
                        String(
                            localized: "mediaGallery.itemAccessibilityLabel",
                            bundle: .module
                        )
                    },
                    pagination: GalleryPagination(
                        hasNextPage: vm.hasNextPage,
                        isFetchingNextPage: vm.isFetchingNextPage,
                        threshold: configuration.paginationThreshold,
                        fetchNextPage: {
                            Task { @MainActor in
                                await vm.loadMoreIfNeeded()
                            }
                        }
                    ),
                    onRefresh: {
                        await vm.reload()
                    },
                    onTap: configuration.onTap,
                    headerContent: {
                        configuration.headerContent?.makeView() ?? AnyView(EmptyView())
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
                        configuration.emptyContent.makeView()
                    },
                    footerContent: {
                        configuration.footerContent?.makeView() ?? AnyView(EmptyView())
                    }
                )
            }
        }
        .task {
            await vm.requestAccess()
        }
        .onChange(of: configuration.filter) { _, newFilter in
            Task { @MainActor in
                await vm.changeFilter(to: newFilter)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }

            Task { @MainActor in
                await vm.requestAccess()
            }
        }
    }
}
