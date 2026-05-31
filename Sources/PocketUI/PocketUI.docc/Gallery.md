# GalleryView로 갤러리 구성하기

항목 컬렉션을 선택 가능한 그리드 기반 갤러리로 표시합니다.

## 개요

``GalleryView``는 `LazyVGrid`를 직접 조립할 때 반복되는 선택, 레이아웃,
빈 상태, 추가 로딩, 새로고침 연결을 한곳에 묶은 갤러리 뷰입니다. 탭 이후의
네비게이션, 시트, 상세 화면은 앱에서 직접 결정합니다.

### 기본 그리드

앱 모델은 `Identifiable`이면 충분합니다. 셀 콘텐츠는 앱에서 만든 SwiftUI 뷰를
전달합니다. 각 항목의 접근성 레이블은 앱의 언어와 콘텐츠 맥락에 맞게
`accessibilityLabel`로 전달합니다.

```swift
struct Photo: Identifiable {
    let id: UUID
    let accessibilityLabel: String
}

GalleryView(
    items: items,
    layout: GalleryLayout(
        minimumColumnWidth: 96,
        contentMode: .fill
    ),
    onTap: { item in
        path.append(item.id)
    },
    accessibilityLabel: \.accessibilityLabel
) { item in
    ThumbnailView(item: item)
}
```

### 선택 연결하기

선택은 여러 항목을 토글 선택하는 모드가 필요할 때만 ``GallerySelection``으로
전달합니다. 선택 모드가 필요 없으면 `.none`, 여러 항목을 선택하면 `.multiple`을
사용합니다. 선택 모드에서는 셀 탭이 선택 토글로 처리되며 `onTap`은 호출되지
않습니다. 대표 이미지나 앨범 커버처럼 하나의 항목을 고르는 흐름은 `onTap`에서
앱 상태를 직접 갱신하고, `overlayContent`로 상태에 맞는 표시를 조립하는 편이 더
명확합니다.

```swift
@State private var selectedIDs: Set<Photo.ID> = []

GalleryView(
    items: photos,
    selection: .multiple($selectedIDs),
    accessibilityLabel: \.accessibilityLabel
) { photo in
    PhotoThumbnail(photo: photo)
}
```

선택된 ID로 실제 항목이 필요하면 앱이 가지고 있는 데이터에서 다시 찾습니다.
이렇게 하면 갤러리는 앱의 공유, 다운로드, PhotoKit, 파일 저장 방식을 몰라도 되고,
앱은 선택된 항목을 자기 데이터 모델 그대로 사용할 수 있습니다.

```swift
private var selectedPhotos: [Photo] {
    photos.filter { selectedIDs.contains($0.id) }
}

private func shareSelectedPhotos() {
    share(photos: selectedPhotos)
}

private func downloadSelectedPhotos() async {
    await downloader.download(photos: selectedPhotos)
}
```

```swift
@State private var coverPhotoID: Photo.ID?

GalleryView(
    items: photos,
    selection: .none,
    onTap: { photo in
        coverPhotoID = photo.id
    },
    accessibilityLabel: \.accessibilityLabel
) { photo in
    PhotoThumbnail(photo: photo)
} overlayContent: { photo in
    if coverPhotoID == photo.id {
        CoverBadge()
    }
}
```

### 셀 오버레이 추가하기

갤러리 셀 자체의 크기, 선택 표시, 접근성, 탭 동작은 `GalleryView`가 관리합니다.
앱별 배지나 메타데이터는 `overlayContent`로 전달합니다. 오버레이는 셀의
bottom-leading에 놓이고, 갤러리가 제공하는 선택 표시보다 아래에 그려집니다.

```swift
GalleryView(
    items: photos,
    accessibilityLabel: \.accessibilityLabel
) { photo in
    PhotoThumbnail(photo: photo)
} overlayContent: { photo in
    PhotoMetadataOverlay(photo: photo)
}
```

### 레이아웃 조정하기

``GalleryLayout``는 열 너비, 셀 비율, 간격, 콘텐츠 여백, 스크롤
인디케이터, 셀 안의 콘텐츠 표시 방식을 관리합니다. 메뉴나 segmented control은
앱에서 만들고, 그 결과값만 레이아웃으로 전달합니다.

```swift
GalleryView(
    items: items,
    layout: GalleryLayout(
        spacing: .space0_5,
        minimumColumnWidth: 88,
        maximumColumnWidth: 132,
        contentMode: .fit,
        contentInsets: .all(.space2)
    ),
    contentAspectRatio: \.aspectRatio,
    accessibilityLabel: \.accessibilityLabel
) { item in
    PreviewTile(item: item)
}
```

### 스크롤 위치 연결하기

갤러리의 스크롤 위치를 앱 상태와 연결해야 하면 SwiftUI `ScrollPosition`을
전달합니다. `GalleryView`는 그리드 항목을 scroll target으로 표시하고, 실제
스크롤 위치 상태와 `scrollTo` 호출은 앱이 직접 소유합니다.

```swift
@State private var galleryScrollPosition = ScrollPosition(
    idType: Photo.ID.self
)

GalleryView(
    items: photos,
    scrollPosition: $galleryScrollPosition,
    accessibilityLabel: \.accessibilityLabel
) { photo in
    PhotoThumbnail(photo: photo)
}
.onChange(of: currentPhotoID) { _, currentPhotoID in
    guard let currentPhotoID else { return }

    galleryScrollPosition.scrollTo(id: currentPhotoID, anchor: .center)
}
```

### 상세 화면 연결하기

그리드 셀과 상세 화면을 같은 항목 ID로 연결하려면 ``GalleryZoomTransition``을
전달합니다. 상세 화면이 좌우 페이지 이동과 확대/축소를 제공하면
``GalleryDetailView``를 navigation destination 안에서 사용할 수 있습니다.
`activeItemID`는 현재 페이지와 닫는 줌 전환의 기준 항목으로 함께 갱신됩니다.

```swift
@State private var activePhotoID: Photo.ID?
@State private var galleryScrollPosition = ScrollPosition(
    idType: Photo.ID.self
)
@Namespace private var galleryNamespace

var zoomTransition: GalleryZoomTransition<Photo.ID> {
    GalleryZoomTransition(sourceID: $activePhotoID, in: galleryNamespace)
}

GalleryView(
    items: photos,
    zoomTransition: zoomTransition,
    scrollPosition: $galleryScrollPosition,
    onTap: { photo in
        activePhotoID = photo.id
        path.append(photo.id)
    },
    accessibilityLabel: \.accessibilityLabel
) { photo in
    PhotoThumbnail(photo: photo)
}
.navigationDestination(for: Photo.ID.self) { sourceID in
    GalleryDetailView(
        items: photos,
        sourceItemID: sourceID,
        activeItemID: $activePhotoID,
        zoomTransition: zoomTransition,
        contentAspectRatio: \.aspectRatio,
        onActiveItemChange: { photoID in
            galleryScrollPosition.scrollTo(id: photoID, anchor: .center)
        }
    ) { photo in
        PhotoDetailContent(photo: photo)
    }
}
```

상세 화면의 툴바처럼 현재 포커스된 항목이 필요할 때도 같은 방식으로
`activeItemID`를 앱 데이터로 복원합니다. `activeItemID`는 페이지 이동에 맞춰
갱신되므로, 공유나 다운로드 버튼은 현재 보이는 항목을 기준으로 동작할 수
있습니다.

```swift
private var activePhoto: Photo? {
    activePhotoID.flatMap { photoID in
        photos.first { $0.id == photoID }
    }
}

.navigationDestination(for: Photo.ID.self) { sourceID in
    GalleryDetailView(
        items: photos,
        sourceItemID: sourceID,
        activeItemID: $activePhotoID,
        zoomTransition: zoomTransition,
        contentAspectRatio: \.aspectRatio
    ) { photo in
        PhotoDetailContent(photo: photo)
    }
    .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                guard let activePhoto else { return }

                share(photo: activePhoto)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Button {
                guard let activePhoto else { return }

                download(photo: activePhoto)
            } label: {
                Label("Download", systemImage: "arrow.down.circle")
            }
        }
    }
}
```

데이터가 삭제되거나 페이지네이션 결과가 바뀌는 앱에서는 사라진 ID가 선택 상태에
남지 않도록 앱 상태를 함께 정리합니다.

```swift
.onChange(of: photos.map(\.id)) { _, photoIDs in
    let availablePhotoIDs = Set(photoIDs)

    selectedIDs.formIntersection(availablePhotoIDs)

    if let activePhotoID, !availablePhotoIDs.contains(activePhotoID) {
        self.activePhotoID = photoIDs.first
    }
}
```

### 빈 상태, 다음 페이지, 새로고침

빈 상태는 `emptyContent`로, 끝까지 스크롤했을 때의 다음 페이지 요청은
``GalleryPagination``으로 연결합니다. `threshold`는 마지막 몇 개 항목 중 하나가
보였을 때 `fetchNextPage`를 미리 호출할지 정합니다. `GalleryView`는
`isFetchingNextPage`가 `true`인 동안 같은 경계에 대한 중복 요청을 막습니다.
다음 페이지 요청이 끝나거나 `hasNextPage`가 다시 `true`가 되면 현재 보이는
경계는 다시 요청할 수 있습니다.
플랫폼 새로고침 제스처가 필요하면 `onRefresh`에 async 작업을 전달합니다.

```swift
GalleryView(
    items: items,
    pagination: GalleryPagination(
        hasNextPage: hasNextPage,
        isFetchingNextPage: isFetchingNextPage,
        threshold: 4,
        fetchNextPage: fetchNextPage
    ),
    onRefresh: refresh,
    accessibilityLabel: \.accessibilityLabel
) { item in
    PreviewTile(item: item)
} emptyContent: {
    ContentUnavailableView("No Items", systemImage: "square.grid.2x2")
}
```

## Topics

### 주요 뷰

- ``GalleryView``
- ``GalleryDetailView``

### 레이아웃

- ``GalleryLayout``
- ``GalleryLayout/Insets``
- ``GalleryLayout/ContentDisplayMode``

### 동작 규약

- ``GalleryPagination``
- ``GalleryZoomTransition``

### 선택

- ``GallerySelection``
