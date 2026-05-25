# ZoomableView로 콘텐츠 확대/축소하기

앱이 제공한 SwiftUI 콘텐츠를 확대하고 이동할 수 있게 합니다.

## 개요

``ZoomableView``는 콘텐츠를 컨테이너 안에 맞춰 배치하고, 핀치, 팬, 더블 탭
확대/축소를 적용하는 컨테이너입니다. ``MediaGalleryView``의 상세 화면도 이
컴포넌트를 사용합니다.

기본값은 일반적인 이미지 뷰어처럼 동작합니다. 제스처 없이 고정된 콘텐츠가
필요할 때는 `ZoomableViewBehavior(isEnabled: false)`를 전달합니다.

### 콘텐츠 맞추기

콘텐츠의 가로세로 비율을 알고 있다면 `contentAspectRatio`를 전달합니다. 그러면
콘텐츠가 사용 가능한 영역 안에서 자연스럽게 맞춰집니다.

```swift
ZoomableView(
    contentAspectRatio: media.aspectRatio
) {
    image
        .resizable()
        .scaledToFit()
}
```

비율이 없으면 사용 가능한 전체 영역을 콘텐츠 영역으로 사용합니다.

### 확대 상태 전달하기

부모 뷰가 확대 상태에 맞춰 UI나 제스처를 조정해야 한다면 `onZoomStateChange`를
사용합니다.

```swift
@State private var isZoomed = false

ZoomableView(
    contentAspectRatio: media.aspectRatio,
    onZoomStateChange: { isZoomed = $0 }
) {
    AppDetailImage(item: media)
}
```

``MediaGalleryView``도 이 콜백을 이용해 확대된 콘텐츠와 페이지 이동 제스처가
부딪히지 않도록 조정합니다.

### 동작 조정하기

기본 배율이 화면에 맞지 않으면 직접 ``ZoomableViewBehavior``를 만들어 전달할
수 있습니다.

```swift
ZoomableView(
    behavior: ZoomableViewBehavior(
        isEnabled: true,
        maximumScale: 6,
        doubleTapScale: 3,
        minimumTransientScale: 0.85
    ),
    contentAspectRatio: media.aspectRatio
) {
    AppDetailImage(item: media)
}
```

배율 값은 사용 전에 안전한 범위로 보정됩니다. 각 값의 의미는 API 레퍼런스에서
확인할 수 있습니다.

## Topics

### 확대 컨테이너

- ``ZoomableView``

### 동작

- ``ZoomableViewBehavior``
