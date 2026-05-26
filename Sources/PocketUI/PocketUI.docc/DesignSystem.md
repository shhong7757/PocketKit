# PocketUI 디자인 시스템 토큰

PocketUI 컴포넌트에서 반복되는 값은 작은 디자인 시스템 토큰으로 공유합니다.

## 간격

``PocketUISpacing``은 그리드 간격, 라벨 내부 여백, 보조 컨트롤 여백처럼 반복되는
spacing 값을 모아둔 숫자 스케일입니다. `space1`은 4pt이며, 이후 숫자는 4pt 단위
배율을 나타냅니다. 예를 들어 `space2`는 8pt, `space6`은 24pt입니다.

```swift
MediaGalleryLayout(
    spacing: PocketUISpacing.space1
)
```

컴포넌트 기본값은 토큰을 기준으로 맞추지만, 앱 화면에서 더 세밀한 조정이 필요하면
기존처럼 `CGFloat` 값을 직접 전달할 수 있습니다.

## Topics

### 간격

- ``PocketUISpacing``
