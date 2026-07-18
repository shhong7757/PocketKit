# PocketKit

개인 앱에서 반복해서 사용하는 SwiftUI 컴포넌트와 로컬 저장소를 모아둔 Swift 패키지입니다.

## Modules

- `PocketUI`: SwiftUI 화면 컴포넌트
- `PocketStorage`: Swift용 AsyncStorage 스타일의 로컬 저장소
- `PhotosGallery`: Photos 라이브러리 기반 이미지·동영상 갤러리

## PhotosGallery 권한 설정

`PhotosGallery`를 사용하는 앱의 `Info.plist`에 사진 보관함 접근 설명을 추가해야 합니다.

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>사진을 선택하기 위해 사진 보관함에 접근합니다.</string>
```

## Documentation

- [PocketStorage DocC catalog](Sources/PocketStorage/PocketStorage.docc/PocketStorage.md)
- [PocketUI DocC catalog](Sources/PocketUI/PocketUI.docc/PocketUI.md)
