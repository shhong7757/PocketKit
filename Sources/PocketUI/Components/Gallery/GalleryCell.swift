import SwiftUI

struct GalleryCell<Content: View, OverlayContent: View>: View {
    private enum Metrics {
        static var backgroundOpacity: Double { 0.1 }
        static var borderOpacity: Double { 0.06 }
        static var borderWidth: CGFloat { 1 }
        static var selectionBadgePadding: CGFloat { 6 }
        static var selectionBadgeSize: CGFloat { 28 }
        static var selectionBorderWidth: CGFloat { 3 }
        static var selectionIndicatorOpacity: Double { 0.38 }
        static var selectionTintOpacity: Double { 0.18 }
    }

    let contentMode: GalleryLayout.ContentDisplayMode
    let cellAspectRatio: CGFloat
    let contentAspectRatio: CGFloat?
    let isSelected: Bool
    let showsSelectionIndicator: Bool
    let hasTapAction: Bool
    let accessibilityLabel: String
    let contentAccessibilityValue: String?
    let content: Content
    let overlayContent: OverlayContent

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let resolvedContentSize = contentMode.resolvedContentSize(
                    contentAspectRatio: contentAspectRatio,
                    in: proxy.size
                )

                content
                    .frame(
                        width: resolvedContentSize.width,
                        height: resolvedContentSize.height
                    )
                    .clipped()
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height / 2
                    )
            }
        }
        .aspectRatio(cellAspectRatio, contentMode: .fit)
        .background(Color.secondary.opacity(Metrics.backgroundOpacity))
        .clipShape(Rectangle())
        .overlay {
            Rectangle()
                .stroke(
                    Color.primary.opacity(Metrics.borderOpacity),
                    lineWidth: Metrics.borderWidth
                )
        }
        .overlay(alignment: .bottomLeading) {
            overlayContent
        }
        .overlay {
            if isSelected {
                ZStack {
                    Rectangle()
                        .fill(
                            Color.accentColor.opacity(
                                Metrics.selectionTintOpacity
                            )
                        )
                    Rectangle()
                        .stroke(
                            Color.accentColor,
                            lineWidth: Metrics.selectionBorderWidth
                        )
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if showsSelectionIndicator {
                selectionIndicator
            }
        }
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.16), value: isSelected)
        .animation(.easeInOut(duration: 0.16), value: showsSelectionIndicator)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .modifier(
            GalleryAccessibilityValueModifier(
                accessibilityValue: resolvedAccessibilityValue
            )
        )
        .modifier(
            GalleryAccessibilityHintModifier(
                accessibilityHint: accessibilityHint
            )
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var selectionIndicatorFill: Color {
        isSelected
            ? Color.accentColor
            : Color.black.opacity(Metrics.selectionIndicatorOpacity)
    }

    private var resolvedAccessibilityValue: String? {
        var values: [String] = []

        if let contentAccessibilityValue,
           !contentAccessibilityValue.isEmpty {
            values.append(contentAccessibilityValue)
        }

        guard showsSelectionIndicator else {
            return values.isEmpty ? nil : values.joined(separator: ", ")
        }

        values.append(isSelected
            ? GalleryAccessibilityText.selected
            : GalleryAccessibilityText.notSelected)

        return values.joined(separator: ", ")
    }

    private var accessibilityHint: String? {
        if showsSelectionIndicator {
            return isSelected
                ? GalleryAccessibilityText.deselectsItem
                : GalleryAccessibilityText.selectsItem
        }

        return hasTapAction ? GalleryAccessibilityText.opensItem : nil
    }

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(selectionIndicatorFill)

            Circle()
                .stroke(Color.white, lineWidth: Metrics.borderWidth)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(
            width: Metrics.selectionBadgeSize,
            height: Metrics.selectionBadgeSize
        )
        .padding(Metrics.selectionBadgePadding)
    }
}

private struct GalleryAccessibilityValueModifier: ViewModifier {
    let accessibilityValue: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let accessibilityValue {
            content.accessibilityValue(Text(accessibilityValue))
        } else {
            content
        }
    }
}

private struct GalleryAccessibilityHintModifier: ViewModifier {
    let accessibilityHint: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let accessibilityHint {
            content.accessibilityHint(Text(accessibilityHint))
        } else {
            content
        }
    }
}
