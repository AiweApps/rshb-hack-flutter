import AVFoundation
import SharedLogic

/// Maps the system camera permission and the device to what the component is told.
enum CameraAccess {

    /// The system already has an answer: it was asked before, or there is no camera to ask for.
    static var isDecided: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) != .notDetermined || !hasCamera
    }

    /// Asks for permission when it was never asked, then starts the session.
    static func resolve(camera: CameraController) async -> CameraAvailability {
        let permission = await requestPermission()
        guard permission == .ready else { return permission }
        return await camera.start() ? .ready : .unavailable
    }

    /// The permission alone: shows the system prompt when needed, never starts a session.
    static func requestPermission() async -> CameraAvailability {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .ready
        case .notDetermined:
            // iOS asks only once: after a refusal only Settings can grant it, so no «Allow» step.
            return await AVCaptureDevice.requestAccess(for: .video) ? .ready : .permanentlyDenied
        case .denied, .restricted:
            return .permanentlyDenied
        @unknown default:
            return .unavailable
        }
    }

    private static var hasCamera: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }
}
