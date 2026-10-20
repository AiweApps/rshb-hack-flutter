import UIKit
import SharedLogic

/// iOS side of `PlatformShare`: a `UIActivityViewController`.
///
/// A Swift class implementing a Kotlin interface — Kotlin/Native exposes the interface as an
/// Objective-C protocol, so no Kotlin code is needed for the implementation itself. The
/// class is handed to `doInitKoinIos` at start-up.
final class AppleShare: PlatformShare {

    func share(payload: SharePayload) {
        // The title and the address go in as separate activity items rather than as one
        // formatted string: every target then handles them natively.
        var items: [Any] = [payload.title]
        if let url = payload.url, let address = URL(string: url) {
            items.append(address)
        }
        present(items: items)
    }

    func shareFile(payload: ShareFilePayload) {
        // Written to a temporary file so Files, Mail and AirDrop receive a document with
        // the given name rather than a blob of text.
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(payload.fileName)
        do {
            try payload.content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            return
        }
        present(items: [url])
    }

    private func present(items: [Any]) {
        guard let presenter = Self.topViewController() else { return }

        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // Required on iPad, where an unanchored popover is a runtime crash rather than a
        // layout problem.
        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        presenter.present(controller, animated: true)
    }

    /// Walks down from the key window to whatever is actually on screen. Presenting from the
    /// root controller while a sheet is up would silently do nothing.
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.keyWindow != nil }

        var controller = scene?.keyWindow?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
