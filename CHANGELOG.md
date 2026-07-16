# Changelog

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
