import SwiftUI

/// A brief white flash over the viewfinder on every shot; `trigger` is bumped when one is taken.
struct ShotFlash: View {
    let trigger: Int

    var body: some View {
        Rectangle()
            .fill(AppTheme.onPhoto)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, opacity in
                content.opacity(opacity)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0.85, duration: 0.001)
                    CubicKeyframe(0, duration: 0.45)
                }
            }
            .accessibilityHidden(true)
    }
}
