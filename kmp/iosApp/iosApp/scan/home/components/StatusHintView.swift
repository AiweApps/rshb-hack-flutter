import SwiftUI

/// The glass capsule over the shutter: «point at the label» at rest, the service status for
/// a few seconds when it changes. One surface whose width and tint follow the text; the two
/// texts cross-fade with a small vertical slide and blur (the hint leaves upwards, the status
/// arrives from below). The whole capsule fades and settles in and out with `isShown`; it
/// keeps its place in the layout while hidden, so the row under it never jumps.
struct StatusHintView: View {
    let hint: HintKind
    let look: ShutterLook
    let queueAhead: Int
    /// Whether the capsule is up at all; shared state folds it away by itself.
    let isShown: Bool
    /// Bumped when a shot is refused: the capsule shakes.
    let refusedTicket: Int
    let onTap: () -> Void

    @State private var aimWidth: CGFloat?
    @State private var statusWidth: CGFloat?

    private var showsStatus: Bool { hint != .aim }

    private var tint: Color? {
        guard showsStatus else { return nil }
        if hint == .queued || look == .busy { return AppTheme.warn }
        return look.isRefusing ? AppTheme.bad : nil
    }

    var body: some View {
        let statusText = StatusHintText.status(look: look, hint: hint, queueAhead: queueAhead)
        let visibleWidth = showsStatus ? statusWidth : aimWidth

        Button(action: onTap) {
            ZStack {
                aimLayer
                statusLayer(text: statusText)
            }
            .frame(width: visibleWidth)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.verticalPadding)
            .frame(minHeight: Metrics.minHeight)
            .clipShape(Capsule())
            .appGlass(in: Capsule(), tint: tint)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.45, bounce: 0.2), value: visibleWidth)
        .animation(.easeInOut(duration: 0.35), value: tint)
        .keyframeAnimator(initialValue: 0.0, trigger: refusedTicket) { content, shift in
            content.offset(x: shift)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-1, duration: Self.shakeStep)
                CubicKeyframe(3, duration: Self.shakeStep)
                CubicKeyframe(-6, duration: Self.shakeStep)
                CubicKeyframe(6, duration: Self.shakeStep)
                CubicKeyframe(-6, duration: Self.shakeStep)
                CubicKeyframe(6, duration: Self.shakeStep)
                CubicKeyframe(-6, duration: Self.shakeStep)
                CubicKeyframe(3, duration: Self.shakeStep)
                CubicKeyframe(-1, duration: Self.shakeStep)
                CubicKeyframe(0, duration: Self.shakeStep)
            }
        }
        // Over a photo the capsule is always the dark glass with white text.
        .environment(\.colorScheme, .dark)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .modifier(HintLayerStyle(isVisible: isShown, hiddenOffset: Metrics.slide))
        .allowsHitTesting(isShown)
        .accessibilityLabel(StatusHintText.visible(look: look, hint: hint, queueAhead: queueAhead))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Layers

    private var aimLayer: some View {
        Text(StatusHintText.aim)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.onPhoto)
            .lineLimit(1)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { aimWidth = $0 }
            .modifier(HintLayerStyle(isVisible: !showsStatus, hiddenOffset: -Metrics.slide))
    }

    private func statusLayer(text: String) -> some View {
        HStack(spacing: 8) {
            StatusDot(look: look)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.onPhoto)
                .lineLimit(1)
        }
        .fixedSize()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { statusWidth = $0 }
        .modifier(HintLayerStyle(isVisible: showsStatus, hiddenOffset: Metrics.slide))
    }

    /// One of the ten steps of the 0.42 s swing of the design.
    private static let shakeStep = 0.042

    private enum Metrics {
        static let minHeight: CGFloat = 36
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 8
        static let slide: CGFloat = 10
    }
}

/// Fades a layer in and out, sliding it by `hiddenOffset` and blurring it while it is away.
private struct HintLayerStyle: ViewModifier {
    let isVisible: Bool
    let hiddenOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.96)
            .offset(y: isVisible ? 0 : hiddenOffset)
            .blur(radius: isVisible ? 0 : 3)
            .animation(.smooth(duration: 0.38), value: isVisible)
            .accessibilityHidden(!isVisible)
    }
}

/// The coloured dot in front of the status: blinks while we connect, pulses while the
/// service is busy, stays still otherwise.
private struct StatusDot: View {
    let look: ShutterLook

    var body: some View {
        TimelineView(.animation(paused: look != .checking && look != .busy)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let (scale, opacity) = motion(at: t)
            Circle()
                .fill(colour)
                .frame(width: 8, height: 8)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .accessibilityHidden(true)
    }

    private var colour: Color {
        switch look {
        case .checking: return AppTheme.onPhoto.opacity(0.8)
        case .ready: return AppTheme.ok
        case .busy: return AppTheme.warn
        case .blocked, .offline: return AppTheme.bad
        }
    }

    private func motion(at time: TimeInterval) -> (scale: Double, opacity: Double) {
        switch look {
        case .checking:
            // Blinks between 35 % and full, once a second.
            let wave = (1 - cos(2 * .pi * time / 1.0)) / 2
            return (1, 0.35 + 0.65 * wave)
        case .busy:
            // Swells to 1.5x while dimming to 55 %, every 1.4 s.
            let wave = (1 - cos(2 * .pi * time / 1.4)) / 2
            return (1 + 0.5 * wave, 1 - 0.45 * wave)
        case .ready, .blocked, .offline:
            return (1, 1)
        }
    }
}
