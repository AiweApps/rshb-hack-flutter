import CoreGraphics

/// What a drag on the photo does to the frame: draws a new one, moves it, or resizes it by a
/// corner. Decided once, where the finger lands.
enum DraftDrag {
    case draw(start: CGPoint)
    case move(from: CGPoint, box: FrameRect)
    case resize(corner: Corner, from: CGPoint, box: FrameRect)

    enum Corner: CaseIterable {
        case northWest, northEast, southWest, southEast

        var isWest: Bool { self == .northWest || self == .southWest }
        var isNorth: Bool { self == .northWest || self == .northEast }

        func point(of rect: CGRect) -> CGPoint {
            CGPoint(x: isWest ? rect.minX : rect.maxX, y: isNorth ? rect.minY : rect.maxY)
        }
    }

    private static let handleRadius: CGFloat = 26

    /// `touch` is in screen points; `draft` is the current frame, if any.
    static func begin(touch: CGPoint, draft: FrameRect?, geometry: PhotoGeometry) -> DraftDrag {
        let framePoint = geometry.toFrame(touch)
        guard let draft else { return .draw(start: framePoint) }
        let rect = geometry.toScreenRect(draft.bottleBox)
        for corner in Corner.allCases {
            let handle = corner.point(of: rect)
            if hypot(handle.x - touch.x, handle.y - touch.y) <= handleRadius {
                return .resize(corner: corner, from: framePoint, box: draft)
            }
        }
        if rect.contains(touch) {
            return .move(from: framePoint, box: draft)
        }
        return .draw(start: framePoint)
    }

    /// The frame while the finger is at `touch`.
    func frame(at touch: CGPoint, geometry: PhotoGeometry, minSide: CGFloat) -> FrameRect {
        let point = geometry.toFrame(touch)
        switch self {
        case .draw(let start):
            return FrameRect(from: start, to: point)
        case .move(let from, let box):
            let dx = point.x - from.x
            let dy = point.y - from.y
            let x1 = min(max(box.x1 + dx, 0), geometry.frame.width - box.width)
            let y1 = min(max(box.y1 + dy, 0), geometry.frame.height - box.height)
            return FrameRect(x1: x1, y1: y1, x2: x1 + box.width, y2: y1 + box.height)
        case .resize(let corner, let from, let box):
            let dx = point.x - from.x
            let dy = point.y - from.y
            var result = box
            if corner.isWest {
                result.x1 = min(max(box.x1 + dx, 0), box.x2 - minSide)
            } else {
                result.x2 = min(max(box.x2 + dx, box.x1 + minSide), geometry.frame.width)
            }
            if corner.isNorth {
                result.y1 = min(max(box.y1 + dy, 0), box.y2 - minSide)
            } else {
                result.y2 = min(max(box.y2 + dy, box.y1 + minSide), geometry.frame.height)
            }
            return result
        }
    }

    var isDraw: Bool {
        if case .draw = self { return true }
        return false
    }
}
