import SwiftUI

struct GalleryScrollPositionModifier: ViewModifier {
    let scrollPosition: Binding<ScrollPosition>?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let scrollPosition {
            content.scrollPosition(scrollPosition)
        } else {
            content
        }
    }
}

struct GalleryPullToRefreshModifier: ViewModifier {
    let onRefresh: (@Sendable () async -> Void)?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let onRefresh {
            content.refreshable {
                await onRefresh()
            }
        } else {
            content
        }
    }
}

struct GalleryZoomTransitionSourceModifier<ID: Hashable>: ViewModifier {
    let sourceID: ID
    let zoomTransition: GalleryZoomTransition<ID>?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let zoomTransition {
            content.matchedTransitionSource(
                id: sourceID,
                in: zoomTransition.namespace
            )
        } else {
            content
        }
    }
}

struct GalleryCellTapActionModifier: ViewModifier {
    let isEnabled: Bool
    let tapAction: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            Button(action: tapAction) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}
