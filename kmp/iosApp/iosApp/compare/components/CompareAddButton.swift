import SwiftUI

/// The comparison's «+» in the navigation bar: a wine-tinted glass button that opens a menu
/// with the two ways to add a wine, from the history or by a new scan. Disabled while the set
/// is full.
struct CompareAddButton: View {
    let isEnabled: Bool
    let onPickFromHistory: () -> Void
    let onNewScan: () -> Void

    @State private var pickCount = 0

    var body: some View {
        Menu {
            Button {
                pickCount += 1
                onPickFromHistory()
            } label: {
                Label(String(localized: "compare_pick_history"), appSymbol: "clock.arrow.circlepath")
            }
            Button {
                pickCount += 1
                onNewScan()
            } label: {
                Label(String(localized: "compare_new_scan"), appSymbol: "camera")
            }
        } label: {
            AppIcon(systemName: "plus")
                .font(.body.weight(.semibold))
        }
        .menuOrder(.fixed)
        .menuStyle(.button)
        .modifier(WineTintedGlass())
        .disabled(!isEnabled)
        .accessibilityLabel(String(localized: "compare_add_wine"))
        .sensoryFeedback(.selection, trigger: pickCount)
    }
}

/// Prominent glass tinted with the brand wine on iOS 26 (the bar's own glass, coloured);
/// a filled wine button before.
private struct WineTintedGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .tint(AppTheme.wine)
        } else {
            content
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(AppTheme.wine)
        }
    }
}
