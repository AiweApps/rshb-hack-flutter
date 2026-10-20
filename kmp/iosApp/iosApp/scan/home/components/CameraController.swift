import AVFoundation
import Foundation

/// Owns the capture session. Platform plumbing only: whether the camera should run, and what
/// to do with a photo, is decided by `ScanHomeComponent`; this reports how it went.
///
/// Everything that touches the session or the device — configuring, starting, stopping,
/// focusing, capturing — runs on one serial queue, never on the main thread: `startRunning`
/// and `lockForConfiguration` block, and a blocked main thread is a frozen UI.
final class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()

    /// Whether the back camera has a flash to fire; the flash button is off without one.
    @Published private(set) var hasFlash = false

    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "winescan.camera.session")
    private var device: AVCaptureDevice?
    private var isConfigured = false
    private var pendingCapture: (id: Int64, continuation: CheckedContinuation<Data?, Never>)?
    private var subjectAreaObserver: NSObjectProtocol?

    /// Configures the session on first use and starts it. `false` means the device has no
    /// usable back camera.
    func start() async -> Bool {
        guard !Task.isCancelled else { return false }
        return await withCheckedContinuation { continuation in
            queue.async { [self] in
                guard configureIfNeeded() else {
                    continuation.resume(returning: false)
                    return
                }
                if !session.isRunning {
                    useContinuousAutofocus()
                    session.startRunning()
                }
                let flash = device?.hasFlash == true && output.supportedFlashModes.contains(.on)
                DispatchQueue.main.async { [weak self] in self?.hasFlash = flash }
                continuation.resume(returning: true)
            }
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning {
                session.stopRunning()
            }
            // A capture that never finishes would block every later one.
            pendingCapture?.continuation.resume(returning: nil)
            pendingCapture = nil
        }
    }

    /// Focuses and meters exposure at a point given in the device's own coordinates (from
    /// `captureDevicePointConverted`). Once the scene changes, the camera goes back to
    /// continuous autofocus on its own.
    func focus(atDevicePoint point: CGPoint) {
        queue.async { [self] in
            guard let device else { return }
            do {
                try device.lockForConfiguration()
            } catch {
                return
            }
            defer { device.unlockForConfiguration() }
            if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposurePointOfInterest = point
                device.exposureMode = .continuousAutoExposure
            }
            device.isSubjectAreaChangeMonitoringEnabled = true
        }
    }

    /// Takes one photo; `nil` when the capture fails.
    func capture(flashOn: Bool) async -> Data? {
        guard !Task.isCancelled else { return nil }
        return await withCheckedContinuation { continuation in
            queue.async { [self] in
                guard session.isRunning, pendingCapture == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                let settings = AVCapturePhotoSettings()
                pendingCapture = (settings.uniqueID, continuation)
                let wanted: AVCaptureDevice.FlashMode = flashOn ? .on : .off
                if output.supportedFlashModes.contains(wanted) {
                    settings.flashMode = wanted
                }
                output.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let data = error == nil ? photo.fileDataRepresentation() : nil
        queue.async { [self] in
            // A stopped capture can finish after a later capture has started.
            guard pendingCapture?.id == photo.resolvedSettings.uniqueID else { return }
            pendingCapture?.continuation.resume(returning: data)
            pendingCapture = nil
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        guard error != nil else { return }
        queue.async { [self] in
            guard pendingCapture?.id == resolvedSettings.uniqueID else { return }
            pendingCapture?.continuation.resume(returning: nil)
            pendingCapture = nil
        }
    }

    /// Runs on `queue`.
    private func configureIfNeeded() -> Bool {
        if isConfigured { return true }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return false
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        guard session.canAddInput(input), session.canAddOutput(output) else {
            return false
        }
        session.addInput(input)
        session.addOutput(output)
        self.device = device
        isConfigured = true
        useContinuousAutofocus()
        observeSubjectArea(of: device)
        return true
    }

    /// The default state of the lens: it keeps refocusing and metering on its own.
    /// Runs on `queue`.
    private func useContinuousAutofocus() {
        guard let device else { return }
        do {
            try device.lockForConfiguration()
        } catch {
            return
        }
        defer { device.unlockForConfiguration() }
        let center = CGPoint(x: 0.5, y: 0.5)
        if device.isFocusModeSupported(.continuousAutoFocus) {
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = center
            }
            device.focusMode = .continuousAutoFocus
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = center
            }
            device.exposureMode = .continuousAutoExposure
        }
        device.isSubjectAreaChangeMonitoringEnabled = false
    }

    private func observeSubjectArea(of device: AVCaptureDevice) {
        subjectAreaObserver = NotificationCenter.default.addObserver(
            forName: AVCaptureDevice.subjectAreaDidChangeNotification,
            object: device,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            queue.async { self.useContinuousAutofocus() }
        }
    }

    deinit {
        if let subjectAreaObserver {
            NotificationCenter.default.removeObserver(subjectAreaObserver)
        }
    }
}
