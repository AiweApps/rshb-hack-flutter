import SwiftUI
import SharedLogic

struct AssistantAttachmentView: View {
    let photo: AssistantPhoto
    let onOpen: () -> Void
    let onRemove: () -> Void

    var body: some View {
        Button(action: onOpen) {
            LocalPhotoView(path: photo.path, maxPixel: 240) {
                Rectangle().fill(AppTheme.paper2)
            }
            .frame(width: 64, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "assistant_view_photo"))
        .overlay(alignment: .topTrailing) {
            Button(action: onRemove) {
                AppIcon(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.onWine)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.ink, in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "assistant_remove_photo"))
            .offset(x: 12, y: -10)
        }
        .padding(.trailing, 8)
    }
}

/// Local-only photo viewer. The app never uploads a photo just because this view opens.
struct AssistantPhotoViewer: View {
    let photo: AssistantPhoto
    let index: Int
    let count: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onClose: () -> Void
    @State private var image: UIImage?
    @State private var loadedPath: String?
    @State private var zoom = ZoomState()

    var body: some View {
        ZStack {
            AppTheme.scrim.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: onClose) {
                        AppIcon(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.onPhoto)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(String(localized: "common_close"))
                    Spacer()
                    if count > 1 {
                        Text("\(index + 1) / \(count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.onPhoto)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 12)
                GeometryReader { geometry in
                    ZStack {
                        if loadedPath == photo.path {
                            if let image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .zoomed(zoom)
                                    .accessibilityLabel(String(localized: "assistant_photo"))
                            } else {
                                Text(String(localized: "scan_error_photo_open"))
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.onPhoto)
                                    .multilineTextAlignment(.center)
                                    .padding(24)
                            }
                        } else {
                            ProgressView().tint(AppTheme.onPhoto)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .zoomGestures($zoom, size: geometry.size)
                    .clipped()
                }
                if count > 1 {
                    HStack {
                        viewerArrow("chevron.left", disabled: index == 0, action: onPrevious)
                        Spacer()
                        viewerArrow("chevron.right", disabled: index == count - 1, action: onNext)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .task(id: photo.path) {
            image = nil
            loadedPath = nil
            zoom.reset()
            let loaded = await LocalPhotoLoader.image(path: photo.path, maxPixel: nil)
            guard !Task.isCancelled else { return }
            image = loaded
            loadedPath = photo.path
        }
    }

    private func viewerArrow(_ symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AppIcon(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.onPhoto)
                .frame(width: 44, height: 44)
                .background(AppTheme.onPhoto.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.3 : 1)
        .accessibilityLabel(String(localized: symbol == "chevron.left" ? "assistant_previous_photo" : "assistant_next_photo"))
    }
}
