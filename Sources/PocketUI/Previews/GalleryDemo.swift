import Foundation
import SwiftUI

private enum GalleryDemoFixtures {
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
    ) -> GalleryDemoItem {
        GalleryDemoItem(
            id: id,
            title: title,
            accessibilityLabel: accessibilityLabel,
            aspectRatio: aspectRatio
        )
    }
}

struct GalleryDemoItem: Identifiable, Hashable {
    let id: String
    let title: String
    let accessibilityLabel: String
    let aspectRatio: CGFloat?
}

struct GalleryDemo: View {
    private let items: [GalleryDemoItem]
    private let isFetchingNextPage: Bool

    @State private var path: [GalleryDemoItem.ID] = []
    @State private var activeItemID: GalleryDemoItem.ID?
    @State private var scrollPosition = ScrollPosition(
        idType: GalleryDemoItem.ID.self
    )
    @State private var isSelectionEnabled = false
    @State private var selectedIDs: Set<GalleryDemoItem.ID> = []
    @State private var contentMode: GalleryLayout.ContentDisplayMode = .fill
    @State private var gridDensity: GalleryDemoGridDensity = .comfortable
    @Namespace private var transitionNamespace

    init(
        items: [GalleryDemoItem] = GalleryDemoFixtures.items,
        isFetchingNextPage: Bool = false
    ) {
        self.items = items
        self.isFetchingNextPage = isFetchingNextPage
    }

    var body: some View {
        NavigationStack(path: $path) {
            GalleryView(
                items: items,
                selection: gallerySelection,
                layout: gridDensity.layout(contentMode: contentMode),
                zoomTransition: zoomTransition,
                scrollPosition: $scrollPosition,
                contentAspectRatio: \.aspectRatio,
                accessibilityLabel: \.accessibilityLabel,
                pagination: GalleryPagination(
                    isFetchingNextPage: isFetchingNextPage
                ),
                onTap: openItemAction,
                content: { item in
                    GalleryDemoPreviewTile(item: item)
                },
                overlayContent: { item in
                    GalleryDemoGridOverlay(item: item)
                },
                emptyContent: {
                    ContentUnavailableView("No Media", systemImage: "photo")
                }
            )
            .navigationTitle("Gallery")
            .navigationDestination(for: GalleryDemoItem.ID.self) { itemID in
                GalleryDemoDetailScreen(
                    items: items,
                    sourceItemID: itemID,
                    activeItemID: $activeItemID,
                    onActiveItemChange: scrollToItem,
                    zoomTransition: zoomTransition
                )
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    GalleryDemoOptionsMenu(
                        contentMode: $contentMode,
                        gridDensity: $gridDensity
                    )
                }

                GalleryDemoSelectionToolbar(
                    isSelectionEnabled: $isSelectionEnabled,
                    selectedIDs: $selectedIDs
                )
            }
        }
    }

    private var gallerySelection: GallerySelection<GalleryDemoItem.ID> {
        isSelectionEnabled ? .multiple($selectedIDs) : .none
    }

    private var openItemAction: ((GalleryDemoItem) -> Void)? {
        if isSelectionEnabled {
            return nil
        }

        return openItem
    }

    private var zoomTransition: GalleryZoomTransition<GalleryDemoItem.ID> {
        GalleryZoomTransition(sourceID: $activeItemID, in: transitionNamespace)
    }

    private func openItem(_ item: GalleryDemoItem) {
        activeItemID = item.id
        path.append(item.id)
    }

    private func scrollToItem(_ itemID: GalleryDemoItem.ID) {
        scrollPosition.scrollTo(id: itemID, anchor: .center)
    }
}

private struct GalleryDemoDetailScreen: View {
    let items: [GalleryDemoItem]
    let sourceItemID: GalleryDemoItem.ID
    @Binding var activeItemID: GalleryDemoItem.ID?
    let onActiveItemChange: (GalleryDemoItem.ID) -> Void
    let zoomTransition: GalleryZoomTransition<GalleryDemoItem.ID>

    var body: some View {
        GalleryDetailView(
            items: items,
            sourceItemID: sourceItemID,
            activeItemID: $activeItemID,
            zoomTransition: zoomTransition,
            contentAspectRatio: \.aspectRatio,
            onActiveItemChange: onActiveItemChange,
            content: { item in
                GalleryDemoPreviewTile(item: item)
            },
            emptyContent: {
                ContentUnavailableView("No Media", systemImage: "photo")
            }
        )
        .toolbar {
            GalleryDemoDetailToolbar(
                pageIndicatorText: pageIndicatorText
            )
        }
    }

    private var selectedIndex: Int? {
        guard let selectedItemID else { return nil }

        return items.firstIndex { $0.id == selectedItemID }
    }

    private var selectedItemID: GalleryDemoItem.ID? {
        if let activeItemID,
            items.contains(where: { $0.id == activeItemID })
        {
            return activeItemID
        }

        if items.contains(where: { $0.id == sourceItemID }) {
            return sourceItemID
        }

        return items.first?.id
    }

    private var pageIndicatorText: String? {
        guard let selectedIndex else { return nil }

        return "\(selectedIndex + 1) / \(items.count)"
    }
}

private struct GalleryDemoOptionsMenu: View {
    @Binding var contentMode: GalleryLayout.ContentDisplayMode
    @Binding var gridDensity: GalleryDemoGridDensity

    var body: some View {
        Menu {
            Section("View Options") {
                Toggle(isOn: contentModeBinding(for: .fill)) {
                    Label("Fill Cell", systemImage: "rectangle.fill")
                }

                Toggle(isOn: contentModeBinding(for: .fit)) {
                    Label("Fit Aspect Ratio", systemImage: "arrow.down.right.and.arrow.up.left")
                }
            }

            Section("Grid Density") {
                Picker("Grid Density", selection: $gridDensity) {
                    ForEach(GalleryDemoGridDensity.allCases) { density in
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

    private func contentModeBinding(
        for candidate: GalleryLayout.ContentDisplayMode
    ) -> Binding<Bool> {
        Binding {
            contentMode == candidate
        } set: { isOn in
            if isOn {
                contentMode = candidate
            }
        }
    }
}

private enum GalleryDemoGridDensity: CaseIterable, Identifiable {
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

    func layout(
        contentMode: GalleryLayout.ContentDisplayMode
    ) -> GalleryLayout {
        switch self {
        case .comfortable:
            return GalleryLayout(
                contentMode: contentMode
            )
        case .dense:
            return GalleryLayout(
                spacing: .space0_5,
                minimumColumnWidth: 88,
                maximumColumnWidth: 132,
                contentMode: contentMode
            )
        }
    }
}

private struct GalleryDemoPreviewTile: View {
    let item: GalleryDemoItem

    var body: some View {
        GalleryDemoGradient(item: item)
    }
}

private struct GalleryDemoGridOverlay: View {
    let item: GalleryDemoItem

    var body: some View {
        Text(item.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.space2)
    }
}

private struct GalleryDemoSelectionToolbar: ToolbarContent {
    @Binding var isSelectionEnabled: Bool
    @Binding var selectedIDs: Set<GalleryDemoItem.ID>

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: toggleSelectionMode) {
                Image(
                    systemName: isSelectionEnabled
                        ? "checkmark.circle.fill"
                        : "checkmark.circle"
                )
            }
            .accessibilityLabel(Text(selectionToggleAccessibilityLabel))
        }
    }

    private var selectionToggleAccessibilityLabel: LocalizedStringKey {
        isSelectionEnabled ? "Finish Selection" : "Select Items"
    }

    private func toggleSelectionMode() {
        isSelectionEnabled.toggle()

        if !isSelectionEnabled {
            selectedIDs.removeAll()
        }
    }
}

private struct GalleryDemoDetailToolbar: ToolbarContent {
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
                    GalleryDemoPageIndicator(text: pageIndicatorText)
                }
            #else
                ToolbarItem(placement: .automatic) {
                    GalleryDemoPageIndicator(text: pageIndicatorText)
                }
            #endif
        }
    }

    private func toolbarButton(
        systemImage: String,
        accessibilityLabel: LocalizedStringKey,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
        }
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

private struct GalleryDemoPageIndicator: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .frame(minWidth: 64)
            .padding(.horizontal, .space3)
            .padding(.vertical, .space2)
            .accessibilityLabel(Text("Page \(text)"))
    }
}

private struct GalleryDemoGradient: View {
    let item: GalleryDemoItem

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
    GalleryDemo()
}

#Preview("Gallery Fetching Next Page") {
    GalleryDemo(
        items: Array(GalleryDemoFixtures.items.prefix(4)),
        isFetchingNextPage: true
    )
}
