import SwiftUI

/// Centered, full-space loading indicator shared across every screen's `ScreenState.Loading`
/// branch.
struct LoadingStateView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
