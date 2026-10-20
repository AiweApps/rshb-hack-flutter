import UIKit
import SharedLogic

/// Turns whatever the camera or the picker produced into the JPEG the service expects: no
/// larger than `ScanLimits.UPLOAD_MAX_SIDE` on a side, and **upright in its pixels** — the
/// EXIF rotation is baked in, so the frames the service answers with refer to the picture
/// as the user saw it. HEIC becomes JPEG on the way.
///
/// Returns `nil` when the image cannot be decoded; the caller reports it as a failed
/// capture or pick.
enum PhotoPreparer {

    static func prepare(data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        return prepare(image: image)
    }

    static func prepare(image: UIImage) -> String? {
        let maxSide = CGFloat(ScanLimits.shared.UPLOAD_MAX_SIDE)
        let quality = CGFloat(ScanLimits.shared.UPLOAD_JPEG_QUALITY) / 100

        // `size` is already orientation-aware; drawing through UIGraphicsImageRenderer
        // applies the orientation to the pixels and drops the EXIF tag.
        let longer = max(image.size.width, image.size.height)
        let scale = longer > maxSide ? maxSide / longer : 1
        let target = CGSize(
            width: max(1, (image.size.width * scale).rounded(.down)),
            height: max(1, (image.size.height * scale).rounded(.down))
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let upright = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let jpeg = upright.jpegData(compressionQuality: quality) else { return nil }

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("prepared", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(Int(Date().timeIntervalSince1970 * 1000)).jpg")
        do {
            try jpeg.write(to: url, options: .atomic)
        } catch {
            return nil
        }
        return url.path
    }
}
