# Changelog

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
