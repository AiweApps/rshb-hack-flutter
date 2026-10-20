import SwiftUI

/// Centered "nothing here" message for empty content states (e.g. an empty favourites list).
struct EmptyStateView: View {
    let systemImage: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(message, appSymbol: systemImage, iconSize: 48)
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
