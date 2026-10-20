import SwiftUI

/// The one way to close a modal: a ✕ in the top leading corner, as the system sheets of
/// iOS 26 have it. In a toolbar it is a plain button (the bar draws the glass); in a sheet's
/// own header it is a round glass button of its own.
struct CloseButton: View {
    var isInToolbar = false
    let action: () -> Void

    @State private var closeCount = 0

    var body: some View {
        if isInToolbar {
            button
        } else {
            button.appGlassIconButtonStyle()
        }
    }

    private var button: some View {
        Button {
            closeCount += 1
            action()
        } label: {
            AppIcon(systemName: "xmark")
                .font(.body.weight(.semibold))
                .frame(width: isInToolbar ? nil : 32, height: isInToolbar ? nil : 32)
        }
        .accessibilityLabel(String(localized: "common_close"))
        .sensoryFeedback(.impact(weight: .light), trigger: closeCount)
    }
}
