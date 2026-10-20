import SwiftUI

/// A floating glass pill: symbol, title and an optional wine-coloured count badge. Floats
/// bottom-leading or bottom-trailing over a list.
struct GlassPill: View {
    let title: String
    let systemImage: String
    var badge: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                AppIcon(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
                if let badge {
                    Text("\(badge)")
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.onWine)
                        .padding(.horizontal, 8)
                        .frame(minWidth: 26, minHeight: 26)
                        .background(AppTheme.wine, in: Capsule())
                        .contentTransition(.numericText())
                }
            }
            .font(.body)
            .foregroundStyle(AppTheme.wine)
            // With the button style's own padding this adds up to the 50 pt tall, 18 pt padded
            // pill the plain-glass version had.
            .padding(.horizontal, 6)
            .frame(minHeight: 36)
        }
        // The glass button style, not an interactive glass effect on a plain button's label:
        // that one handles touches itself and some taps never reach the action.
        .appSecondaryButtonStyle()
        .buttonBorderShape(.capsule)
        .controlSize(.regular)
        .animation(.snappy, value: badge)
    }
}
