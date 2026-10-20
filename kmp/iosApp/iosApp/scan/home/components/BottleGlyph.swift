import SwiftUI

/// The wine bottle on the shutter, in the 30 x 52 unit box of the design drawn at 0.6 scale
/// (18 x 31.2 pt). The wine inside is a clipped wave whose level depends on `look`: full and
/// calm when the service is ready, sloshing while we connect, filling up in a loop while
/// there is a queue, empty when a shot would get no answer. A shot tips the bottle over.
///
/// The disc under it is white in both schemes, so the glyph pins itself to the light palette.
struct BottleGlyph: View {
    let look: ShutterLook
    /// Bumped on every shot: the bottle tilts and rights itself.
    let pourTrigger: Int

    @Environment(\.self) private var environment
    @State private var previousLook: ShutterLook
    @State private var changedAt: TimeInterval = -.infinity

    init(look: ShutterLook, pourTrigger: Int) {
        self.look = look
        self.pourTrigger = pourTrigger
        _previousLook = State(initialValue: look)
    }

    var body: some View {
        ZStack {
            liquid
            BottleShape()
                .stroke(
                    look.isRefusing ? AppTheme.muted : AppTheme.wine,
                    style: StrokeStyle(lineWidth: Metrics.strokeWidth, lineJoin: .round)
                )
            label
        }
        .frame(width: Metrics.size.width, height: Metrics.size.height)
        .animation(.easeInOut(duration: Metrics.colourDuration), value: look)
        .keyframeAnimator(initialValue: 0.0, trigger: pourTrigger) { content, angle in
            content.rotationEffect(.degrees(angle), anchor: Metrics.pourAnchor)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-Metrics.pourAngle, duration: Metrics.pourDown)
                CubicKeyframe(0, duration: Metrics.pourBack)
            }
        }
        .environment(\.colorScheme, .light)
        .onChange(of: look) { old, _ in
            previousLook = old
            changedAt = Date.timeIntervalSinceReferenceDate
        }
        .accessibilityHidden(true)
    }

    // MARK: Parts

    private var liquid: some View {
        // The disc is white in both schemes, so the wine is resolved against the light palette.
        var light = environment
        light.colorScheme = .light
        let wine = AppTheme.wine2.resolve(in: light)
        let busyWine = AppTheme.bottleLiquidBusy.resolve(in: light)
        let size = Metrics.size
        let scale = Metrics.scale
        return TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let progress = LiquidMotion.ease(min(max((now - changedAt) / Metrics.levelDuration, 0), 1))
            let surface = LiquidMotion.lerp(
                LiquidMotion.surface(previousLook, at: now),
                LiquidMotion.surface(look, at: now),
                progress
            )
            let colour = LiquidMotion.mix(
                previousLook == .busy ? busyWine : wine,
                look == .busy ? busyWine : wine,
                progress
            )
            Canvas { context, _ in
                context.clip(to: BottleShape().path(in: CGRect(origin: .zero, size: size)))
                var wave = Path()
                let phase = 2 * Double.pi * now / Metrics.wavePeriod
                let step = 1.0
                var x = -step
                wave.move(to: CGPoint(x: x * scale, y: (surface + Metrics.waveAmplitude * sin(phase + 2 * .pi * x / 30)) * scale))
                while x < 30 + step {
                    x += step
                    let y = surface + Metrics.waveAmplitude * sin(phase + 2 * .pi * x / 30)
                    wave.addLine(to: CGPoint(x: x * scale, y: y * scale))
                }
                wave.addLine(to: CGPoint(x: (30 + step) * scale, y: size.height + 2))
                wave.addLine(to: CGPoint(x: -step * scale, y: size.height + 2))
                wave.closeSubpath()
                context.fill(wave, with: .color(colour))
            }
        }
    }

    private var label: some View {
        RoundedRectangle(cornerRadius: 1.5 * Metrics.scale)
            .fill(AppTheme.bottleLabel.opacity(look.isRefusing ? 0.4 : 0.92))
            .frame(width: 18 * Metrics.scale, height: 11 * Metrics.scale)
            .position(x: 15 * Metrics.scale, y: 33.5 * Metrics.scale)
    }

    // MARK: Metrics

    private enum Metrics {
        static let scale: CGFloat = 0.6
        static let size = CGSize(width: 30 * scale, height: 52 * scale)
        static let strokeWidth: CGFloat = 1.8 * scale
        static let waveAmplitude = 1.5
        static let wavePeriod = 1.8
        static let levelDuration = 0.9
        static let colourDuration = 0.45
        static let pourAngle = 38.0
        static let pourDown = 0.28
        static let pourBack = 0.42
        /// The design tips the bottle about a point a little below its middle.
        static let pourAnchor = UnitPoint(x: 0.5, y: 0.6)
    }
}

/// The bottle outline from the design, in its own 30 x 52 box scaled to the rect.
struct BottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let kx = rect.width / 30
        let ky = rect.height / 52
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * kx, y: rect.minY + y * ky)
        }
        var path = Path()
        path.move(to: point(11, 1))
        path.addLine(to: point(19, 1))
        path.addLine(to: point(19, 12))
        path.addCurve(to: point(26, 25), control1: point(19, 15), control2: point(26, 18))
        path.addLine(to: point(26, 47))
        path.addQuadCurve(to: point(22, 51), control: point(26, 51))
        path.addLine(to: point(8, 51))
        path.addQuadCurve(to: point(4, 47), control: point(4, 51))
        path.addLine(to: point(4, 25))
        path.addCurve(to: point(11, 12), control1: point(4, 18), control2: point(11, 15))
        path.closeSubpath()
        return path
    }
}

/// Where the wine surface is, in bottle units (the bottle spans y = 1...51), at a moment.
enum LiquidMotion {
    private static let full = 16.0
    private static let empty = 60.0

    static func surface(_ look: ShutterLook, at time: TimeInterval) -> Double {
        switch look {
        case .ready:
            return full
        case .checking:
            // Sloshes between two low levels, 1.6 s a swing.
            return 35 + 5 * cos(2 * .pi * time / 1.6)
        case .busy:
            // Fills up, holds, then drains fast to start over: 3.2 s a loop.
            let u = time.truncatingRemainder(dividingBy: 3.2) / 3.2
            if u < 0.78 { return lerp(48, 20, ease(u / 0.78)) }
            if u < 0.92 { return 20 }
            let drain = (u - 0.92) / 0.08
            return lerp(20, 48, drain * drain)
        case .blocked, .offline:
            return empty
        }
    }

    static func ease(_ x: Double) -> Double { x * x * (3 - 2 * x) }

    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    static func mix(_ a: Color.Resolved, _ b: Color.Resolved, _ t: Double) -> Color {
        let f = Float(t)
        return Color(Color.Resolved(
            red: a.red + (b.red - a.red) * f,
            green: a.green + (b.green - a.green) * f,
            blue: a.blue + (b.blue - a.blue) * f,
            opacity: a.opacity + (b.opacity - a.opacity) * f
        ))
    }
}
