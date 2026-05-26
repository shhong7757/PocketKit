# MediaGalleryView로 갤러리 구성하기

앱이 소유한 미디어 항목을 그리드와 상세 화면으로 보여줍니다.

## 개요

``MediaGalleryView``는 앱의 `Identifiable` 항목을 썸네일 그리드와 상세 화면으로
연결하는 기본 갤러리 흐름입니다.

### 데이터 연결하기

PocketUI는 별도의 미디어 타입을 요구하지 않습니다. 앱에서 이미 쓰고 있는
`Identifiable` 타입을 그대로 전달하면 됩니다.

```swift
struct AppMedia: Identifiable, Hashable {
    let id: String
    let title: String
    let accessibilityLabel: String
    let aspectRatio: CGFloat?
}
```

필요한 메타데이터는 클로저나 키 경로로 연결합니다. 예를 들어
`contentAspectRatio`와 `accessibilityLabel`은 앱의 모델에서 자연스럽게 꺼내 쓸
수 있습니다.

### 갤러리 표시하기

``MediaGalleryView``는 `NavigationStack` 안에서 사용합니다. `thumbnailContent`와
`detailContent`에는 앱에서 만든 SwiftUI 뷰를 전달합니다.

```swift
struct GalleryScreen: View {
    @State private var selection: AppMedia?

    let items: [AppMedia]

    var body: some View {
        NavigationStack {
            MediaGalleryView(
                items: items,
                selection: $selection,
                contentAspectRatio: \.aspectRatio,
                accessibilityLabel: \.accessibilityLabel,
                canLoadMore: false
            ) { item in
                AppThumbnail(item: item)
            } detailContent: { item in
                AppDetailImage(item: item)
            }
            .navigationTitle("Gallery")
        }
    }
}
```

`selection`은 상세 화면에 표시되는 항목과 동기화됩니다.

### 필요한 UI 더하기

셀 위에 제목이나 배지를 얹고 싶다면 `overlayContent`를, 상세 화면에 앱별 버튼을
넣고 싶다면 `detailToolbarContent`를 사용합니다. 비어 있는 상태는
`emptyStateContent`로 바꿀 수 있습니다.

```swift
MediaGalleryView(
    items: items,
    selection: $selection,
    accessibilityLabel: \.accessibilityLabel
) { item in
    AppThumbnail(item: item)
} detailContent: { item in
    AppDetailImage(item: item)
} overlayContent: { item in
    Text(item.title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(PocketUISpacing.space2)
} emptyStateContent: {
    ContentUnavailableView("No Media", systemImage: "photo")
} detailToolbarContent: { item in
    ToolbarItem(placement: .principal) {
        Text(item.title)
    }
}
```

상세 화면의 제목, 액션, 페이지 표시, 메타데이터는 앱마다 다르기 때문에 앱에서
직접 구성합니다.

### 레이아웃 조정하기

간격, 열 너비, 셀 비율, 스크롤 인디케이터는 ``MediaGalleryLayout``으로
조정합니다. 셀을 꽉 채우려면 ``MediaGalleryContentDisplayMode/fill``을, 항목별
비율을 보존하려면 ``MediaGalleryContentDisplayMode/fit``을 사용합니다.
반복되는 간격 값은 ``PocketUISpacing`` 토큰을 사용할 수 있습니다.

### 더 불러오기

페이지네이션이 필요한 화면에서는 `canLoadMore`, `isLoadingMore`, `onLoadMore`를
앱의 로딩 상태에 연결합니다.

```swift
MediaGalleryView(
    items: items,
    selection: $selection,
    canLoadMore: hasNextPage && !isLoadingMore,
    isLoadingMore: isLoadingMore,
    onLoadMore: loadNextPage
) { item in
    AppThumbnail(item: item)
} detailContent: { item in
    AppDetailImage(item: item)
}
```

PocketUI는 마지막 항목이 보였는지를 판단하고, `isLoadingMore`가 `true`일 때
그리드 하단에 진행 표시기를 보여줍니다. 요청 중복 제거, 실패 후 재시도, 초기
로딩 화면은 앱에서 정합니다.

### 확대/축소 조정하기

상세 화면의 확대/축소는 기본으로 켜져 있습니다. 제스처를 끄거나 배율을 바꾸고
싶다면 `zoomBehavior`에 ``ZoomableViewBehavior`` 값을 전달합니다. 자세한
내용은 <doc:ZoomableContent>에서 다룹니다.

### 접근성 챙기기

그리드 셀의 보이는 텍스트가 VoiceOver 라벨로 충분하지 않다면
`accessibilityLabel`을 전달합니다. 내부 ID나 파일명보다 사용자가 이해할 수
있는 짧은 설명이 좋습니다.

## Topics

### 주요 뷰

- ``MediaGalleryView``

### 레이아웃

- ``MediaGalleryLayout``
- ``MediaGalleryContentDisplayMode``

### 보조 타입

- ``MediaGalleryEmptyToolbarContent``
