import SwiftUI

/// 콘텐츠를 맞춰 표시하고 선택적으로 핀치, 팬, 더블 탭 확대/축소를 제공하는 컨테이너입니다.
public struct ZoomableView<Content: View>: View {
    private let behavior: ZoomableViewBehavior
    private let contentAspectRatio: CGFloat?
    private let onZoomStateChange: (Bool) -> Void
    private let content: () -> Content

    @State private var baseScale: CGFloat = 1
    @GestureState private var pinchScale: CGFloat = 1
    @State private var baseOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    @State private var lastReportedIsZoomed = false

    /// 확대/축소 가능한 콘텐츠 컨테이너를 만듭니다.
    ///
    /// 콘텐츠가 사용 가능한 전체 영역을 채우지 않고 컨테이너 안에 맞춰져야 한다면
    /// `contentAspectRatio`를 전달합니다.
    ///
    /// - Parameters:
    ///   - behavior: 콘텐츠에 적용할 제스처 동작입니다.
    ///   - contentAspectRatio: 맞춰 표시할 선택적 가로세로 비율입니다.
    ///   - onZoomStateChange: 콘텐츠가 확대된 상태인지 보고하는 콜백입니다.
    ///   - content: 확대/축소 컨테이너 안에 표시할 SwiftUI 콘텐츠입니다.
    public init(
        behavior: ZoomableViewBehavior = .init(),
        contentAspectRatio: CGFloat? = nil,
        onZoomStateChange: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.behavior = behavior
        self.contentAspectRatio = contentAspectRatio
        self.onZoomStateChange = onZoomStateChange
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            let contentSize = fittedContentSize(in: proxy.size)
            let scale = currentScale
            let offset = displayedOffset(
                in: proxy.size,
                contentSize: contentSize,
                scale: scale
            )
            let transformedContent = ZStack {
                content()
                    .frame(width: contentSize.width, height: contentSize.height)
                    .scaleEffect(scale)
                    .offset(offset)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .animation(Metrics.zoomAnimation, value: baseScale)
            .animation(Metrics.zoomAnimation, value: baseOffset)

            if behavior.isEnabled {
                zoomableContent(
                    transformedContent,
                    in: proxy.size,
                    contentSize: contentSize
                )
            } else {
                transformedContent
            }
        }
        .onAppear {
            reportZoomState(isZoomed)
        }
        .onDisappear {
            reportZoomState(false)
        }
        .onChange(of: baseScale) { _, _ in
            reportZoomState(isZoomed)
        }
        .onChange(of: pinchScale) { _, _ in
            reportZoomState(isZoomed)
        }
    }

    private var currentScale: CGFloat {
        clampedDisplayScale(baseScale * pinchScale)
    }

    private var isZoomed: Bool {
        currentScale > 1
    }

    @ViewBuilder
    private func zoomableContent<TransformedContent: View>(
        _ transformedContent: TransformedContent,
        in size: CGSize,
        contentSize: CGSize
    ) -> some View {
        transformedContent
            .simultaneousGesture(
                pinchGesture(in: size, contentSize: contentSize)
            )
            .simultaneousGesture(
                dragGesture(in: size, contentSize: contentSize),
                including: isZoomed ? .all : .none
            )
            .simultaneousGesture(
                doubleTapGesture(in: size, contentSize: contentSize)
            )
    }

    private func doubleTapGesture(
        in size: CGSize,
        contentSize: CGSize
    ) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                toggleZoom(
                    at: value.location,
                    in: size,
                    contentSize: contentSize
                )
            }
    }

    private func pinchGesture(
        in size: CGSize,
        contentSize: CGSize
    ) -> some Gesture {
        MagnificationGesture()
            .updating($pinchScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let nextScale = clampedStoredScale(baseScale * value)
                baseScale = nextScale
                baseOffset =
                    nextScale <= 1
                    ? .zero
                    : clampedOffset(
                        baseOffset,
                        in: size,
                        contentSize: contentSize,
                        scale: nextScale
                    )
            }
    }

    private func dragGesture(
        in size: CGSize,
        contentSize: CGSize
    ) -> some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                guard currentScale > 1 else { return }
                state = value.translation
            }
            .onEnded { value in
                guard baseScale > 1 else {
                    baseOffset = .zero
                    return
                }

                let nextOffset = CGSize(
                    width: baseOffset.width + value.translation.width,
                    height: baseOffset.height + value.translation.height
                )
                baseOffset = clampedOffset(
                    nextOffset,
                    in: size,
                    contentSize: contentSize,
                    scale: baseScale
                )
            }
    }

    private func toggleZoom(
        at location: CGPoint,
        in size: CGSize,
        contentSize: CGSize
    ) {
        withAnimation(Metrics.zoomAnimation) {
            if baseScale > 1 {
                baseScale = 1
                baseOffset = .zero
            } else {
                let nextScale = behavior.resolvedDoubleTapScale
                baseScale = nextScale
                baseOffset = clampedOffset(
                    doubleTapOffset(
                        at: location,
                        in: size,
                        scale: nextScale
                    ),
                    in: size,
                    contentSize: contentSize,
                    scale: nextScale
                )
            }
        }
    }

    private func doubleTapOffset(
        at location: CGPoint,
        in size: CGSize,
        scale: CGFloat
    ) -> CGSize {
        let center = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )

        return CGSize(
            width: (center.x - location.x) * (scale - 1),
            height: (center.y - location.y) * (scale - 1)
        )
    }

    private func clampedDisplayScale(_ scale: CGFloat) -> CGFloat {
        min(
            max(behavior.resolvedMinimumTransientScale, scale),
            behavior.resolvedMaximumScale
        )
    }

    private func clampedStoredScale(_ scale: CGFloat) -> CGFloat {
        min(max(1, scale), behavior.resolvedMaximumScale)
    }

    private func displayedOffset(
        in size: CGSize,
        contentSize: CGSize,
        scale: CGFloat
    ) -> CGSize {
        guard scale > 1 else { return .zero }
        return clampedOffset(
            CGSize(
                width: baseOffset.width + dragOffset.width,
                height: baseOffset.height + dragOffset.height
            ),
            in: size,
            contentSize: contentSize,
            scale: scale
        )
    }

    private func clampedOffset(
        _ offset: CGSize,
        in size: CGSize,
        contentSize: CGSize,
        scale: CGFloat
    ) -> CGSize {
        let maximumX = max(0, (contentSize.width * scale - size.width) / 2)
        let maximumY = max(0, (contentSize.height * scale - size.height) / 2)

        return CGSize(
            width: min(max(offset.width, -maximumX), maximumX),
            height: min(max(offset.height, -maximumY), maximumY)
        )
    }

    private func fittedContentSize(in containerSize: CGSize) -> CGSize {
        guard containerSize.width > 0,
            containerSize.height > 0
        else {
            return .zero
        }

        guard let contentAspectRatio,
            contentAspectRatio > 0
        else {
            return containerSize
        }

        let containerAspectRatio = containerSize.width / containerSize.height

        if containerAspectRatio > contentAspectRatio {
            let height = containerSize.height
            return CGSize(width: height * contentAspectRatio, height: height)
        }

        let width = containerSize.width
        return CGSize(width: width, height: width / contentAspectRatio)
    }

    private func reportZoomState(_ isZoomed: Bool) {
        guard lastReportedIsZoomed != isZoomed else { return }

        lastReportedIsZoomed = isZoomed
        onZoomStateChange(isZoomed)
    }
}

extension ZoomableView {
    private enum Metrics {
        static var zoomAnimation: Animation {
            .snappy(duration: 0.24)
        }
    }
}

/// ``ZoomableView``의 확대/축소 제스처 설정입니다.
public struct ZoomableViewBehavior: Hashable, Sendable {
    /// 핀치, 팬, 더블 탭 제스처를 활성화할지 여부입니다.
    public let isEnabled: Bool

    /// 저장되는 최대 확대 배율입니다.
    public let maximumScale: CGFloat

    /// 더블 탭으로 확대할 때 사용할 배율입니다.
    public let doubleTapScale: CGFloat

    /// 핀치 중 허용할 가장 낮은 임시 배율입니다.
    public let minimumTransientScale: CGFloat

    /// 확대/축소 제스처 설정을 만듭니다.
    ///
    /// - Parameters:
    ///   - isEnabled: 핀치, 팬, 더블 탭 제스처를 활성화할지 여부입니다.
    ///   - maximumScale: 저장되는 최대 확대 배율입니다.
    ///   - doubleTapScale: 더블 탭으로 확대할 때 사용할 배율입니다.
    ///   - minimumTransientScale: 핀치 중 허용할 가장 낮은 임시 배율입니다.
    public init(
        isEnabled: Bool = true,
        maximumScale: CGFloat = 4,
        doubleTapScale: CGFloat = 2,
        minimumTransientScale: CGFloat = 0.85
    ) {
        self.isEnabled = isEnabled
        self.maximumScale = maximumScale
        self.doubleTapScale = doubleTapScale
        self.minimumTransientScale = minimumTransientScale
    }

    var resolvedMaximumScale: CGFloat {
        max(1, maximumScale)
    }

    var resolvedDoubleTapScale: CGFloat {
        min(max(1, doubleTapScale), resolvedMaximumScale)
    }

    var resolvedMinimumTransientScale: CGFloat {
        min(max(0.1, minimumTransientScale), 1)
    }
}
