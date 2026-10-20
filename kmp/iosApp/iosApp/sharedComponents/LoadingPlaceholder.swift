import SwiftUI

/// A redacted, softly pulsing stand-in for text that is still on its way. Not «no data»:
/// it says nothing yet, and VoiceOver hears that the data is loading.
private struct LoadingPlaceholderModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            base(content)
        } else {
            base(content).phaseAnimator([0.45, 1.0]) { view, opacity in
                view.opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: 0.9)
            }
        }
    }

    private func base(_ content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "gastro_loading"))
    }
}

extension View {
    func loadingPlaceholder() -> some View {
        modifier(LoadingPlaceholderModifier())
    }
}
