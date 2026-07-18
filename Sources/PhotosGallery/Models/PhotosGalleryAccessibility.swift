/// Accessibility information for a PhotosGallery content item.
public struct PhotosGalleryAccessibility: Sendable, Equatable {
    /// Identifies the content item.
    public let label: String

    /// Describes additional metadata or state for the content item.
    public let value: String?

    public init(
        label: String,
        value: String? = nil
    ) {
        self.label = label
        self.value = value
    }
}
