import SwiftUI
import UIKit

struct PhotosGalleryContentView: View {
    let content: PhotosGalleryContent

    @Environment(\.displayScale) private var displayScale
    @State private var vm: PhotosGalleryContentViewModel

    init(content: PhotosGalleryContent) {
        self.init(
            content: content,
            service: PhotosGalleryThumbnailService.live()
        )
    }

    init(
        content: PhotosGalleryContent,
        service: any PhotosGalleryThumbnailServiceProtocol
    ) {
        self.init(
            content: content,
            vm: PhotosGalleryContentViewModel(service: service)
        )
    }

    init(
        content: PhotosGalleryContent,
        vm: PhotosGalleryContentViewModel
    ) {
        self.content = content
        _vm = State(initialValue: vm)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(uiColor: .systemGray5)

                if let image = vm.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }

                if content.mediaType == .video {
                    Image(systemName: "video.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.black.opacity(0.55), in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(8)
                }
            }
            .clipped()
            .task(id: requestKey(for: proxy.size)) {
                vm.load(
                    content: content,
                    targetSize: targetSize(for: proxy.size)
                )
            }
            .onDisappear {
                vm.cancel()
            }
        }
    }

    private func requestKey(for size: CGSize) -> String {
        let targetSize = targetSize(for: size)
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        guard width > 0, height > 0 else { return "placeholder" }
        return "\(content.id)-\(width)x\(height)"
    }

    private func targetSize(for size: CGSize) -> CGSize {
        CGSize(
            width: (size.width * displayScale).rounded(.up),
            height: (size.height * displayScale).rounded(.up)
        )
    }
}
