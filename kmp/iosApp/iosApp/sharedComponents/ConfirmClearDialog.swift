import SwiftUI
import SharedLogic

extension View {

    /// The «clear history?» confirmation, driven by a Decompose slot: it is on screen while
    /// the slot holds a `ConfirmClearHistoryComponent`. Used by History and Settings.
    func confirmClearHistoryDialog(
        component: ConfirmClearHistoryComponent?,
        onDismiss: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            String(localized: "history_clear_confirm_title"),
            isPresented: Binding(
                get: { component != nil },
                set: { isPresented in
                    if !isPresented {
                        onDismiss()
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "history_clear_confirm"), role: .destructive) {
                component?.onConfirmClicked()
            }
            Button(String(localized: "common_cancel"), role: .cancel) {
                component?.onCancelClicked()
            }
        } message: {
            Text(String(localized: "history_clear_confirm_body"))
        }
    }
}
