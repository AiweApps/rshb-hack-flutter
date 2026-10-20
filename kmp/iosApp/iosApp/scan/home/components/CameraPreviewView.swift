import AVFoundation
import SwiftUI

/// The live viewfinder: an `AVCaptureVideoPreviewLayer` filling its frame. A tap reports where
/// it landed, both in the view (for the focus square) and in the camera's own coordinates
/// (for focus and exposure).
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let onTap: (_ viewPoint: CGPoint, _ devicePoint: CGPoint) -> Void

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        let tap = UITapGestureRecognizer(target: view, action: #selector(PreviewUIView.handleTap(_:)))
        view.addGestureRecognizer(tap)
        view.onTap = onTap
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.onTap = onTap
    }

    final class PreviewUIView: UIView {
        var onTap: ((CGPoint, CGPoint) -> Void)?

        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            let point = recognizer.location(in: self)
            onTap?(point, previewLayer.captureDevicePointConverted(fromLayerPoint: point))
        }
    }
}
