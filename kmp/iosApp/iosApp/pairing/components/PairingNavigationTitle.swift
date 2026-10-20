import SwiftUI

extension View {

    /// The screen title with an optional subtitle under it: the system subtitle on iOS 26+,
    /// a two-line title in the bar before.
    @ViewBuilder
    func pairingNavigationTitle(title: String, subtitle: String?) -> some View {
        if #available(iOS 26, *) {
            self.navigationTitle(title)
                .navigationSubtitle(subtitle ?? "")
                .navigationBarTitleDisplayMode(.inline)
        } else {
            self.navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text(title)
                                .font(.headline)
                            if let subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)
                    }
                }
        }
    }
}
