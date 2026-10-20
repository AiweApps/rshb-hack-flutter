import CoreGraphics
import SharedLogic

/// Maps between frame pixels (what the service speaks) and the screen box the photo is
/// letterboxed into. Pure layout arithmetic.
struct PhotoGeometry {
    let box: CGSize
    let frame: CGSize
    let scale: CGFloat
    let origin: CGPoint

    init(box: CGSize, frame: CGSize) {
        self.box = box
        self.frame = frame
        let fit = min(box.width / frame.width, box.height / frame.height)
        self.scale = fit
        self.origin = CGPoint(x: (box.width - frame.width * fit) / 2, y: (box.height - frame.height * fit) / 2)
    }

    func toScreen(_ point: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + point.x * scale, y: origin.y + point.y * scale)
    }

    func toScreenRect(_ box: BottleBox) -> CGRect {
        let a = toScreen(CGPoint(x: box.x1, y: box.y1))
        let b = toScreen(CGPoint(x: box.x2, y: box.y2))
        return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y))
    }

    /// A screen point in frame pixels, clamped to the photo.
    func toFrame(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max((point.x - origin.x) / scale, 0), frame.width),
            y: min(max((point.y - origin.y) / scale, 0), frame.height)
        )
    }
}

/// A box in frame pixels, as plain numbers for gesture arithmetic.
struct FrameRect: Equatable {
    var x1: CGFloat
    var y1: CGFloat
    var x2: CGFloat
    var y2: CGFloat

    init(_ box: BottleBox) {
        x1 = CGFloat(box.x1)
        y1 = CGFloat(box.y1)
        x2 = CGFloat(box.x2)
        y2 = CGFloat(box.y2)
    }

    init(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    }

    init(from a: CGPoint, to b: CGPoint) {
        self.init(x1: min(a.x, b.x), y1: min(a.y, b.y), x2: max(a.x, b.x), y2: max(a.y, b.y))
    }

    var width: CGFloat { x2 - x1 }
    var height: CGFloat { y2 - y1 }

    /// The frame lies on an edge of the photo of the given size.
    func touchesEdge(of size: CGSize) -> Bool {
        x1 <= 0 || y1 <= 0 || x2 >= size.width || y2 >= size.height
    }

    var bottleBox: BottleBox {
        BottleBox(x1: Double(x1), y1: Double(y1), x2: Double(x2), y2: Double(y2))
    }
}
