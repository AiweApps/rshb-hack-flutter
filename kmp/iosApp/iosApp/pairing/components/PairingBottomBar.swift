import SwiftUI
import SharedLogic

/// One primary action, with a quiet route back to the dish categories.
struct PairingBottomBar: View {
    let state: DishPairingState
    let onSave: () -> Void
    let onChangeDish: () -> Void
    let onAddWine: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { changeDish; Spacer(minLength: 0); primaryAction }
            VStack(spacing: 4) { primaryAction; changeDish }
        }
        .controlSize(.regular)
        .buttonBorderShape(.capsule)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var changeDish: some View {
        Button(String(localized: "pairing_change_dish"), action: onChangeDish)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.ink2)
            .frame(minHeight: 44)
            .fixedSize(horizontal: true, vertical: false)
            .buttonStyle(.plain)
            .disabled(state.isSaving)
    }

    @ViewBuilder
    private var primaryAction: some View {
        if state.hasNoMatches {
            Button(String(localized: "pairing_add_wine"), action: onAddWine)
                .frame(minHeight: 44)
                .appSecondaryButtonStyle()
        } else {
            let isSaved = state.savedId != nil
            Button(action: onSave) {
                HStack(spacing: 8) {
                    if state.isSaving {
                        ProgressView()
                    } else if isSaved {
                        AppIcon(systemName: "checkmark")
                    }
                    Text(String(localized: isSaved ? "pairing_saved" : "pairing_save"))
                }
                .foregroundStyle(AppTheme.onWine)
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
            }
            .appPrimaryButtonStyle()
            .disabled(!state.canSave)
            .animation(.snappy, value: isSaved)
        }
    }
}
