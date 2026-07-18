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
        let includeLivePhotos: Bool
        let selection: GallerySelection<String>
        let layout: GalleryLayout
        let zoomTransition: GalleryZoomTransition<String>?
        let scrollPosition: Binding<ScrollPosition>?
        let contentAspectRatio: (PhotosGalleryContent) -> CGFloat?
        let accessibilityLabel: (PhotosGalleryContent) -> String
        let onTap: ((PhotosGalleryContent) -> Void)?
        let onError: (@Sendable @MainActor (PhotosGalleryError) -> Void)?
        let loadingContent: Slot?
        let unavailableContent: (PhotosGalleryAccessStatus) -> Slot?
        let emptyContent: Slot?
        let headerContent: Slot?
        let footerContent: Slot?
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var vm: PhotosGalleryViewModel
    private let configuration: Configuration
    private let thumbnailService: any PhotosGalleryThumbnailServiceProtocol

    public init(
        filter: PhotosGalleryFilter? = .all,
        includeLivePhotos: Bool? = false,
        selection: GallerySelection<String> = .none,
        layout: GalleryLayout? = .compact,
        zoomTransition: GalleryZoomTransition<String>? = nil,
        scrollPosition: Binding<ScrollPosition>? = nil,
        contentAspectRatio: @escaping (PhotosGalleryContent) -> CGFloat? = { _ in nil },
        accessibilityLabel: @escaping (PhotosGalleryContent) -> String,
        onTap: ((PhotosGalleryContent) -> Void)? = nil,
        onError: (@Sendable @MainActor (PhotosGalleryError) -> Void)? = nil,
        loadingContent: PhotosGallery.Slot? = nil,
        unavailableContent: @escaping (PhotosGalleryAccessStatus) -> PhotosGallery.Slot? = { _ in nil },
        emptyContent: PhotosGallery.Slot? = nil,
        headerContent: PhotosGallery.Slot? = nil,
        footerContent: PhotosGallery.Slot? = nil
    ) {
        self.init(
            vm: PhotosGalleryViewModel(
                filter: filter ?? .all,
                includeLivePhotos: includeLivePhotos ?? false
            ),
            configuration: Configuration(
                filter: filter ?? .all,
                includeLivePhotos: includeLivePhotos ?? false,
                selection: selection,
                layout: layout ?? .compact,
                zoomTransition: zoomTransition,
                scrollPosition: scrollPosition,
                contentAspectRatio: contentAspectRatio,
                accessibilityLabel: accessibilityLabel,
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

        Group {
            switch vm.presentationState {
            case .loading:
                configuration.loadingContent?.makeView()
                    ?? AnyView(
                        ProgressView()
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                    )

            case .unavailable:
                configuration.unavailableContent(vm.accessStatus)?.makeView()
                    ?? AnyView(EmptyView())

            case .available:
                PocketUI.GalleryView(
                    items: vm.items,
                    selection: configuration.selection,
                    layout: configuration.layout,
                    zoomTransition: configuration.zoomTransition,
                    scrollPosition: configuration.scrollPosition,
                    contentAspectRatio: configuration.contentAspectRatio,
                    accessibilityLabel: configuration.accessibilityLabel,
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
                        configuration.emptyContent?.makeView() ?? AnyView(EmptyView())
                    },
                    footerContent: {
                        configuration.footerContent?.makeView() ?? AnyView(EmptyView())
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
