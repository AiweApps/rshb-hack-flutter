import SwiftUI
import ImageIO
import UIKit

/// Loads photos the app keeps on the device (history, the scan being shown), off the main
/// thread and through an in-memory cache. Thumbnails are decoded at the size they are shown
/// at, so a long history never holds full-size bitmaps.
enum LocalPhotoLoader {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 60
        return cache
    }()

    static func image(path: String, maxPixel: CGFloat?) async -> UIImage? {
        let key = "\(path)#\(Int(maxPixel ?? 0))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let loaded = await Task.detached(priority: .userInitiated) {
            let image = decode(path: path, maxPixel: maxPixel)
            ImageLoadDiagnostics.record("local", source: path,
                detail: image == nil ? "decode_failed; exists=\(FileManager.default.fileExists(atPath: path))" : "loaded")
            return image
        }.value
        if let loaded {
            cache.setObject(loaded, forKey: key)
        }
        return loaded
    }

    private static func decode(path: String, maxPixel: CGFloat?) -> UIImage? {
        guard let maxPixel else {
            return UIImage(contentsOfFile: path)
        }
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: thumbnail)
    }
}

/// A photo from a file path, filled into its frame. Shows `placeholder` until it is ready
/// or when the file cannot be read.
struct LocalPhotoView<Placeholder: View>: View {
    let path: String
    var maxPixel: CGFloat?
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: path) {
            image = await LocalPhotoLoader.image(path: path, maxPixel: maxPixel)
        }
    }
}
