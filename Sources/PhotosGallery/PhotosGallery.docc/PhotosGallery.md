# ``PhotosGallery``

Photos 라이브러리의 이미지와 동영상을 SwiftUI 갤러리로 표시하는 컴포넌트입니다.

## 개요

``PhotosGallery``는 사진 보관함 접근 권한 확인, 미디어 페이지 조회, 썸네일 로딩,
새로고침과 추가 페이지 로딩을 하나의 뷰로 연결합니다. 셀 레이아웃과 선택,
상세 화면 전환은 ``PocketUI``의 갤러리 기능을 사용하며, 앱은 콘텐츠와 상태별
화면만 전달하면 됩니다.

## 시작하기

사용 전 앱의 `Info.plist`에 사진 보관함 접근 설명을 추가해야 합니다.

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>사진을 선택하기 위해 사진 보관함에 접근합니다.</string>
```

기본 사용법과 권한, 오류, 상태별 콘텐츠 설정은 <doc:PhotosGalleryUsage>를
참조하세요.

## Topics

### 사용 가이드

- <doc:PhotosGalleryUsage>

### 갤러리

- ``PhotosGallery``
- ``PhotosGallery/Slot``

### 콘텐츠와 필터

- ``PhotosGalleryContent``
- ``PhotosGalleryAccessibility``
- ``PhotosGalleryFilter``
- ``PhotosGalleryMediaType``

### 접근 권한과 오류

- ``PhotosGalleryAccessStatus``
- ``PhotosGalleryAccessStatus/isAccessible``
- ``PhotosGalleryError``
