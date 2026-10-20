import SwiftUI

/// The 80 pt shutter button. The ring and the bottle inside it carry the service status:
///
/// - ready: a white ring with a soft gold glow breathing around it, a full bottle inside a
///   scanner frame;
/// - checking: a dim ring with a white arc running round it, a bottle sloshing at a low level;
/// - busy: a dim ring with an amber arc, the wine filling up in a loop, a badge with the queue;
/// - blocked / offline: a slowly turning dashed red ring, an empty bottle on a dimmed disc.
///
/// All motion is derived from `look` and the tickets; the timing of the status lives in the
/// shared component.
struct BottleShutter: View {
    let look: ShutterLook
    /// Photos waiting ahead; 0 hides the badge.
    let queueAhead: Int
    /// Bumped on every shot: the bottle is poured.
    let shotCount: Int
    /// Bumped when a press is refused: the shutter wobbles.
    let refusedTicket: Int
    /// The status in words, read out after the label.
    let accessibilityValue: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.clear.frame(width: ShutterMetrics.size, height: ShutterMetrics.size)
        }
        .buttonStyle(
            BottleShutterStyle(
                look: look,
                queueAhead: queueAhead,
                shotCount: shotCount,
                refusedTicket: refusedTicket
            )
        )
        .accessibilityLabel(String(localized: "scan_shutter"))
        .accessibilityValue(accessibilityValue)
    }
}

enum ShutterMetrics {
    static let size: CGFloat = 80
    static let ringWidth: CGFloat = 4
    static let discInset: CGFloat = 8
}

private struct BottleShutterStyle: ButtonStyle {
    let look: ShutterLook
    let queueAhead: Int
    let shotCount: Int
    let refusedTicket: Int

    func makeBody(configuration: Configuration) -> some View {
        BottleShutterFace(
            look: look,
            queueAhead: queueAhead,
            shotCount: shotCount,
            refusedTicket: refusedTicket,
            isPressed: configuration.isPressed
        )
    }
}

private struct BottleShutterFace: View {
    let look: ShutterLook
    let queueAhead: Int
    let shotCount: Int
    let refusedTicket: Int
    let isPressed: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(ringColour, lineWidth: ShutterMetrics.ringWidth)
                .opacity(look.isRefusing ? 0 : 1)
            BlockedRing(isActive: look.isRefusing)
            BreathingGlow(isActive: look == .ready)
            RunningArc(isActive: look == .checking, colour: AppTheme.onPhoto, period: 1.1, tail: 0.45)
            RunningArc(isActive: look == .busy, colour: AppTheme.warn, period: 1.8, tail: 0.6)
            disc
            ShutterBadge(count: queueAhead)
        }
        .animation(.easeInOut(duration: 0.5), value: look)
        .frame(width: ShutterMetrics.size, height: ShutterMetrics.size)
        .keyframeAnimator(initialValue: 1.0, trigger: refusedTicket) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(0.86, duration: 0.126)
                CubicKeyframe(1.05, duration: 0.126)
                CubicKeyframe(1.0, duration: 0.168)
            }
        }
        // Drawn over a photo: the dark palette, whatever the app scheme is.
        .environment(\.colorScheme, .dark)
        .contentShape(Circle())
    }

    private var ringColour: Color {
        look == .ready ? AppTheme.onPhoto.opacity(0.95) : AppTheme.onPhoto.opacity(0.28)
    }

    private var disc: some View {
        ZStack {
            Circle()
                .fill(AppTheme.onPhoto.opacity(look.isRefusing ? 0.5 : 1))
            ScannerFrame(isActive: look == .ready)
            BottleGlyph(look: look, pourTrigger: shotCount)
        }
        .padding(ShutterMetrics.discInset)
        .scaleEffect(isPressed ? 0.9 : 1)
        .animation(.snappy(duration: 0.18), value: isPressed)
    }
}

// MARK: - Ring parts

/// Gold halo that swells and fades back, 2.6 s a breath.
private struct BreathingGlow: View {
    let isActive: Bool

    var body: some View {
        TimelineView(.animation(paused: !isActive)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breath = (1 - cos(2 * .pi * t / 2.6)) / 2
            let spread = 8 * breath
            Circle()
                .strokeBorder(AppTheme.gold.opacity(0.32), lineWidth: max(spread, 0.01))
                .frame(width: ShutterMetrics.size + 2 * spread, height: ShutterMetrics.size + 2 * spread)
                .frame(width: ShutterMetrics.size, height: ShutterMetrics.size)
        }
        .opacity(isActive ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: isActive)
        .accessibilityHidden(true)
    }
}

/// A ring-shaped arc that fades in along its length and turns round the shutter.
private struct RunningArc: View {
    let isActive: Bool
    let colour: Color
    /// Seconds per turn.
    let period: Double
    /// The visible share of the circle, the head being the brightest end.
    let tail: Double

    var body: some View {
        TimelineView(.animation(paused: !isActive)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Circle()
                .strokeBorder(
                    AngularGradient(
                        stops: [
                            .init(color: colour.opacity(0), location: 1 - tail),
                            .init(color: colour, location: 1)
                        ],
                        center: .center
                    ),
                    lineWidth: ShutterMetrics.ringWidth
                )
                .rotationEffect(.degrees(360 * t.truncatingRemainder(dividingBy: period) / period))
        }
        .opacity(isActive ? 1 : 0)
        .animation(.easeInOut(duration: 0.4), value: isActive)
        .accessibilityHidden(true)
    }
}

/// The ring while a shot would get no answer: dashed, red, turning very slowly.
private struct BlockedRing: View {
    let isActive: Bool

    var body: some View {
        TimelineView(.animation(paused: !isActive)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Circle()
                .strokeBorder(
                    AppTheme.bad.opacity(0.75),
                    style: StrokeStyle(lineWidth: ShutterMetrics.ringWidth, dash: [12, 7.9])
                )
                .rotationEffect(.degrees(360 * t.truncatingRemainder(dividingBy: 14) / 14))
        }
        .opacity(isActive ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: isActive)
        .accessibilityHidden(true)
    }
}

/// The queue length on the shutter, popping in and out with a spring.
private struct ShutterBadge: View {
    let count: Int

    /// Kept while the badge shrinks away, so it does not flash «0» on its way out.
    @State private var shown: Int

    init(count: Int) {
        self.count = count
        _shown = State(initialValue: max(count, 1))
    }

    var body: some View {
        Text("\(shown)")
            .font(.footnote.weight(.bold))
            .monospacedDigit()
            // `paper` in the dark palette is the near-black the amber wants for its text.
            .foregroundStyle(AppTheme.paper)
            .contentTransition(.numericText())
            .padding(.horizontal, 6)
            .frame(minWidth: 22, minHeight: 22)
            .background(AppTheme.warn, in: Capsule())
            .scaleEffect(count > 0 ? 1 : 0)
            .opacity(count > 0 ? 1 : 0)
            .animation(.spring(duration: 0.4, bounce: 0.5), value: count > 0)
            .animation(.snappy, value: shown)
            .offset(x: 8, y: -6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .onChange(of: count) { _, new in
                if new > 0 { shown = new }
            }
            .accessibilityHidden(true)
    }
}
