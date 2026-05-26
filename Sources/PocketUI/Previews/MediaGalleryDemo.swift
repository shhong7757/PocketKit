import Foundation
import SwiftUI

private enum MediaGalleryDemoFixtures {
    static let items = [
        item("alpine", "Square 1:1", "Square alpine landscape", 1),
        item("city", "Classic 4:3", "Classic city skyline", 4.0 / 3.0),
        item("coast", "Wide 16:9", "Wide coastal water", 16.0 / 9.0),
        item("forest", "Portrait 3:4", "Portrait forest path", 3.0 / 4.0),
        item("studio", "Poster 2:3", "Poster studio portrait", 2.0 / 3.0),
        item("night", "Tall 9:16", "Tall night street", 9.0 / 16.0),
        item("banner", "Banner 5:2", "Banner desert horizon", 5.0 / 2.0),
        item("panorama", "Panorama 21:9", "Panorama mountain range", 21.0 / 9.0),
        item("ultrawide", "Ultra 3:1", "Ultra wide bridge view", 3.0 / 1.0),
        item("skinny", "Skinny 1:2", "Skinny vertical architecture", 1.0 / 2.0),
        item("strip", "Strip 4:1", "Strip city lights", 4.0 / 1.0),
        item("fallback", "No Ratio", "Media item without an aspect ratio"),
    ]

    private static func item(
        _ id: String,
        _ title: String,
        _ accessibilityLabel: String,
        _ aspectRatio: CGFloat? = nil
    ) -> MediaGalleryDemoItem {
        MediaGalleryDemoItem(
            id: id,
            title: title,
            accessibilityLabel: accessibilityLabel,
            aspectRatio: aspectRatio
        )
    }
}

struct MediaGalleryDemoItem: Hashable, Identifiable {
    let id: String
    let title: String
    let accessibilityLabel: String
    let aspectRatio: CGFloat?
}

struct MediaGalleryDemo: View {
    private let items: [MediaGalleryDemoItem]
    private let isLoadingMore: Bool

    @State private var selection: MediaGalleryDemoItem?
    @State private var contentDisplayMode: MediaGalleryContentDisplayMode = .fill
    @State private var gridDensity: MediaGalleryDemoGridDensity = .comfortable

    init(
        items: [MediaGalleryDemoItem] = MediaGalleryDemoFixtures.items,
        isLoadingMore: Bool = false
    ) {
        self.items = items
        self.isLoadingMore = isLoadingMore
    }

    var body: some View {
        NavigationStack {
            MediaGalleryView(
                items: items,
                selection: $selection,
                contentDisplayMode: contentDisplayMode,
                layout: gridDensity.layout,
                contentAspectRatio: \.aspectRatio,
                accessibilityLabel: \.accessibilityLabel,
                canLoadMore: false,
                isLoadingMore: isLoadingMore
            ) { item in
                MediaGalleryPreviewTile(item: item)
            } detailContent: { item in
                MediaGalleryPreviewTile(item: item)
            } overlayContent: { item in
                MediaGalleryPreviewGridOverlay(item: item)
            } emptyStateContent: {
                ContentUnavailableView("No Media", systemImage: "photo")
            } detailToolbarContent: { item in
                MediaGalleryDetailToolbar(
                    pageIndicatorText: pageIndicatorText(for: item)
                )
            }
            .navigationTitle("Gallery")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    MediaGalleryViewOptionsMenu(
                        contentDisplayMode: $contentDisplayMode,
                        gridDensity: $gridDensity
                    )
                }
            }
        }
    }

    private func pageIndicatorText(for item: MediaGalleryDemoItem) -> String? {
        guard let index = items.firstIndex(of: item) else { return nil }

        return "\(index + 1) / \(items.count)"
    }
}

private struct MediaGalleryViewOptionsMenu: View {
    @Binding var contentDisplayMode: MediaGalleryContentDisplayMode
    @Binding var gridDensity: MediaGalleryDemoGridDensity

    var body: some View {
        Menu {
            Section("View Options") {
                Toggle(isOn: contentDisplayModeBinding(for: .fill)) {
                    Label("Fill Cell", systemImage: "rectangle.fill")
                }

                Toggle(isOn: contentDisplayModeBinding(for: .fit)) {
                    Label("Fit Aspect Ratio", systemImage: "arrow.down.right.and.arrow.up.left")
                }
            }

            Section("Grid Density") {
                Picker("Grid Density", selection: $gridDensity) {
                    ForEach(MediaGalleryDemoGridDensity.allCases) { density in
                        Label(density.title, systemImage: density.systemImage)
                            .tag(density)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel(Text("View Options"))
    }

    private func contentDisplayModeBinding(
        for candidate: MediaGalleryContentDisplayMode
    ) -> Binding<Bool> {
        Binding {
            contentDisplayMode == candidate
        } set: { isOn in
            if isOn {
                contentDisplayMode = candidate
            }
        }
    }
}

private enum MediaGalleryDemoGridDensity: CaseIterable, Identifiable {
    case comfortable
    case dense

    var id: Self { self }

    var title: String {
        switch self {
        case .comfortable:
            return "Comfortable"
        case .dense:
            return "Dense"
        }
    }

    var systemImage: String {
        switch self {
        case .comfortable:
            return "square.grid.2x2"
        case .dense:
            return "square.grid.3x3"
        }
    }

    var layout: MediaGalleryLayout {
        switch self {
        case .comfortable:
            return MediaGalleryLayout()
        case .dense:
            return MediaGalleryLayout(
                spacing: PocketUISpacing.spaceHalf,
                minimumColumnWidth: 88,
                maximumColumnWidth: 132
            )
        }
    }
}

private struct MediaGalleryPreviewTile: View {
    let item: MediaGalleryDemoItem

    var body: some View {
        MediaGalleryDemoGradient(item: item)
    }
}

private struct MediaGalleryPreviewGridOverlay: View {
    let item: MediaGalleryDemoItem

    var body: some View {
        Text(item.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(PocketUISpacing.space2)
    }
}

private struct MediaGalleryDetailToolbar: ToolbarContent {
    let pageIndicatorText: String?

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            toolbarButton(systemImage: "heart", accessibilityLabel: "Favorite")
            toolbarButton(systemImage: "square.and.arrow.up", accessibilityLabel: "Share")
            toolbarButton(systemImage: "ellipsis", accessibilityLabel: "More")
        }

        if let pageIndicatorText {
            #if os(iOS)
                ToolbarItem(placement: .bottomBar) {
                    MediaGalleryPageIndicator(text: pageIndicatorText)
                }
            #else
                ToolbarItem(placement: .automatic) {
                    MediaGalleryPageIndicator(text: pageIndicatorText)
                }
            #endif
        }
    }

    private func toolbarButton(
        systemImage: String,
        accessibilityLabel: LocalizedStringKey
    ) -> some View {
        Button {
        } label: {
            Image(systemName: systemImage)
        }
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

private struct MediaGalleryPageIndicator: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .frame(minWidth: 64)
            .padding(.horizontal, PocketUISpacing.space3)
            .padding(.vertical, PocketUISpacing.space2)
            .accessibilityLabel(Text("Page \(text)"))
    }
}

private struct MediaGalleryDemoGradient: View {
    let item: MediaGalleryDemoItem

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var colors: [Color] {
        switch item.id {
        case "alpine":
            return [.teal, .blue]
        case "city":
            return [.indigo, .pink]
        case "coast":
            return [.cyan, .mint]
        case "forest":
            return [.green, .brown]
        case "studio":
            return [.orange, .red]
        case "night":
            return [.purple, .black]
        case "banner":
            return [.yellow, .orange]
        case "panorama":
            return [.blue, .indigo]
        case "ultrawide":
            return [.mint, .teal]
        case "skinny":
            return [.pink, .purple]
        case "strip":
            return [.red, .black]
        case "fallback":
            return [.gray, .secondary]
        default:
            return [.purple, .black]
        }
    }
}

#Preview("Gallery") {
    MediaGalleryDemo()
}

#Preview("Gallery Loading More") {
    MediaGalleryDemo(
        items: Array(MediaGalleryDemoFixtures.items.prefix(4)),
        isLoadingMore: true
    )
}
