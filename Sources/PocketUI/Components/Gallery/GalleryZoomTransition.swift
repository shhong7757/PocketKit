import SwiftUI

/// 갤러리 셀과 상세 화면의 SwiftUI 줌 전환을 연결하는 설정입니다.
public struct GalleryZoomTransition<ID: Hashable> {
    let namespace: Namespace.ID

    let sourceID: Binding<ID?>

    /// 갤러리 줌 전환 설정을 만듭니다.
    public init(
        sourceID: Binding<ID?>,
        in namespace: Namespace.ID
    ) {
        self.namespace = namespace
        self.sourceID = sourceID
    }

    fileprivate func resolvedSourceID(fallback fallbackSourceID: ID) -> ID {
        sourceID.wrappedValue ?? fallbackSourceID
    }

    /// `GalleryView`가 활성화한 항목을 현재 전환 소스로 기록할 때 사용합니다.
    internal func activateSourceID(_ id: ID?) {
        sourceID.wrappedValue = id
    }
}

extension View {
    /// ``GalleryZoomTransition``으로 연결된 상세 화면 내비게이션 전환을 적용합니다.
    ///
    /// `zoomTransition`이 `nil`이면 기본 내비게이션 전환을 유지합니다.
    /// `fallbackSourceID`는 `zoomTransition.sourceID`가 아직 설정되지 않았을 때 사용할
    /// 대체 소스 ID입니다.
    @ViewBuilder
    public func galleryZoomTransition<ID: Hashable>(
        fallbackSourceID: ID,
        using zoomTransition: GalleryZoomTransition<ID>?
    ) -> some View {
        #if os(iOS)
            if let zoomTransition {
                navigationTransition(
                    .zoom(
                        sourceID: zoomTransition.resolvedSourceID(
                            fallback: fallbackSourceID
                        ),
                        in: zoomTransition.namespace
                    )
                )
            } else {
                self
            }
        #else
            self
        #endif
    }
}
