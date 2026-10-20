import SwiftUI

/// Corner brackets around the bottle with a thin line sweeping top to bottom: «the scanner
/// is ready to read a label». About 36 x 44 pt, so it sits inside the 64 pt disc without
/// touching its edge. Appears with a scale-and-fade spring and leaves the same way.
struct ScannerFrame: View {
    let isActive: Bool

    var body: some View {
        // A paused timeline keeps its last frame, which is what the fade-out needs.
        TimelineView(.animation(paused: !isActive)) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .frame(width: Metrics.size.width, height: Metrics.size.height)
        .scaleEffect(isActive ? 1 : Metrics.enterScale)
        .animation(.spring(duration: 0.5, bounce: 0.3), value: isActive)
        .opacity(isActive ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: isActive)
        .environment(\.colorScheme, .light)
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let k = size.width / 44
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }

        var brackets = Path()
        brackets.move(to: point(2, 12))
        brackets.addLine(to: point(2, 4))
        brackets.addQuadCurve(to: point(4, 2), control: point(2, 2))
        brackets.addLine(to: point(12, 2))
        brackets.move(to: point(32, 2))
        brackets.addLine(to: point(40, 2))
        brackets.addQuadCurve(to: point(42, 4), control: point(42, 2))
        brackets.addLine(to: point(42, 12))
        brackets.move(to: point(42, 42))
        brackets.addLine(to: point(42, 50))
        brackets.addQuadCurve(to: point(40, 52), control: point(42, 52))
        brackets.addLine(to: point(32, 52))
        brackets.move(to: point(12, 52))
        brackets.addLine(to: point(4, 52))
        brackets.addQuadCurve(to: point(2, 50), control: point(2, 52))
        brackets.addLine(to: point(2, 42))
        context.stroke(
            brackets,
            with: .color(AppTheme.gold),
            style: StrokeStyle(lineWidth: 2.4 * k, lineCap: .round, lineJoin: .round)
        )

        let sweep = Self.sweep(at: time)
        let line = CGRect(x: 5 * k, y: sweep.y * k, width: 34 * k, height: 2 * k)
        context.fill(
            Path(roundedRect: line, cornerRadius: k),
            with: .color(AppTheme.gold.opacity(sweep.opacity))
        )
    }

    /// One 2.4 s pass: the line travels down while it fades in, fades out, and returns unseen.
    private static func sweep(at time: TimeInterval) -> (y: Double, opacity: Double) {
        let u = time.truncatingRemainder(dividingBy: 2.4) / 2.4
        let y = u < 0.5
            ? LiquidMotion.lerp(8, 44, LiquidMotion.ease(u / 0.5))
            : LiquidMotion.lerp(44, 8, LiquidMotion.ease((u - 0.5) / 0.5))
        let opacity: Double
        if u < 0.15 {
            opacity = 0.85 * LiquidMotion.ease(u / 0.15)
        } else if u < 0.5 {
            opacity = 0.85
        } else if u < 0.65 {
            opacity = 0.85 * (1 - LiquidMotion.ease((u - 0.5) / 0.15))
        } else {
            opacity = 0
        }
        return (y, opacity)
    }

    private enum Metrics {
        static let size = CGSize(width: 36, height: 44)
        static let enterScale: CGFloat = 1.35
    }
}
