import SwiftUI
import SharedLogic

/// A wine's picture: the bottle cut out of the user's photo when a photo and a box are given,
/// the whole photo when only the path is, and the catalogue reference otherwise.
struct WinePhotoView: View {
    let referencePath: String?
    let photoPath: String?
    var crop: BottleBox?
    var frame: [KotlinInt]?
    let referenceAccess: ReferenceAccess?
    /// Fit keeps a tall bottle crop whole; fill suits a thumbnail of a full photo.
    var fit = true

    init(card: WineCard, photoPath: String?, crop: BottleBox? = nil, frame: [KotlinInt]? = nil,
         referenceAccess: ReferenceAccess?, fit: Bool = true) {
        self.init(reference: card.reference, photoPath: photoPath, crop: crop, frame: frame,
                  referenceAccess: referenceAccess, fit: fit)
    }

    init(reference: String?, photoPath: String?, crop: BottleBox? = nil, frame: [KotlinInt]? = nil,
         referenceAccess: ReferenceAccess?, fit: Bool = true) {
        referencePath = reference
        self.photoPath = photoPath
        self.crop = crop
        self.frame = frame
        self.referenceAccess = referenceAccess
        self.fit = fit
    }

    @State private var cropped: UIImage?
    @State private var isFailed = false

    var body: some View {
        ZStack {
            if let photoPath, !isFailed {
                userPhoto(path: photoPath)
            } else {
                reference
            }
        }
        .task(id: "\(photoPath ?? "")#\(String(describing: crop))#\(String(describing: frame))") { await loadCrop() }
    }

    @ViewBuilder
    private func userPhoto(path: String) -> some View {
        if crop == nil {
            LocalPhotoView(path: path, maxPixel: 600) { ProgressView() }
        } else if let cropped {
            if fit {
                Image(uiImage: cropped).resizable().scaledToFit()
            } else {
                Image(uiImage: cropped).resizable().scaledToFill()
            }
        } else {
            ProgressView()
        }
    }

    private var reference: some View {
        AuthorizedAsyncImage(
            url: referenceAccess?.resolve(reference: referencePath),
            access: referenceAccess
        ) {
            ProgressView()
        } failure: {
            AppIcon(systemName: "photo").foregroundStyle(.tertiary)
        }
    }

    private func loadCrop() async {
        ImageLoadDiagnostics.record("thumbnail_start", source: photoPath ?? referencePath ?? "none", detail: "crop=\(crop != nil)")
        cropped = nil
        isFailed = false
        guard let photoPath, let crop else { return }
        let frame = frame
        guard let image = await LocalPhotoLoader.image(path: photoPath, maxPixel: nil) else {
            guard !Task.isCancelled else { return }
            isFailed = true
            return
        }
        guard !Task.isCancelled else {
            ImageLoadDiagnostics.record("thumbnail_cancelled", source: photoPath, detail: "after_decode")
            return
        }
        let result = await Task.detached { PhotoCrop.crop(image: image, box: crop, frame: frame) }.value
        guard !Task.isCancelled else {
            ImageLoadDiagnostics.record("thumbnail_cancelled", source: photoPath, detail: "after_crop")
            return
        }
        cropped = result
        isFailed = result == nil
        ImageLoadDiagnostics.record("thumbnail_end", source: photoPath, detail: result == nil ? "crop_failed" : "loaded")
    }
}
