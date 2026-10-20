import SwiftUI
import SharedLogic

/// The dish categories as a readable list of full-width rows, nothing hidden sideways.
struct DishChipsRow: View {
    let dishes: [DishLabel]
    let isInteractive: Bool
    let onSelect: (DishLabel) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(dishes, id: \.id) { dish in
                Button {
                    onSelect(dish)
                } label: {
                    HStack(spacing: 12) {
                        Text(dish.label)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        AppIcon(systemName: "chevron.right")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .foregroundStyle(AppTheme.ink)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isInteractive)
                if dish.id != dishes.last?.id {
                    Divider().overlay(AppTheme.rule)
                }
            }
        }
    }
}
