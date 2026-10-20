import SwiftUI
import SharedLogic

/// Reference photos live behind the guest Bearer token, which `AsyncImage` cannot send. The
/// request carries the header from `ReferenceAccess`; decoded images are kept in memory.
enum AuthorizedImageLoader {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 80
        return cache
    }()

    static func image(url: String, access: ReferenceAccess?) async -> UIImage? {
        let key = url as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let address = URL(string: url) else {
            ImageLoadDiagnostics.record("reference", source: url, detail: "invalid_url")
            return nil
        }
        if address.isFileURL {
            let allowed = Bundle.main.bundleURL.appendingPathComponent("LocalScannerAssets/api/reference").standardizedFileURL.path + "/"
            let installed = LocalScannerAssetStore.storageDirectory.standardizedFileURL.path + "/"
            let path = address.standardizedFileURL.path
            let permitted = path.hasPrefix(allowed) || (path.hasPrefix(installed) && path.contains("/api/reference/") && address.pathExtension == "jpg")
            guard permitted,
                  let image = UIImage(contentsOfFile: address.path) else {
                ImageLoadDiagnostics.record("reference", source: url, detail: "file_failed; allowed=\(permitted); exists=\(FileManager.default.fileExists(atPath: address.path))")
                return nil
            }
            ImageLoadDiagnostics.record("reference", source: url, detail: "file_loaded")
            cache.setObject(image, forKey: key)
            return image
        }
        var request = URLRequest(url: address)
        if let access {
            request.setValue(access.authorizationHeader, forHTTPHeaderField: ReferenceAccess.companion.AUTHORIZATION_HEADER)
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200, let image = UIImage(data: data) else {
                ImageLoadDiagnostics.record("reference", source: url, detail: "http=\(status); bytes=\(data.count)")
                return nil
            }
            ImageLoadDiagnostics.record("reference", source: url, detail: "http_loaded")
            cache.setObject(image, forKey: key)
            return image
        } catch {
            ImageLoadDiagnostics.record("reference", source: url, detail: "network_error=\((error as NSError).code)")
            return nil
        }
    }
}

struct AuthorizedAsyncImage<Placeholder: View, Failure: View>: View {
    let url: String?
    let access: ReferenceAccess?
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> Failure

    private enum Phase {
        case loading
        case loaded(UIImage)
        case failed
    }

    @State private var phase = Phase.loading

    // The URL alone is stable when guest credentials arrive or refresh after a failed request.
    private struct RequestIdentity: Equatable {
        let url: String?
        let baseURL: String?
        let token: String?
    }

    var body: some View {
        ZStack {
            switch phase {
            case .loading:
                placeholder()
            case .loaded(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            case .failed:
                failure()
            }
        }
        .task(id: RequestIdentity(url: url, baseURL: access?.baseUrl, token: access?.token)) {
            guard let url, !url.isEmpty else {
                phase = .failed
                return
            }
            phase = .loading
            if let image = await AuthorizedImageLoader.image(url: url, access: access) {
                guard !Task.isCancelled else { return }
                phase = .loaded(image)
            } else {
                guard !Task.isCancelled else { return }
                phase = .failed
            }
        }
    }
}
