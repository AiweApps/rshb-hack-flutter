import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Native presentation of the scanner's single-photo picker. The shared component still
/// owns the request; the UUID only rejects callbacks from a dismissed presentation.
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let requestID: UUID?
    let onFinish: (UUID, NSItemProvider?) -> Void

    func makeUIViewController(context: Context) -> HostController {
        let host = HostController()
        context.coordinator.host = host
        host.onAppear = { [weak coordinator = context.coordinator] in coordinator?.presentIfNeeded() }
        return host
    }

    func updateUIViewController(_ controller: HostController, context: Context) {
        context.coordinator.update(requestID: requestID, onFinish: onFinish)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    static func dismantleUIViewController(_ controller: HostController, coordinator: Coordinator) {
        coordinator.invalidate()
    }

    final class HostController: UIViewController {
        var onAppear: (() -> Void)?

        override func loadView() {
            view = UIView()
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onAppear?()
        }
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        weak var host: HostController?
        private var requestedID: UUID?
        private var activeID: UUID?
        private var picker: PHPickerViewController?
        private var reported = false
        private var isDismissing = false
        private var onFinish: ((UUID, NSItemProvider?) -> Void)?

        func update(requestID: UUID?, onFinish: @escaping (UUID, NSItemProvider?) -> Void) {
            requestedID = requestID
            self.onFinish = onFinish
            if let picker, activeID != requestID { dismiss(picker) }
            presentIfNeeded()
        }

        func presentIfNeeded() {
            guard picker == nil, let requestedID, let host,
                  host.viewIfLoaded?.window != nil, host.presentedViewController == nil else { return }
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 1
            configuration.preferredAssetRepresentationMode = .current
            let picker = PHPickerViewController(configuration: configuration)
            picker.modalPresentationStyle = .pageSheet
            picker.delegate = self
            self.picker = picker
            activeID = requestedID
            reported = false
            host.present(picker, animated: true)
            picker.presentationController?.delegate = self
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard self.picker === picker else { return }
            report(results.first?.itemProvider)
            dismiss(picker)
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            guard let picker, presentationController.presentedViewController === picker else { return }
            report(nil)
            clear(picker)
        }

        func invalidate() {
            requestedID = nil
            onFinish = nil
            host?.onAppear = nil
            if let picker { dismiss(picker, animated: false) }
        }

        private func report(_ provider: NSItemProvider?) {
            guard !reported, let activeID, activeID == requestedID else { return }
            reported = true
            requestedID = nil
            onFinish?(activeID, provider)
        }

        private func dismiss(_ picker: PHPickerViewController, animated: Bool = true) {
            guard !isDismissing else { return }
            isDismissing = true
            picker.dismiss(animated: animated) { [weak self, weak picker] in
                guard let self, let picker else { return }
                self.clear(picker)
            }
        }

        private func clear(_ picker: PHPickerViewController) {
            guard self.picker === picker else { return }
            self.picker = nil
            activeID = nil
            isDismissing = false
            presentIfNeeded()
        }
    }
}

/// Item-provider work can outlive the picker (for example an iCloud download). Cancellation
/// resumes the waiter once, cancels that download and ignores any later provider callback.
final class PhotoLibraryImageRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Data?, Never>?
    private var progress: Progress?
    private var finished = false

    func load(from provider: NSItemProvider) async -> Data? {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                lock.lock()
                if finished {
                    lock.unlock()
                    continuation.resume(returning: nil)
                    return
                }
                self.continuation = continuation
                lock.unlock()
                let progress = provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [self] data, _ in
                    finish(data)
                }
                lock.lock()
                let shouldCancel = finished
                if !shouldCancel { self.progress = progress }
                lock.unlock()
                if shouldCancel { progress.cancel() }
            }
        } onCancel: {
            self.cancel()
        }
    }

    private func cancel() {
        lock.lock()
        let progress = self.progress
        lock.unlock()
        finish(nil)
        progress?.cancel()
    }

    private func finish(_ data: Data?) {
        lock.lock()
        guard !finished else { lock.unlock(); return }
        finished = true
        let continuation = self.continuation
        self.continuation = nil
        progress = nil
        lock.unlock()
        continuation?.resume(returning: data)
    }
}
