import SwiftUI

/// The content of an «Open on Svoe Vino» link: the text and the trailing arrow. The caller
/// owns the button, its tint and its padding.
struct CatalogueLinkLabel: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .multilineTextAlignment(.leading)
            Spacer()
            AppIcon(systemName: "arrow.up.right")
                .accessibilityHidden(true)
        }
    }
}
