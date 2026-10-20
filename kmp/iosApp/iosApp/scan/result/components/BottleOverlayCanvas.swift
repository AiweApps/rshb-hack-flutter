import SwiftUI
import SharedLogic

/// Draws over the photo on the frame screen: the answer's bottle boxes, faintly and only for
/// orientation; and the frame being drawn, with the photo dimmed outside it and round
/// handles on its corners.
struct BottleOverlayCanvas: View {
    let geometry: PhotoGeometry
    let view: RecognitionView?
    let draft: FrameRect?

    private static let handleRadius: CGFloat = 8
    private static let dimOpacity = 0.55
    private static let hintOpacity = 0.5

    var body: some View {
        Canvas { context, _ in
            if let draft {
                dimOutside(in: &context, rect: geometry.toScreenRect(draft.bottleBox))
            }
            if let view {
                let showBadges = view.bottles.count > 1 || view.isExplicitRoi
                for bottle in view.bottles {
                    guard let box = bottle.geometryBox else { continue }
                    drawBottle(in: &context, rect: geometry.toScreenRect(box), number: bottle.number, showBadge: showBadges)
                }
            }
            if let draft {
                drawDraft(in: &context, rect: geometry.toScreenRect(draft.bottleBox))
            }
        }
        .accessibilityHidden(true)
    }

    /// The photo darkened everywhere but inside the frame.
    private func dimOutside(in context: inout GraphicsContext, rect: CGRect) {
        let photo = CGRect(
            x: geometry.origin.x,
            y: geometry.origin.y,
            width: geometry.frame.width * geometry.scale,
            height: geometry.frame.height * geometry.scale
        )
        var path = Path(photo)
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 6, height: 6))
        context.fill(path, with: .color(AppTheme.scrim.opacity(Self.dimOpacity)), style: FillStyle(eoFill: true))
    }

    private func drawBottle(in context: inout GraphicsContext, rect: CGRect, number: Int32, showBadge: Bool) {
        let shape = Path(roundedRect: rect, cornerRadius: 8)
        context.stroke(shape, with: .color(AppTheme.scrim.opacity(0.25)), lineWidth: 3)
        context.stroke(shape, with: .color(AppTheme.onPhoto.opacity(Self.hintOpacity)), lineWidth: 1.5)
        guard showBadge else { return }
        let center = CGPoint(x: rect.minX + 14, y: rect.minY + 14)
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - 11, y: center.y - 11, width: 22, height: 22)),
            with: .color(AppTheme.wine.opacity(0.75))
        )
        context.draw(
            Text("\(number)").font(.caption2.bold()).foregroundColor(AppTheme.onWine),
            at: center
        )
    }

    private func drawDraft(in context: inout GraphicsContext, rect: CGRect) {
        let outline = Path(roundedRect: rect, cornerRadius: 6)
        context.stroke(outline, with: .color(AppTheme.scrim.opacity(0.4)), lineWidth: 5)
        context.stroke(outline, with: .color(AppTheme.gold), lineWidth: 2.5)
        let radius = Self.handleRadius
        for corner in DraftDrag.Corner.allCases {
            let point = corner.point(of: rect)
            let dot = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: dot.insetBy(dx: -2, dy: -2)), with: .color(AppTheme.scrim.opacity(0.4)))
            context.fill(Path(ellipseIn: dot), with: .color(AppTheme.gold))
            context.stroke(Path(ellipseIn: dot), with: .color(AppTheme.onPhoto), lineWidth: 2)
        }
    }
}
