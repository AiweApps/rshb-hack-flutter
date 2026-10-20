import SwiftUI

/// The tab with no wines, or with only one: the two ways to add the next.
struct CompareEmptyView: View {
    let title: String
    let message: String?
    let onPickFromHistory: () -> Void
    let onScan: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, appSymbol: "arrow.left.arrow.right", iconSize: 48)
        } description: {
            if let message {
                Text(message)
            }
        } actions: {
            CompareAddActions(onPickFromHistory: onPickFromHistory, onScan: onScan)
        }
    }
}

/// «Pick from the history» (prominent) and «Scan» (glass), shared by the empty tab and the
/// single-wine hint.
struct CompareAddActions: View {
    let onPickFromHistory: () -> Void
    let onScan: () -> Void

    var body: some View {
        AppGlassGroup(spacing: 10) {
            VStack(spacing: 10) {
                Button(action: onPickFromHistory) {
                    Text(String(localized: "compare_pick_history"))
                        .frame(maxWidth: 260)
                }
                .appPrimaryButtonStyle()
                Button(action: onScan) {
                    Label(String(localized: "compare_scan"), appSymbol: "camera")
                        .frame(maxWidth: 260)
                }
                .appSecondaryButtonStyle()
                .tint(AppTheme.wine)
            }
            .controlSize(.large)
            .buttonBorderShape(.capsule)
        }
    }
}
