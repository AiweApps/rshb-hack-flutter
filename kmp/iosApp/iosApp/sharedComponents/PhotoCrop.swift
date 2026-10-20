import UIKit
import SharedLogic

/// Cuts the bottle the answer is about out of the user's photo. Boxes are in frame pixels
/// (what the service saw); the decoded image may differ in size, so they are scaled first.
enum PhotoCrop {

    static func crop(image: UIImage, box: BottleBox, frame: [KotlinInt]?, paddingFactor: Double? = nil) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        var scaleX: CGFloat = 1
        var scaleY: CGFloat = 1
        if let frame, frame.count == 2, frame[0].intValue > 0, frame[1].intValue > 0 {
            scaleX = width / CGFloat(frame[0].intValue)
            scaleY = height / CGFloat(frame[1].intValue)
        }
        let padding = CGFloat(paddingFactor ?? Double(ScanLimits.shared.CROP_PADDING_FACTOR)) * CGFloat(box.longerSide)
        let left = clamp((CGFloat(box.x1) - padding) * scaleX, upper: width)
        let top = clamp((CGFloat(box.y1) - padding) * scaleY, upper: height)
        let right = clamp((CGFloat(box.x2) + padding) * scaleX, upper: width)
        let bottom = clamp((CGFloat(box.y2) + padding) * scaleY, upper: height)
        let source = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        guard source.width >= 1, source.height >= 1,
              let cropped = cgImage.cropping(to: source) else {
            return nil
        }
        return UIImage(cgImage: cropped)
    }

    private static func clamp(_ value: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, 0), upper)
    }
}
