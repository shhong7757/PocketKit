# PhotosGallery 사용하기

사진 보관함 권한을 확인하고 미디어 갤러리를 화면에 추가하는 방법을 설명합니다.

## 기본 갤러리

`PhotosGallery`는 콘텐츠의 접근성 정보를 앱에서 생성하도록 요구합니다. 최소한
레이블을 반환하면 이미지와 동영상 목록을 표시할 수 있습니다.

```swift
PhotosGallery(
    accessibility: { content in
        PhotosGalleryAccessibility(
            label: content.mediaType == .video ? "동영상" : "사진"
        )
    }
)
```

`filter`로 표시할 미디어 종류를 제한할 수 있습니다.

```swift
PhotosGallery(
    filter: .images,
    accessibility: { _ in
        PhotosGalleryAccessibility(label: "사진")
    }
)
```

``PhotosGalleryFilter/all``은 이미지와 동영상을 모두 표시합니다. Live Photo를
포함하려면 `includeLivePhotos`를 `true`로 설정합니다.

## 사진 보관함 권한

권한이 아직 결정되지 않았다면 갤러리가 접근 권한을 요청합니다. 사용자가 제한된
접근을 허용한 경우에도 ``PhotosGalleryAccessStatus/isAccessible``가 `true`이므로
허용된 항목을 표시할 수 있습니다.

접근이 불가능한 상태에서는 `unavailableContent`로 상태별 안내 화면을 제공할 수
있습니다.

```swift
PhotosGallery(
    accessibility: { _ in
        PhotosGalleryAccessibility(label: "사진")
    },
    unavailableContent: { status in
        PhotosGallery.Slot {
            VStack(spacing: 12) {
                Text("사진에 접근할 수 없습니다")
                Text(String(describing: status))
                    .font(.caption)
            }
        }
    }
)
```

앱의 `Info.plist`에는 다음 키가 필요합니다.

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>사진을 선택하기 위해 사진 보관함에 접근합니다.</string>
```

## 선택과 탭 처리

여러 항목을 선택하는 흐름은 ``PocketUI/GallerySelection``을 전달합니다. 선택된 ID는
`PhotosGalleryContent.id`와 같은 문자열입니다.

```swift
@State private var selectedIDs: Set<String> = []

PhotosGallery(
    selection: .multiple($selectedIDs),
    accessibility: { _ in
        PhotosGalleryAccessibility(label: "사진")
    }
)
```

선택 모드가 아닐 때 항목 탭은 `onTap`으로 전달됩니다.

```swift
PhotosGallery(
    accessibility: { _ in
        PhotosGalleryAccessibility(label: "사진")
    },
    onTap: { content in
        openDetail(for: content.id)
    }
)
```

## 상태별 콘텐츠

다음 슬롯으로 기본 화면을 앱의 디자인에 맞게 바꿀 수 있습니다.

- `loadingContent`: 권한 확인 또는 첫 페이지를 불러오는 동안 표시합니다.
- `unavailableContent`: 사진 보관함에 접근할 수 없을 때 표시합니다.
- `emptyContent`: 접근은 가능하지만 표시할 항목이 없을 때 표시합니다.
- `headerContent`, `footerContent`: ``PhotosGalleryContext``를 받아 갤러리 위·아래에
  상태에 맞는 콘텐츠를 추가합니다.

```swift
PhotosGallery(
    accessibility: { _ in
        PhotosGalleryAccessibility(label: "사진")
    },
    loadingContent: PhotosGallery.Slot {
        ProgressView("불러오는 중")
    },
    emptyContent: PhotosGallery.Slot {
        ContentUnavailableView("사진 없음", systemImage: "photo")
    },
    headerContent: PhotosGallery.Slot { context in
        Text("현재 사진 수: \(context.contentCount)")
    }
)
```

## 오류 처리

권한 요청이나 페이지 조회에 실패하면 `onError`가 호출됩니다. 오류 종류는
``PhotosGalleryError``로 구분할 수 있습니다.

```swift
PhotosGallery(
    accessibility: { _ in
        PhotosGalleryAccessibility(label: "사진")
    },
    onError: { error in
        switch error {
        case .photoLibraryAccessDenied:
            showMessage("사진 접근 권한을 허용해 주세요.")
        case .photoLibraryAccessRestricted:
            showMessage("이 기기에서는 사진 접근이 제한되어 있습니다.")
        case .pageFetchFailed:
            showMessage("사진을 불러오지 못했습니다.")
        }
    }
)
```

`onError`는 메인 액터에서 호출되므로 화면 상태를 안전하게 갱신할 수 있습니다.

## 새로고침과 페이지네이션

갤러리의 당겨서 새로고침과 다음 페이지 로딩은 기본으로 연결되어 있습니다.
사용자가 마지막 항목에 가까워지면 다음 페이지를 미리 요청하며, 로딩 중복은
갤러리가 방지합니다.

## 관련 문서

- ``PocketUI/GalleryView``
- ``PocketUI/GalleryLayout``
- ``PocketUI/GallerySelection``
- ``PocketUI/GalleryDetailView``
