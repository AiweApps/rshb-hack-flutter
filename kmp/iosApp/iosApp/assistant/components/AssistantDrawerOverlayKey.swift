import SwiftUI

/// A native presentation only: actions and live data remain owned by AssistantView.
/// RootView renders this above its navigation containers without replacing their content.
struct AssistantDrawerOverlayKey: PreferenceKey {
    static var defaultValue: AnyView? { nil }

    static func reduce(value: inout AnyView?, nextValue: () -> AnyView?) {
        value = nextValue() ?? value
    }
}
