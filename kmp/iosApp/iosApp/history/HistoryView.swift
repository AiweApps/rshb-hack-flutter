import SwiftUI
import SharedLogic

struct HistoryView: View {
    @ObservedObject private var observableState: ObservableValue<HistoryState>
    @ObservedObject private var modalSlot: ObservableValue<ChildSlot<AnyObject, HistoryComponentModal>>
    private let component: HistoryComponent

    init(component: HistoryComponent) {
        self.component = component
        self.observableState = ObservableValue(component.state)
        self.modalSlot = ObservableValue(component.modalSlot)
    }

    var body: some View {
        let state = observableState.value
        let confirm = modalSlot.value.child?.instance as? HistoryComponentModal.ConfirmClear

        content
            .navigationTitle(String(localized: "history_title"))
            .background(AppTheme.paper.ignoresSafeArea())
            .toolbar {
                if state.canClear {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: component.onClearClicked) {
                                Label(String(localized: "history_clear"), appSymbol: "trash")
                            }
                        } label: {
                            Label(String(localized: "history_menu"), appSymbol: "ellipsis")
                        }
                        // On the menu, so the popover form of the dialog points at it.
                        .confirmClearHistoryDialog(component: confirm?.component, onDismiss: component.onModalDismissed)
                    }
                }
            }
            .toastBanner(message: toastMessage(state), onConsumed: component.onToastConsumed)
            .sensoryFeedback(trigger: state.toast) { _, toast in
                guard let toast else { return nil }
                if toast == HistoryToast.cleared { return .success }
                if toast == HistoryToast.deleteFailed
                    || toast == HistoryToast.clearFailed
                    || toast == HistoryToast.pairingDeleteFailed
                    || toast == HistoryToast.compareFull
                    || toast == HistoryToast.addToCompareFailed
                    || toast == HistoryToast.removeFromCompareFailed
                    || toast == HistoryToast.favoritesFailed {
                    return .warning
                }
                return nil
            }
    }

    @ViewBuilder
    private var content: some View {
        let state = observableState.value
        let screenState = state.screenState

        if screenState is ScreenState.Loading {
            LoadingStateView()
        } else if let error = screenState as? ScreenState.Error {
            ErrorStateView(error: error.error, onRetry: component.onRetry)
        } else if screenState is ScreenState.Content {
            if state.isEmpty {
                HistoryEmptyView(onScanNow: component.onScanNowClicked)
            } else {
                HistoryList(state: state, component: component)
            }
        }
    }

    private func toastMessage(_ state: HistoryState) -> String? {
        guard let toast = state.toast else { return nil }
        if toast == HistoryToast.deleted { return String(localized: "history_deleted") }
        if toast == HistoryToast.deleteFailed { return String(localized: "history_delete_failed") }
        if toast == HistoryToast.cleared { return String(localized: "history_cleared") }
        if toast == HistoryToast.pairingDeleted { return String(localized: "history_toast_pairing_deleted") }
        if toast == HistoryToast.pairingDeleteFailed { return String(localized: "history_toast_pairing_delete_failed") }
        if toast == HistoryToast.addedToCompare { return String(localized: "notice_compare_added") }
        if toast == HistoryToast.alreadyInCompare { return String(localized: "notice_compare_already") }
        if toast == HistoryToast.compareFull { return String(localized: "notice_compare_full") }
        if toast == HistoryToast.addToCompareFailed { return String(localized: "notice_compare_failed") }
        if toast == HistoryToast.removedFromCompare { return String(localized: "notice_compare_removed") }
        if toast == HistoryToast.removeFromCompareFailed { return String(localized: "notice_compare_remove_failed") }
        if toast == HistoryToast.addedToFavorites { return String(localized: "history_toast_favorite_added") }
        if toast == HistoryToast.removedFromFavorites { return String(localized: "history_toast_favorite_removed") }
        if toast == HistoryToast.favoritesFailed { return String(localized: "history_toast_favorite_failed") }
        return String(localized: "history_clear_failed")
    }
}
