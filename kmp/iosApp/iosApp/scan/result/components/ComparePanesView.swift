import SwiftUI
import SharedLogic

/// The big photo block: the bottle cut out of the user's photo next to the catalogue
/// reference. The glass expand button in the corner (and a tap anywhere) opens the reveal
/// comparison.
struct ComparePanesView: View {
    let photoPath: String
    let crop: BottleBox?
    let frame: [KotlinInt]?
    let referenceUrl: String?
    let referenceAccess: ReferenceAccess?
    let onTap: () -> Void

    @State private var cropped: UIImage?
    @State private var isCropFailed = false

    private static let paneHeight: CGFloat = 196

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 1) {
                pane(caption: String(localized: "result_your_photo")) {
                    yourPhoto
                }
                pane(caption: String(localized: "result_reference")) {
                    AuthorizedAsyncImage(url: referenceUrl, access: referenceAccess) {
                        ProgressView()
                    } failure: {
                        missing(String(localized: "result_reference_missing"))
                    }
                    .padding(8)
                }
            }
            .background(AppTheme.rule)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .topTrailing) {
                AppIcon(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.wine)
                    .frame(width: 40, height: 40)
                    .appGlass(in: Circle())
                    .padding(10)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "result_expand_compare"))
        .task(id: "\(photoPath)#\(String(describing: crop))#\(String(describing: frame))") { await loadCrop() }
    }

    @ViewBuilder
    private var yourPhoto: some View {
        if let cropped {
            Image(uiImage: cropped)
                .resizable()
                .scaledToFit()
                .padding(8)
        } else if isCropFailed {
            missing(String(localized: "result_photo_missing"))
        } else {
            ProgressView()
        }
    }

    private func pane<Content: View>(caption: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
                .frame(maxWidth: .infinity)
                .frame(height: Self.paneHeight)
            Text(caption)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.muted)
                .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.paper2)
    }

    private func missing(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppTheme.muted)
            .multilineTextAlignment(.center)
            .padding(8)
    }

    private func loadCrop() async {
        cropped = nil
        isCropFailed = false
        let crop = crop, frame = frame, path = photoPath
        guard let image = await LocalPhotoLoader.image(path: path, maxPixel: crop == nil ? 2000 : nil) else {
            guard !Task.isCancelled else { return }
            isCropFailed = true
            return
        }
        guard !Task.isCancelled else { return }
        let result: UIImage
        if let crop {
            result = await Task.detached { PhotoCrop.crop(image: image, box: crop, frame: frame) ?? image }.value
        } else {
            result = image
        }
        guard !Task.isCancelled else { return }
        cropped = result
    }
}
