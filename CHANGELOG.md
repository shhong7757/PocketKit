# Changelog

## v0.4.1 - 2026-07-18

### Added

- Added DocC documentation for the PhotosGallery module and its usage patterns.

### Changed

- Updated PhotosGallery thumbnails to fill their gallery cells using `scaledToFill`.

### Fixed

- Aligned loaded gallery content to start from the top instead of the vertical center.

## v0.4.0 - 2026-07-18

### Breaking Changes

- Replaced the `PhotosGallery.accessibilityLabel` closure with an `accessibility` closure that returns `PhotosGalleryAccessibility`.
- Replaced `GalleryPagination.threshold` with the viewport-based `visibilityThreshold`.
- Removed the public `PhotosGallery.paginationThreshold` parameter; page size and visibility threshold are now managed by the module's paging policy.
- Made `PhotosGallery.filter`, `includeLivePhotos`, and `layout` non-optional parameters with defaults.

### Added

- Added the `PhotosGallery` product for browsing and selecting images and videos from the Photos library.
- Added Photos library authorization handling with loading, unavailable, and empty content injection.
- Added paginated image and video loading with refresh and next-page support.
- Added Live Photo filtering and Live Photo indicators.
- Added video duration metadata and accessibility values.
- Added `PhotosGalleryAccessibility` for localized item labels and additional accessibility metadata.
- Added viewport visibility-based pagination using SwiftUI's scroll visibility APIs.
- Added configurable header and footer content for PhotosGallery previews and consumers.

### Changed

- Delegated loading, unavailable, and empty-state presentation to the consuming view.
- Moved PhotosGallery paging constants into `PhotosGalleryPagingPolicy`.
- Added color-based preview placeholders to make different media items easier to distinguish.

### Fixed

- Prevented thumbnail cropping by fitting thumbnails within their cells.
- Prevented duplicate next-page requests for the same pagination boundary.
- Added thumbnail request cancellation and cache cleanup when gallery cells disappear.

## v0.3.0 - 2026-07-17

### Added

- Added the new `PocketStorage` product with actor-based `PocketStore` APIs.
- Added explicit asynchronous `set`, `value`, and `remove` operations for `Codable & Sendable` values.
- Added `value(forKey:default:)` for default-value reads.
- Added `PocketStoreKey<Value>` and typed-key overloads.
- Added `PocketStoreError` for encoding and decoding failures.
- Added focused `PocketStorage` documentation and storage tests.

### Changed

- `PocketStorage` stores `Codable & Sendable` values as JSON data in `UserDefaults`.
- Kept `PocketUI` as a separate package product alongside `PocketStorage`.

## v0.2.0 - 2026-05-31

### Breaking Changes

- Replaced the previous `MediaGallery` API with the new `Gallery` components in `PocketUI`.
- Removed `PocketUISpacing`; use the public `CGFloat` spacing tokens such as `.space0_5`, `.space1`, and `.space2` instead.

### Added

- Added `GalleryDetailView` for detail browsing flows with stable page selection fallback behavior.
- Added Gallery documentation, previews, localization strings, and focused behavior coverage for layout, pagination, selection, and detail selection.

### Changed

- Updated the package product naming around the `PocketUI` target after the Gallery migration.
- Simplified the design-system surface by keeping spacing tokens on `CGFloat`.
