import SwiftUI

/// «Add to comparison» / «Remove from comparison». The symbol swaps with `.replace` and
/// bounces on the change; once the wine is in, the button turns into the quieter
/// «remove» one. Prominent (or secondary, beside another primary action) for the hero action, compact for a card in a list.
struct AddToCompareButton: View {
    enum Style {
        case prominent
        /// Full width like `prominent`, but quiet: next to another primary action.
        case secondary
        /// Looks like `prominent`, but as wide as its label: one of a row of actions.
        case inline
        case compact
    }

    let isInCompare: Bool
    let style: Style
    let onAdd: () -> Void
    let onRemove: () -> Void

    @State private var tapCount = 0
    /// What the last tap did, so the haptic matches it even though the state arrives later.
    @State private var feedback: SensoryFeedback = .success

    var body: some View {
        content
            .sensoryFeedback(trigger: tapCount) { _, _ in feedback }
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .prominent, .inline:
            button
                .controlSize(.large)
                .buttonBorderShape(.capsule)
                .modifier(ProminentStyle(isInCompare: isInCompare))
        case .secondary:
            button
                .controlSize(.large)
                .buttonBorderShape(.capsule)
                .appSecondaryButtonStyle()
                .tint(AppTheme.wine)
        case .compact:
            button
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.wine)
        }
    }

    private var button: some View {
        Button {
            // Success when the wine joins the set, a lighter tap when it leaves.
            feedback = isInCompare ? .impact(weight: .light) : .success
            tapCount += 1
            if isInCompare {
                onRemove()
            } else {
                onAdd()
            }
        } label: {
            HStack(spacing: 8) {
                AppIcon(systemName: isInCompare ? "minus.circle" : "plus.circle")
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: isInCompare)
                Text(isInCompare ? String(localized: "result_remove_from_compare") : String(localized: "result_add_to_compare"))
            }
            .frame(maxWidth: style == .compact || style == .inline ? nil : .infinity)
        }
    }

    private struct ProminentStyle: ViewModifier {
        let isInCompare: Bool

        @ViewBuilder
        func body(content: Content) -> some View {
            if isInCompare {
                content.appSecondaryButtonStyle().tint(AppTheme.wine)
            } else {
                content.appPrimaryButtonStyle()
            }
        }
    }
}
