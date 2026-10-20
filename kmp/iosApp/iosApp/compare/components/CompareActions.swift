import SwiftUI

/// Content actions, never an overlay on top of comparison rows.
struct CompareActions: View {
    let canPairDish: Bool
    let onPlanDinner: () -> Void
    let onPairDish: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { actions }
            VStack(alignment: .leading, spacing: 0) { actions }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(.plain)
        .tint(AppTheme.wine)
    }

    @ViewBuilder
    private var actions: some View {
        Button(action: onPlanDinner) {
            Text(String(localized: "compare_plan_dinner"))
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(AppTheme.card, in: Capsule())
                .overlay(Capsule().stroke(AppTheme.rule, lineWidth: 1))
        }
        Button(action: onPairDish) {
            Text(String(localized: "compare_for_dish"))
                .font(.subheadline)
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .disabled(!canPairDish)
    }
}
